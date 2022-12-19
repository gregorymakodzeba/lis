// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.5.16;

import "./uniswap/v2-core-patched/UniswapV2Pair.sol";
import "./ILOVELYTokenList.sol";

contract LOVELYTokenList is ILOVELYTokenList {

    struct Token {

        // Amount, which must be paid to make the token valid
        uint256 validationAmount;

        // A token, in which this amount should be paid
        address validationToken;

        // A block number, after which the token becomes active
        uint activationBlockNumber;
    }

    uint defaultValidationAmount;

    address private owner;

    address[] public addresses;
    mapping(address => Token) slots;

    address feeTo;
    address public feeToSetter;

    constructor(address _owner) public {
        owner = _owner;
        feeTo = _owner;
        feeToSetter = _owner;
    }

    function getDefaultValidationAmount() public view returns (uint) {
        return defaultValidationAmount;
    }

    function setDefaultValidationAmount(uint _value) public {
        require(owner == msg.sender, 'UniswapV2: FORBIDDEN');

        defaultValidationAmount = _value;
    }

    function add(address _token, address _validationToken, uint _validationAmount, uint _activationBlockNumber) public {

        // This check was replaced with another check below allowing non-owners to list their tokens.
        // require(owner == msg.sender, "LOVELY DEX: NOT_OWNER");

        // Cannot add the token twice
        require(slots[_token].validationToken == address(0x0), 'LOVELY DEX: EXISTS');

        // Non-DEX-owners cannot re-define validation amount
        require(msg.sender == owner || _validationAmount == defaultValidationAmount, "LOVELY DEX: TOKEN_LIST_VALIDATION_AMOUNT");

        // Validate the token being added
        require(feeTo != address(0), "LOVELY DEX: NON_FEE_LIST");
        IERC20(_validationToken).transferFrom(msg.sender, feeTo, _validationAmount);

        // Save requirements for token validation
        slots[_token].validationToken = _validationToken;
        slots[_token].validationAmount = _validationAmount;
        slots[_token].activationBlockNumber = _activationBlockNumber;

        // Save to an address index.
        // This cannot happen twice.
        // So, there are no search checks.
        addresses.push(_token);
    }

    function at(uint i) public view returns (address) {
        return addresses[i];
    }

    function length() public view returns (uint256) {
        return addresses.length;
    }

    function validationAmountAt(uint i) public view returns (uint256) {
        return slots[addresses[i]].validationAmount;
    }

    function validationTokenAt(uint i) public view returns (address) {
        return slots[addresses[i]].validationToken;
    }

    function activationBlockNumberFor(address token) public view returns (uint) {
        return slots[token].activationBlockNumber;
    }

    function setFeeTo(address _feeTo) external {
        require(msg.sender == feeToSetter, 'LOVELY DEX: FORBIDDEN');
        feeTo = _feeTo;
    }

    function setFeeToSetter(address _feeToSetter) external {
        require(msg.sender == feeToSetter, 'LOVELY DEX: FORBIDDEN');
        feeToSetter = _feeToSetter;
    }

    // Initial implementation suggested a separate procedure for validation
    // function validate(address _token) private {
    //     require(feeTo != address(0), "LOVELY DEX: NON_FEE_LIST");
    //     IERC20(slots[_token].token).transferFrom(msg.sender, feeTo, slots[_token].amount);
    //     slots[_token].amount = 0;
    // }

    function validated(address _token) public view returns (bool) {

        // Requested token must be known
        require(slots[_token].validationToken != address(0x0), 'LOVELY DEX: NOT_EXISTS');

        // v.1.0
        // return 0 == slots[_token].amount;
        // v.2.0
        return true;
    }
}
