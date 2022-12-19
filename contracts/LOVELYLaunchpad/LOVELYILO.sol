// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./LOVELYTreasury.sol";
import "./interfaces/ILOVELYILO.sol";
import "./interfaces/ISharedData.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract LOVELYILO is
    ILOVELYILO,
    Initializable,
    PausableUpgradeable,
    AccessControlUpgradeable,
    LOVELYTreasury,
    ReentrancyGuard,
    ISharedData
{
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    uint256 ILO_FEE = 1125;
    uint256 STAKING_REWARD_FEE = 1250;
    uint256 LOCKED_FEE = 4750;
    uint256 CLIENT_FEE = 4000;
    uint256 DIV = 10000;
    uint256 DECIMAL_8 = 8;
    uint256 DECIMAL_6 = 6;

    struct UserInfo {
        uint256 deposit;
        uint256 claimedAmount;
        uint256 refundedAmount;
    }

    struct TokenInfo {
        IERC20 token;
        // How much Sale tokens we will revice per 1 IERC20 token
        uint256 presaleRate;
        uint256 amount;
        uint256 decimal;
    }

    struct SaleInformation {
        address tokenAddress;
        uint256 minimumContributionLimit;
        uint256 maximumContributionLimit;
        uint256 softCap;
        uint256 hardCap;
        uint256 totalCap;
        uint256 startDepositTime;
        uint256 endDepositTime;
        uint256 depositCount;
        uint256 claimOrRefundCount;
        bool isMainTokenAllowed;
    }

    SaleInformation public saleInformation;
    address[] public users;
    TokenInfo public tokenInfo;
    VestingInfo[] public vestingInfo;

    mapping(address => UserInfo) public allowanceToUserInfo;

    function initialize(PublicSaleParams memory params)
        public
        virtual
        initializer
    {
        __Pausable_init();
        __AccessControl_init();

        _setupRole(DEFAULT_ADMIN_ROLE, params._admin);
        _setupRole(MANAGER_ROLE, msg.sender);
        _setupRole(MANAGER_ROLE, params._manager);

        bool isMainTokenAllowed = params._presaleRate == 0 ? false : true;

        saleInformation = SaleInformation(
            params._tokenAddress,
            params._minimumContributionLimit,
            params._maximumContributionLimit,
            params._softCap,
            params._hardCap,
            params._startDepositTime,
            params._endDepositTime,
            0,
            0,
            0,
            isMainTokenAllowed
        );

        for (uint256 index = 0; index < params._vestingInfo.length; index++) {
            vestingInfo.push(
                VestingInfo(
                    params._vestingInfo[index]._time,
                    params._vestingInfo[index]._percent
                )
            );
        }

        if (saleInformation.isMainTokenAllowed) {
            tokenInfo = TokenInfo({
                presaleRate: params._presaleRate,
                token: IERC20(address(0)),
                amount: 0,
                decimal: 0
            });
        } else {
            tokenInfo = TokenInfo({
                presaleRate: params._token._presaleRate,
                token: IERC20(params._token._tokenAddress),
                amount: 0,
                decimal: params._token._decimal
            });
        }
    }

    function deposit() public payable virtual whenNotPaused {
        require(saleInformation.isMainTokenAllowed);
        _deposirRequire(msg.sender, msg.value);

        allowanceToUserInfo[msg.sender].deposit = msg.value;

        saleInformation.depositCount++;
        users.push(msg.sender);
        saleInformation.totalCap = saleInformation.totalCap + msg.value;

        emit Deposit(msg.sender, msg.value);
    }

    function depositToken(IERC20 currency, uint256 amount)
        public
        whenNotPaused
    {
        require(!saleInformation.isMainTokenAllowed);

        _deposirRequire(msg.sender, amount);

        if (tokenInfo.decimal == DECIMAL_8) {
            amount = amount / 100000000000000;
        } else if (tokenInfo.decimal == DECIMAL_6) {
            amount = amount / 1000000000000;
        }

        this._takeMoneyFromSender(currency, msg.sender, amount);
        allowanceToUserInfo[msg.sender].deposit = amount;
        saleInformation.depositCount++;

        users.push(msg.sender);

        addTokenInfoAmount(amount);

        emit DepositToken(msg.sender, msg.sender, amount);
    }

    function claim() public virtual whenNotPaused nonReentrant {
        if (saleInformation.isMainTokenAllowed) {
            uint256 iloBalance = address(this).balance;
            require(iloBalance >= saleInformation.softCap);
        } else {
            require(saleInformation.totalCap >= saleInformation.softCap);
        }

        require(block.timestamp > vestingInfo[0]._time);
        require(allowanceToUserInfo[msg.sender].deposit > 0);

        uint256 allowedPercentage = 0;

        for (uint256 index = 0; index < vestingInfo.length; index++) {
            if (block.timestamp <= vestingInfo[index]._time) {
                allowedPercentage += vestingInfo[index]._percent;
            }
        }

        uint256 claimAmount = (tokenInfo.presaleRate *
            allowanceToUserInfo[msg.sender].deposit) / (1 ether);

        uint256 calculatedClaimAmount = (claimAmount * allowedPercentage) /
            (1 ether) /
            100;

        calculatedClaimAmount -= allowanceToUserInfo[msg.sender].claimedAmount;

        IERC20(saleInformation.tokenAddress).transfer(
            msg.sender,
            calculatedClaimAmount
        );

        allowanceToUserInfo[msg.sender].claimedAmount = calculatedClaimAmount;
        saleInformation.claimOrRefundCount++;
        emit Claim(msg.sender, calculatedClaimAmount);
    }

    function transferBalance()
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        whenNotPaused
        nonReentrant
    {
        require(block.timestamp > saleInformation.endDepositTime);

        if (saleInformation.isMainTokenAllowed) {
            uint256 iloBalance = address(this).balance;
            require(iloBalance >= saleInformation.softCap);
            payable(msg.sender).transfer(iloBalance);
        } else {
            this._sendMoneyToPublicSaleOwner(
                tokenInfo.token,
                msg.sender,
                tokenInfo.amount
            );
        }
    }

    function transferToken(address to) public onlyRole(MANAGER_ROLE) {
        uint256 iloBalance = IERC20(saleInformation.tokenAddress).balanceOf(
            address(this)
        );
        IERC20(saleInformation.tokenAddress).transfer(to, iloBalance);
    }

    function updateTokenAddress(address _address)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        saleInformation.tokenAddress = _address;
    }

    function updateStartDepositTime(uint256 _time)
        public
        onlyRole(MANAGER_ROLE)
    {
        require(_time < saleInformation.endDepositTime);
        saleInformation.startDepositTime = _time;
    }

    function updateEndDepositTime(uint256 _time) public onlyRole(MANAGER_ROLE) {
        require(_time > saleInformation.startDepositTime);

        saleInformation.endDepositTime = _time;
    }

    function updateStartClaimTime(VestingInfoParams memory params)
        public
        onlyRole(MANAGER_ROLE)
    {
        require(params._vestingInfo.length > 0);

        require(params._vestingInfo[0]._time > saleInformation.endDepositTime);

        for (
            uint256 index = 0;
            index < params._vestingInfo.length - 1;
            index++
        ) {
            require(
                params._vestingInfo[index + 1]._time >
                    params._vestingInfo[index]._time
            );
        }

        for (uint256 index = 0; index < params._vestingInfo.length; index++) {
            delete vestingInfo[index];
            vestingInfo[index] = VestingInfo(
                params._vestingInfo[index]._time,
                params._vestingInfo[index]._percent
            );
        }
    }

    function updateSoftCap(uint256 _softCap) public onlyRole(MANAGER_ROLE) {
        saleInformation.softCap = _softCap;
    }

    function updateHardCap(uint256 _hardCap) public onlyRole(MANAGER_ROLE) {
        saleInformation.hardCap = _hardCap;
    }

    function updateMinimumContributionLimit(uint256 _limit)
        public
        onlyRole(MANAGER_ROLE)
    {
        saleInformation.minimumContributionLimit = _limit;
    }

    function updateMaximumContributionLimit(uint256 _limit)
        public
        onlyRole(MANAGER_ROLE)
    {
        saleInformation.maximumContributionLimit = _limit;
    }

    function userInfoList() public view returns (address[] memory) {
        return users;
    }

    function isClaimAllowed() public view returns (bool) {
        return block.timestamp > vestingInfo[0]._time;
    }

    function vestingLength() public view returns (uint256) {
        return vestingInfo.length;
    }

    function pause() public onlyRole(MANAGER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(MANAGER_ROLE) {
        _unpause();
    }

    function processingFees(uint256 amount)
        private
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        uint256 iloFee = (amount * ILO_FEE) / DIV;
        uint256 stakingRewardFee = (amount * STAKING_REWARD_FEE) / DIV;
        uint256 lockedFee = (amount * LOCKED_FEE) / DIV;
        uint256 cliendFee = (amount * CLIENT_FEE) / DIV;

        return (iloFee, stakingRewardFee, lockedFee, cliendFee);
    }

    function updateILOFee(uint256 _fee) public onlyRole(MANAGER_ROLE) {
        ILO_FEE = _fee;
    }

    function updateStakingRewardFee(uint256 _fee)
        public
        onlyRole(MANAGER_ROLE)
    {
        STAKING_REWARD_FEE = _fee;
    }

    function updateLockedFee(uint256 _fee) public onlyRole(MANAGER_ROLE) {
        LOCKED_FEE = _fee;
    }

    function updateCliendFee(uint256 _fee) public onlyRole(MANAGER_ROLE) {
        CLIENT_FEE = _fee;
    }

    function addTokenInfoAmount(uint256 _amount) private {
        tokenInfo.amount = tokenInfo.amount + _amount;
        saleInformation.totalCap = saleInformation.totalCap + _amount;
    }

    function _deposirRequire(address sender, uint256 amount) private view {
        require(block.timestamp > saleInformation.startDepositTime);
        require(block.timestamp < saleInformation.endDepositTime);
        require(allowanceToUserInfo[sender].deposit == 0);
        uint256 tempTotalCap = saleInformation.totalCap + amount;
        require(tempTotalCap <= saleInformation.hardCap);

        require(amount >= saleInformation.minimumContributionLimit);
        require(amount <= saleInformation.maximumContributionLimit);
        require(saleInformation.totalCap <= saleInformation.hardCap);
    }
}
