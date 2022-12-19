// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.1;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract LOVELYFarm is Ownable, ReentrancyGuard {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    modifier onlyOwnerOrPoolOwner(uint256 _poolIdentifier) {
        require(
            pools[_poolIdentifier].owner == msg.sender || owner() == msg.sender,
            "LOVELY FARM: FORBIDDEN"
        );
        _;
    }

    struct User {
        uint256 amount;
        uint256 rewardDebt;
    }

    struct Pool {

        address owner;

        address refundAddress;

        mapping(address => User) users;

        uint fee;

        IERC20 liquidityToken;

        IERC20 rewardToken;
        uint256 rewardMultiplier;
        uint256 rewardPerShare;
        uint256 rewardPerBlock;
        uint256 rewardTokenAmount;
        uint256 rewardLastBlock;
        uint256 rewardTotal;
        uint256 rewardStartBlock;
        uint256 rewardEndBlock;
    }

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

    mapping(uint256 => Pool) private pools;
    uint256 public poolCount;

    function add(uint256 _poolIdentifier, IERC20 _liquidityToken) public onlyOwner {

        uint256 rewardLastBlock = block.number > pools[_poolIdentifier].rewardStartBlock
        ? block.number
        : pools[_poolIdentifier].rewardStartBlock;

        pools[_poolIdentifier].liquidityToken = _liquidityToken;
        pools[_poolIdentifier].rewardLastBlock = rewardLastBlock;
        pools[_poolIdentifier].rewardPerShare = 0;
    }

    function at(uint256 _poolIdentifier) public view returns (address) {
        return address(pools[_poolIdentifier].liquidityToken);
    }

    function setFee(uint256 _poolIdentifier, uint _fee) public onlyOwner {
        pools[_poolIdentifier].fee = _fee;
    }

    function getFee(uint256 _poolIdentifier) public view returns (uint) {
        return pools[_poolIdentifier].fee;
    }

    function createPool(
        IERC20 _rewardToken,
        address _owner,
        address _refundAddress,
        uint256 _rewardTokenAmount,
        uint256 _startTime,
        uint256 _endTime
    ) external onlyOwner returns (uint256) {
        require(
            _endTime > _startTime,
            "createPool: Start time should be more than end time"
        );
        require(
            _startTime > block.timestamp,
            "createPool: Start time should be more than current time"
        );
        require(
            _rewardTokenAmount > 0,
            "createPool: Reward token amount should be more than zero"
        );
        require(
            _refundAddress != address(0),
            "createPool: refundee address no zero address"
        );
        require(
            _owner != address(0),
            "createPool: owner address no zero address"
        );

        uint256 daysToStart = (_startTime / 1 days) - (block.timestamp / 1 days);
        uint256 daysToEnd = (_endTime / 1 days) - (block.timestamp / 1 days);
        uint256 id = poolCount++;
        Pool storage masterPool = pools[id];
        masterPool.rewardTokenAmount = _rewardTokenAmount;
        masterPool.rewardStartBlock = daysToStart * 28000;
        masterPool.rewardEndBlock = daysToEnd * 28000;
        masterPool.rewardPerBlock = left(poolCount) / ((_endTime - _startTime) / 60 * 20);
        IERC20 token = _rewardToken;
        _addToken(id, token);
        _addRefundAddress(id, _refundAddress);
        _addOwner(id, _owner);
        return id;
    }

    function left(uint256 _poolIdentifier) public view returns (uint256) {
        return pools[_poolIdentifier].rewardTokenAmount - pools[_poolIdentifier].rewardTotal;
    }

    function blockPeriod(uint256 _poolIdentifier) public view returns (uint256) {
        return pools[_poolIdentifier].rewardEndBlock - pools[_poolIdentifier].rewardStartBlock;
    }

    function blockPeriodToStart(uint256 _poolIdentifier) public view returns (uint256) {
        return pools[_poolIdentifier].rewardStartBlock - block.number;
    }

    function _addToken(uint256 _poolIdentifier, IERC20 token) private {
        pools[_poolIdentifier].rewardToken = token;
    }

    function _addRefundAddress(uint256 _poolIdentifier, address _address) private {
        pools[_poolIdentifier].refundAddress = _address;
    }

    function _addOwner(uint256 _poolIdentifier, address _owner) private {
        pools[_poolIdentifier].owner = _owner;
    }

    function earnedTotal(uint256 _poolIdentifier) public view returns (uint256) {
        uint256 earned;
        for (
            uint256 index = pools[_poolIdentifier].rewardStartBlock + 1;
            index < block.number;
            index++
        ) {
            earned += pools[_poolIdentifier].rewardPerBlock;
        }

        return earned;
    }

    function liquidityTokenBalanceOfPool(uint256 _poolIdentifier) public view returns (uint256) {
        return pools[_poolIdentifier].liquidityToken.balanceOf(address(this));
    }

    function liquidityPoolBalanceOfUser(uint256 _poolIdentifier) public view returns (uint256) {
        return pools[_poolIdentifier].users[msg.sender].amount;
    }

    function earnedBlockUser(uint256 _poolIdentifier) public view returns (uint256) {
        User storage user = pools[_poolIdentifier].users[msg.sender];
        uint256 earnedBlock = (pools[_poolIdentifier].rewardPerBlock *
        user.amount) / liquidityTokenBalanceOfPool(_poolIdentifier);
        return earnedBlock;
    }

    function getStatus(uint256 _poolIdentifier) public view returns (uint256) {
        if (pools[_poolIdentifier].rewardStartBlock > block.number) {
            return 0;
        } else if (
            pools[_poolIdentifier].rewardStartBlock <= block.number &&
            pools[_poolIdentifier].rewardTotal <
            pools[_poolIdentifier].rewardTokenAmount
        ) {
            return 1;
        } else {
            return 2;
        }
    }

    function getRewardMultiplier(
        uint256 _poolIdentifier,
        uint256 _from,
        uint256 _to
    ) public view returns (uint256) {
        return _to.sub(_from).mul(pools[_poolIdentifier].rewardMultiplier);
    }

    function updateRewardMultiplier(uint256 _poolIdentifier, uint256 _multiplier)
    public
    onlyOwner
    {
        pools[_poolIdentifier].rewardMultiplier = _multiplier;
    }

    function updateRefundAddress(uint256 _poolIdentifier, address _refundAddress)
    public
    onlyOwnerOrPoolOwner(_poolIdentifier)
    {
        pools[_poolIdentifier].refundAddress = _refundAddress;
    }

    function updatePoolEndTime(uint256 _poolIdentifier, uint256 _endTime)
    public
    onlyOwnerOrPoolOwner(_poolIdentifier)
    {
        uint256 daysToEnd = (_endTime / 1 days) - (block.timestamp / 1 days);
        uint256 endBlock = daysToEnd * 28000;
        pools[_poolIdentifier].rewardEndBlock = endBlock;
        pools[_poolIdentifier].rewardPerBlock = pools[_poolIdentifier]
        .rewardTokenAmount
        .div(endBlock.sub(pools[_poolIdentifier].rewardStartBlock));
    }

    function updateRewardTokenAmount(uint256 _poolIdentifier, uint256 _rewardTokenAmount)
    public
    onlyOwnerOrPoolOwner(_poolIdentifier)
    {
        pools[_poolIdentifier].rewardTokenAmount = _rewardTokenAmount;
        pools[_poolIdentifier].rewardPerBlock = pools[_poolIdentifier]
        .rewardTokenAmount
        .div(
            pools[_poolIdentifier].rewardEndBlock.sub(pools[_poolIdentifier].rewardStartBlock)
        );
    }

    function updatePoolOwner(uint256 _poolIdentifier, address _owner)
    public
    onlyOwnerOrPoolOwner(_poolIdentifier)
    {
        pools[_poolIdentifier].owner = _owner;
    }

    function pendingToken(uint256 _poolIdentifier, address _user)
    external
    view
    returns (uint256)
    {
        Pool storage pool = pools[_poolIdentifier];
        User storage user = pools[_poolIdentifier].users[_user];
        uint256 rewardPerShare = pool.rewardPerShare;
        uint256 lpSupply = pool.liquidityToken.balanceOf(address(this));
        uint256 blockNumber = block.number;

        if (block.number > pools[_poolIdentifier].rewardEndBlock) {
            blockNumber = pools[_poolIdentifier].rewardEndBlock;
        }

        if (blockNumber > pool.rewardLastBlock && lpSupply != 0) {
            uint256 multiplier = getRewardMultiplier(
                _poolIdentifier,
                pool.rewardLastBlock,
                blockNumber
            );
            uint256 tpb = pools[_poolIdentifier].rewardPerBlock;
            uint256 tokenReward = multiplier.mul(tpb);
            rewardPerShare = rewardPerShare.add(
                tokenReward.mul(1e12).div(lpSupply)
            );
        }

        return user.amount.mul(rewardPerShare).div(1e12).sub(user.rewardDebt);
    }

    function deposit(uint256 _poolIdentifier, uint256 _amount) public {
        Pool storage pool = pools[_poolIdentifier];
        User storage user = pools[_poolIdentifier].users[msg.sender];
        if (user.amount > 0) {
            uint256 pending = user
            .amount
            .mul(pool.rewardPerShare)
            .div(1e12)
            .sub(user.rewardDebt);
            if (pending > 0) {
                safeTokenTransfer(_poolIdentifier, msg.sender, pending);
            }
        }
        if (_amount > 0) {
            pool.liquidityToken.transferFrom(msg.sender, address(this), _amount);
            user.amount = user.amount.add(_amount);
        }
        user.rewardDebt = user.amount.mul(pool.rewardPerShare).div(1e12);
        emit Deposit(msg.sender, _poolIdentifier, _amount);
    }

    function withdraw(uint256 _poolIdentifier, uint256 _amount)
    public
    nonReentrant
    {
        Pool storage pool = pools[_poolIdentifier];
        User storage user = pool.users[msg.sender];

        require(user.amount >= _amount, "LOVELY FARM: AMOUNT");

        uint256 pending = user.amount.mul(pool.rewardPerShare).div(1e12).sub(
            user.rewardDebt
        );
        if (pending > 0) {
            safeTokenTransfer(_poolIdentifier, msg.sender, pending);
        }
        if (_amount > 0) {
            uint256 transferableAmount = _amount.sub(_amount.mul(pool.fee).div(1000));
            user.amount = user.amount.sub(_amount);
            pool.liquidityToken.transfer(msg.sender, transferableAmount);
        }
        user.rewardDebt = user.amount.mul(pool.rewardPerShare).div(1e12);
        emit Withdraw(msg.sender, _poolIdentifier, _amount);
    }

    function withdrawAllReward(uint256 _poolIdentifier, address _to)
    public
    onlyOwnerOrPoolOwner(_poolIdentifier)
    {
        uint256 balance = pools[_poolIdentifier].rewardToken.balanceOf(address(this));
        pools[_poolIdentifier].rewardToken.safeTransferFrom(address(this), _to, balance);
    }

    function withdrawAllLiquidity(uint256 _poolIdentifier, address _to)
    public
    onlyOwnerOrPoolOwner(_poolIdentifier)
    {
        uint256 balance = pools[_poolIdentifier].liquidityToken.balanceOf(address(this));
        pools[_poolIdentifier].liquidityToken.safeTransferFrom(address(this), _to, balance);
    }

    function withdrawEmergency(uint256 _poolIdentifier) public nonReentrant {
        Pool storage pool = pools[_poolIdentifier];
        User storage user = pool.users[msg.sender];
        uint256 transferableAmount = user.amount.sub(user.amount.mul(pool.fee).div(1000));
        pool.liquidityToken.safeTransferFrom(address(this), msg.sender, transferableAmount);
        emit EmergencyWithdraw(msg.sender, _poolIdentifier, user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
    }

    function withdrawRefund(uint256 _poolIdentifier)
    public
    onlyOwner
    nonReentrant
    {
        Pool storage pool = pools[_poolIdentifier];
        uint256 amount = pool.rewardTokenAmount - pool.rewardTotal;
        pool.rewardToken.safeTransfer(pool.refundAddress, amount);
    }

    function safeTokenTransfer(
        uint256 _poolIdentifier,
        address _to,
        uint256 _amount
    ) internal {
        uint256 tokenBal = pools[_poolIdentifier].rewardToken.balanceOf(address(this));
        if (_amount > tokenBal) {
            pools[_poolIdentifier].rewardToken.transfer(_to, tokenBal);
            pools[_poolIdentifier].rewardTotal += _amount;
        } else {
            pools[_poolIdentifier].rewardToken.transfer(_to, _amount);
            pools[_poolIdentifier].rewardTotal += _amount;
        }
    }
}

