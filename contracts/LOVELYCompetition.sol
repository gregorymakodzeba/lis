// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.6;

import "./ILOVELYTokenList.sol";
import "./LOVELYAuditedRouter.sol";

contract LOVELYCompetition {

    enum Status {
        Registration,
        Open,
        Close,
        Claiming,
        Over
    }

    enum Tier {
        Zero,
        First,
        Second,
        Third
    }

    struct Event {
        Status status;
        uint256 startBlock;
        uint256 endBlock;
        uint256 rewardAmount;
        address rewardToken;
        LOVELYAuditedRouter router;
        mapping(Tier => uint256) tiers;
        mapping(address => User) users;
        address[] winners;
    }

    struct User {
        bool registered;
        bool claimed;
    }

    address owner;
    address tokenList;

    mapping(uint256 => Event) private events;
    uint256 public eventCount;

    uint256 public minimumRewardAmount;

    address public immutable factory;
    address public immutable WETH;

    // TODO: Attach to the token list
    constructor(address _factory, address _WETH, address _tokenList) public {
        owner = msg.sender;
        factory = _factory;
        WETH = _WETH;
        tokenList = _tokenList;
    }

    function setMinimumRewardAmount(uint256 _amount) external {
        require(msg.sender == owner, "LOVELY DEX: ACCESS_DENIED");
        minimumRewardAmount = _amount;
    }

    //
    // Creates a competition event with the given:
    // - block range;
    // - reward amount in the given token;
    // - tiers.
    //
    function create(
        uint256 _startBlock,
        uint256 _endBlock,
        uint256 _rewardAmount,
        address _rewardToken,
        uint256[4] calldata _tiers
    ) external {

        // Check that the block range is in the future
        require(block.number <= _startBlock && block.number < _endBlock && _startBlock < _endBlock, "LOVELY DEX: EVENT_BLOCK_RANGE");

        // Check that the reward token is listed and validated
        ILOVELYTokenList list = ILOVELYTokenList(tokenList);
        require(list.validated(_rewardToken), "LOVELY DEX: NOT_VALIDATED");

        // Check that the reward token amount is enough
        require(0 == minimumRewardAmount || minimumRewardAmount <= _rewardAmount, "LOVELY DEX: COMPETITION_REWARD_SMALL");

        // Can be called by anyone
        // require(owner == msg.sender, "LOVELY DEX: ACCESS_DENIED");

        // Accept the reward amount in the given token
        IERC20(_rewardToken).transferFrom(msg.sender, address(this), _rewardAmount);

        // Validate that tiers are balanced
        require(_tiers[0] * 5 + _tiers[1] * 5 + _tiers[2] * 10 + _tiers[3] * 30 == 100, "LOVELY DEX: COMPETITION_TIERS_UNBALANCED");

        uint256 id = eventCount++;
        Event storage competitionEvent = events[id];
        competitionEvent.status = Status.Registration;
        competitionEvent.startBlock = _startBlock;
        competitionEvent.endBlock = _endBlock;
        competitionEvent.rewardAmount = _rewardAmount;
        competitionEvent.rewardToken = _rewardToken;

        competitionEvent.router = new LOVELYAuditedRouter(factory, WETH, _rewardToken);
        setEventTiers(id, _tiers);
    }

    function eventRouter(uint256 _eventIdentifier) public view returns (address) {
        return address(events[_eventIdentifier].router);
    }

    function eventStatus(uint256 _eventIdentifier) public view returns (Status) {
        return events[_eventIdentifier].status;
    }

    function eventBlockRange(uint256 _eventIdentifier) public view returns (uint256, uint256) {
        Event storage competitionEvent = events[_eventIdentifier];
        return (competitionEvent.startBlock, competitionEvent.endBlock);
    }

    function eventReward(uint256 _eventIdentifier) public view returns (uint256) {
        return events[_eventIdentifier].rewardAmount;
    }

    function eventTiers(uint256 _eventIdentifier) public view returns (uint256[4] memory) {
        Event storage competitionEvent = events[_eventIdentifier];
        return [
        competitionEvent.tiers[Tier.Zero],
        competitionEvent.tiers[Tier.First],
        competitionEvent.tiers[Tier.Second],
        competitionEvent.tiers[Tier.Third]
        ];
    }

    function setEventTiers(uint256 _eventIdentifier, uint256[4] memory _tiers) private {
        Event storage competitionEvent = events[_eventIdentifier];
        competitionEvent.tiers[Tier.Zero] = _tiers[0];
        competitionEvent.tiers[Tier.First] = _tiers[1];
        competitionEvent.tiers[Tier.Second] = _tiers[2];
        competitionEvent.tiers[Tier.Third] = _tiers[3];
    }

    function eventTierReward(uint256 _eventIdentifier, Tier tier) public view returns (uint256) {
        Event storage competitionEvent = events[_eventIdentifier];
        return competitionEvent.rewardAmount * competitionEvent.tiers[tier] / 100;
    }

    //
    // Transitions the competition event into the next state.
    // Transitions to preceding states are not possible.
    //
    function eventTransition(uint256 _eventIdentifier) external {

        // TODO: Whether this should be performed by the DEX owner?
        require(owner == msg.sender, "LOVELY DEX: ACCESS_DENIED");

        Event storage competitionEvent = events[_eventIdentifier];
        if (Status.Registration == competitionEvent.status) {
            competitionEvent.status = Status.Open;
        } else if (Status.Open == competitionEvent.status) {
            competitionEvent.status = Status.Close;
        } else if (Status.Close == competitionEvent.status) {
            competitionEvent.winners = competitionEvent.router.topAddresses(50);
            competitionEvent.status = Status.Claiming;
        } else if (Status.Claiming == competitionEvent.status) {
            competitionEvent.status = Status.Over;
        }
    }

    //
    // Returns the list of winners for a given event.
    //
    function eventWinners(uint256 _eventIdentifier) external view returns (address[] memory) {

        Event storage competitionEvent = events[_eventIdentifier];

        require(Status.Claiming == competitionEvent.status, "LOVELY DEX: NOT_CLAIMING");

        return competitionEvent.winners;
    }

    //
    // Claims trader's reward.
    //
    function claim(uint256 _eventIdentifier) external {

        Event storage competitionEvent = events[_eventIdentifier];
        User storage user = competitionEvent.users[msg.sender];

        require(user.registered, "LOVELY DEX: NOT_REGISTERED");
        require(!user.claimed, "LOVELY DEX: CLAIMED");

        // Find the trader in the winners array
        bool found = false;
        uint256 length = competitionEvent.winners.length;
        uint256 i = 0;
        for (; i < length; i++) {
            if (msg.sender == competitionEvent.winners[i]) {
                found = true;
                break;
            }
        }

        require(found, "LOVELY DEX: NOT_A_WINNER");

        // Calculate the tier
        Tier tier = Tier.Third;
        if (i < 5) {
            tier = Tier.Zero;
        } else if (i < 10) {
            tier = Tier.First;
        } else if (i < 20) {
            tier = Tier.Second;
        }

        // Calculate the reward
        uint256 reward = competitionEvent.rewardAmount * competitionEvent.tiers[tier] / 100;

        // Check that the reward is available
        require(reward <= IERC20(competitionEvent.rewardToken).balanceOf(address(this)), "LOVELY DEX: NO_BALANCE");

        // Mark the trader as one who claimed his reward
        user.claimed = true;

        // Send the prize
        IERC20(competitionEvent.rewardToken).transfer(msg.sender, reward);
    }

    //
    // Registers a user in a given competition.
    // 
    function register(uint256 _eventIdentifier) external {
        Event storage competitionEvent = events[_eventIdentifier];
        require(!competitionEvent.users[msg.sender].registered, "HAS_REGISTERED");
        competitionEvent.users[msg.sender].registered = true;
    }

    //
    // Whether a user is registed in the given competition.
    // 
    function registered(uint256 _eventIdentifier) public view returns (bool) {
        return events[_eventIdentifier].users[msg.sender].registered;
    }
}
