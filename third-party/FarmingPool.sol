// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.9;

import "./utils/IBEP20.sol";
import "./utils/SafeBEP20.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IMigratorChef {
    // Perform LP token migration from legacy PantokenSwap to TokenSwap.
    // Take the current LP token address and return the new LP token address.
    // Migrator should have full access to the caller's LP token.
    // Return the new LP token address.
    //
    // XXX Migrator must have allowance access to PantokenSwap LP tokens.
    // TokenSwap must mint EXACTLY the same amount of TokenSwap LP tokens or
    // else something bad will happen. Traditional PantokenSwap does not
    // do that so be careful!
    function migrate(IBEP20 token) external returns (IBEP20);
}

// FarmingPool is the master of Token. He can make Token and he is a fair guy.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once TOKEN is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.
contract FarmingPool is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    mapping(uint256 => MasterPool) private farmingPools;
    uint256 public farmingPoolsCount;

    mapping(uint64 => MethodAccess) private methodAccess;
    uint256 private blockToAllow;

    struct MethodAccess {
        bool isCalled;
        uint256 allowedBlock;
    }

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of TOKENs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accTokenPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accTokenPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IBEP20 lpToken; // Address of LP token contract.
        uint256 lastRewardBlock; // Last block number that TOKENs distribution occurs.
        uint256 accTokenPerShare; // Accumulated TOKENs per share, times 1e12. See below.
    }

    struct MasterPool {
        // The TOKEN!
        IBEP20 token;
        // Tokens created per block.
        uint256 tokenPerBlock;
        // Bonus muliplier for early token makers.
        uint256 BONUS_MULTIPLIER;
        // The migrator contract. It has a lot of power. Can only be set through governance (owner).
        IMigratorChef migrator;
        // Info of each pool.
        PoolInfo poolInfo;
        // Info of each user that stakes LP tokens.
        mapping(address => UserInfo) userInfo;
        // The time when TOKEN mining unfrized.
        uint256 unfrizedTime;
        uint256 rewardTokenAmount;
        address refundeeAddress;
        uint256 startTime;
        uint256 endTime;
        // The block number when TOKEN mining starts.
        uint256 startBlock;
        // The block number when TOKEN mining stop.
        uint256 endBlock;
        uint256 totalRewarded;
        address owner;
    }

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );

    function createPool(
        IBEP20 _token,
        address _owner,
        address _refundeeAddress,
        uint256 _rewardTokenAmount,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _lockedHours
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
            _refundeeAddress != address(0),
            "createPool: refundee address no zero address"
        );
        require(
            _owner != address(0),
            "createPool: owner address no zero address"
        );

        uint256 daysToStart = (_startTime / 1 days) -
            (block.timestamp / 1 days);
        uint256 daysToEnd = (_endTime / 1 days) - (block.timestamp / 1 days);
        uint256 startBlock = daysToStart * 28000;
        uint256 endBlock = daysToEnd * 28000;
        uint256 mpid = farmingPoolsCount++;
        MasterPool storage masterPool = farmingPools[mpid];
        // masterPool.token = _token;

        // masterPool.tokenPerBlock = _rewardTokenAmount.div(
        //     endBlock.sub(startBlock)
        // );
        masterPool.BONUS_MULTIPLIER = 1;
        masterPool.unfrizedTime = block.timestamp + (_lockedHours * 1 hours);
        masterPool.rewardTokenAmount = _rewardTokenAmount;
        masterPool.startTime = _startTime;
        masterPool.endTime = _endTime;
        masterPool.startBlock = startBlock;
        masterPool.endBlock = endBlock;
        masterPool.tokenPerBlock =
            left(farmingPoolsCount) /
            (period(farmingPoolsCount) * 20);
        {
            IBEP20 token = _token;
            _addToken(mpid, token);
            _addRefundeeAddress(mpid, _refundeeAddress);
            _addOwner(mpid, _owner);
        }
        return mpid;
    }

    function getBlockToAllow() public view onlyOwner returns (uint256) {
        return blockToAllow;
    }

    function updateBlockToAllow(uint256 _blockToAllow) public onlyOwner {
        blockToAllow = _blockToAllow;
    }

    function _addRefundeeAddress(uint256 _mpid, address _address) private {
        farmingPools[_mpid].refundeeAddress = _address;
    }

    function _addOwner(uint256 _mpid, address _owner) private {
        farmingPools[_mpid].owner = _owner;
    }

    function _addToken(uint256 _mpid, IBEP20 token) private {
        farmingPools[_mpid].token = token;
    }

    modifier onlyUnfrized(uint256 _mpid) {
        require(
            block.timestamp >= farmingPools[_mpid].unfrizedTime,
            "funds are blocked"
        );
        _;
    }

    modifier onlyOwnerOrPoolOwner(uint256 _mpid) {
        require(
            farmingPools[_mpid].owner == msg.sender || owner() == msg.sender,
            "You not owner of this pool or contract"
        );
        _;
    }

    modifier ifAllowed(uint64 _methodId) {
        if (!methodAccess[_methodId].isCalled) {
            methodAccess[_methodId].isCalled = true;
            methodAccess[_methodId].allowedBlock = block.number + blockToAllow;
            revert("Not allowed");
        } else {
            require(
                block.number >= methodAccess[_methodId].allowedBlock,
                "Not allowe"
            );
        }

        _;
        methodAccess[_methodId].isCalled = false;
    }

    function setNotAllowedMethod(uint64 _methodId) public onlyOwner {
        methodAccess[_methodId].isCalled = false;
    }

    function left(uint256 _mpid) public view returns (uint256) {
        return
            farmingPools[_mpid].rewardTokenAmount -
            farmingPools[_mpid].totalRewarded;
    }

    function currentBlock() public view returns (uint256) {
        return block.number;
    }

    function updateMultiplier(uint256 _mpid, uint256 multiplierNumber)
        public
        onlyOwner
    {
        farmingPools[_mpid].BONUS_MULTIPLIER = multiplierNumber;
    }

    function earnedTotal(uint256 _mpid) public view returns (uint256) {
        uint256 currentBlockNumber = currentBlock();
        uint256 earned;
        for (
            uint256 index = farmingPools[_mpid].startBlock + 1;
            index < currentBlockNumber;
            index++
        ) {
            earned += farmingPools[_mpid].tokenPerBlock;
        }
        return earned;
    }

    function lpTokenPool(uint256 _mpid) public view returns (uint256) {
        PoolInfo storage pool = farmingPools[_mpid].poolInfo;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));

        return lpSupply;
    }

    function lpTokenUser(uint256 _mpid) public view returns (uint256) {
        return farmingPools[_mpid].userInfo[msg.sender].amount;
    }

    function earnedBlockUser(uint256 _mpid) public view returns (uint256) {
        UserInfo storage user = farmingPools[_mpid].userInfo[msg.sender];

        uint256 earnedBlock = (farmingPools[_mpid].tokenPerBlock *
            user.amount) / lpTokenPool(_mpid);

        return earnedBlock;
    }

    function period(uint256 _mpid) public view returns (uint256) {
        return
            (farmingPools[_mpid].endTime - farmingPools[_mpid].startTime) / 60;
    }

    function poolLength() external view returns (uint256) {
        return farmingPoolsCount;
    }

    function updaterefundeeAddress(uint256 _mpid, address _refundeeAddress)
        public
        onlyOwnerOrPoolOwner(_mpid)
        ifAllowed(3)
    {
        farmingPools[_mpid].refundeeAddress = _refundeeAddress;
    }

    function updatePoolEndTime(uint256 _mpid, uint256 _endTime)
        public
        onlyOwnerOrPoolOwner(_mpid)
        ifAllowed(2)
    {
        uint256 daysToEnd = (_endTime / 1 days) - (block.timestamp / 1 days);
        uint256 endBlock = daysToEnd * 28000;
        farmingPools[_mpid].endBlock = endBlock;
        farmingPools[_mpid].tokenPerBlock = farmingPools[_mpid]
            .rewardTokenAmount
            .div(endBlock.sub(farmingPools[_mpid].startBlock));
    }

    function updateRewardTokenAmount(uint256 _mpid, uint256 _rewardTokenAmount)
        public
        onlyOwnerOrPoolOwner(_mpid)
        ifAllowed(5)
    {
        farmingPools[_mpid].rewardTokenAmount = _rewardTokenAmount;
        farmingPools[_mpid].tokenPerBlock = farmingPools[_mpid]
            .rewardTokenAmount
            .div(
                farmingPools[_mpid].endBlock.sub(farmingPools[_mpid].startBlock)
            );
    }

    function updatePoolOwner(uint256 _mpid, address _owner)
        public
        onlyOwnerOrPoolOwner(_mpid)
        ifAllowed(1)
    {
        farmingPools[_mpid].owner = _owner;
    }

    function withdrawTokens(uint256 _mpid, address _to)
        public
        onlyOwnerOrPoolOwner(_mpid)
        ifAllowed(4)
    {
        uint256 balance = farmingPools[_mpid].token.balanceOf(address(this));
        farmingPools[_mpid].token.safeTransferFrom(address(this), _to, balance);
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(uint256 _mpid, IBEP20 _lpToken) public onlyOwner {
        uint256 lastRewardBlock = block.number > farmingPools[_mpid].startBlock
            ? block.number
            : farmingPools[_mpid].startBlock;

        farmingPools[_mpid].poolInfo = PoolInfo({
            lpToken: _lpToken,
            lastRewardBlock: lastRewardBlock,
            accTokenPerShare: 0
        });
    }

    // Set the migrator contract. Can only be called by the owner.
    function setMigrator(IMigratorChef _migrator, uint256 _mpid)
        public
        onlyOwner
    {
        farmingPools[_mpid].migrator = _migrator;
    }

    // Migrate lp token to another lp contract. Can be called by anyone. We trust that migrator contract is good.
    function migrate(uint256 _mpid) public {
        require(
            address(farmingPools[_mpid].migrator) != address(0),
            "migrate: no migrator"
        );
        PoolInfo storage pool = farmingPools[_mpid].poolInfo;
        IBEP20 lpToken = pool.lpToken;
        uint256 bal = lpToken.balanceOf(address(this));
        lpToken.safeApprove(address(farmingPools[_mpid].migrator), bal);
        IBEP20 newLpToken = farmingPools[_mpid].migrator.migrate(lpToken);
        require(bal == newLpToken.balanceOf(address(this)), "migrate: bad");
        pool.lpToken = newLpToken;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(
        uint256 _mpid,
        uint256 _from,
        uint256 _to
    ) public view returns (uint256) {
        return _to.sub(_from).mul(farmingPools[_mpid].BONUS_MULTIPLIER);
    }

    function getStatus(uint256 _mpid) public view returns (uint256) {
        if (farmingPools[_mpid].startTime > block.timestamp) {
            return 0;
        } else if (
            farmingPools[_mpid].startTime <= block.timestamp &&
            farmingPools[_mpid].totalRewarded <
            farmingPools[_mpid].rewardTokenAmount
        ) {
            return 1;
        } else {
            return 2;
        }
    }

    // View function to see pending TOKENs on frontend.
    function pendingToken(uint256 _mpid, address _user)
        external
        view
        returns (uint256)
    {
        PoolInfo storage pool = farmingPools[_mpid].poolInfo;
        UserInfo storage user = farmingPools[_mpid].userInfo[_user];
        uint256 accTokenPerShare = pool.accTokenPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        uint256 blockNumber = block.number;

        if (block.number > farmingPools[_mpid].endBlock) {
            blockNumber = farmingPools[_mpid].endBlock;
        }

        if (blockNumber > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(
                _mpid,
                pool.lastRewardBlock,
                blockNumber
            );
            uint256 tpb = farmingPools[_mpid].tokenPerBlock;
            uint256 tokenReward = multiplier.mul(tpb);
            accTokenPerShare = accTokenPerShare.add(
                tokenReward.mul(1e12).div(lpSupply)
            );
        }

        return user.amount.mul(accTokenPerShare).div(1e12).sub(user.rewardDebt);
    }

    // Deposit LP tokens to FarmingPool for TOKEN allocation.
    function deposit(uint256 _mpid, uint256 _amount) public {
        PoolInfo storage pool = farmingPools[_mpid].poolInfo;
        UserInfo storage user = farmingPools[_mpid].userInfo[msg.sender];
        if (user.amount > 0) {
            uint256 pending = user
                .amount
                .mul(pool.accTokenPerShare)
                .div(1e12)
                .sub(user.rewardDebt);
            if (pending > 0) {
                safeTokenTransfer(_mpid, msg.sender, pending);
            }
        }
        if (_amount > 0) {
            pool.lpToken.safeTransferFrom(
                address(msg.sender),
                address(this),
                _amount
            );
            user.amount = user.amount.add(_amount);
        }
        user.rewardDebt = user.amount.mul(pool.accTokenPerShare).div(1e12);
        emit Deposit(msg.sender, _mpid, _amount);
    }

    // Withdraw LP tokens from FarmingPool.
    function withdraw(uint256 _mpid, uint256 _amount)
        public
        onlyUnfrized(_mpid)
        nonReentrant
    {
        PoolInfo storage pool = farmingPools[_mpid].poolInfo;
        UserInfo storage user = farmingPools[_mpid].userInfo[msg.sender];
        require(user.amount >= _amount, "withdraw: not good");

        uint256 pending = user.amount.mul(pool.accTokenPerShare).div(1e12).sub(
            user.rewardDebt
        );
        if (pending > 0) {
            safeTokenTransfer(_mpid, msg.sender, pending);
        }
        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accTokenPerShare).div(1e12);
        emit Withdraw(msg.sender, _mpid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _mpid) public ifAllowed(6) nonReentrant {
        PoolInfo storage pool = farmingPools[_mpid].poolInfo;
        UserInfo storage user = farmingPools[_mpid].userInfo[msg.sender];
        pool.lpToken.safeTransfer(address(msg.sender), user.amount);
        emit EmergencyWithdraw(msg.sender, _mpid, user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
    }

    function withdrawTokensFromPool(uint256 _mpid)
        public
        onlyOwner
        nonReentrant
    {
        MasterPool storage pool = farmingPools[_mpid];
        uint256 amount = pool.rewardTokenAmount - pool.totalRewarded;
        pool.token.safeTransfer(pool.refundeeAddress, amount);
    }

    // Safe token transfer function, just in case if rounding error causes pool to not have enough TOKENs.
    function safeTokenTransfer(
        uint256 _mpid,
        address _to,
        uint256 _amount
    ) internal {
        uint256 tokenBal = farmingPools[_mpid].token.balanceOf(address(this));
        if (_amount > tokenBal) {
            farmingPools[_mpid].token.transfer(_to, tokenBal);
            farmingPools[_mpid].totalRewarded += _amount;
        } else {
            farmingPools[_mpid].token.transfer(_to, _amount);
            farmingPools[_mpid].totalRewarded += _amount;
        }
    }
}
