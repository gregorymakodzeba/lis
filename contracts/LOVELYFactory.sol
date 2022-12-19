// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.5.16;

import "./uniswap/v2-core-patched/UniswapV2Factory.sol";
import "./ILOVELYPairToken.sol";
import "./LOVELYPairToken.sol";
import "./LOVELYTokenList.sol";

contract LOVELYFactory is UniswapV2Factory {

    uint defaultValidationAmount;

    address mainToken;

    LOVELYTokenList tokenList;

    constructor() UniswapV2Factory(msg.sender) public {
        tokenList = new LOVELYTokenList(msg.sender);
    }

    function getDefaultValidationAmount() public view returns (uint) {
        return defaultValidationAmount;
    }

    function setDefaultValidationAmount(uint _value) public {
        require(msg.sender == feeToSetter, 'LOVELY DEX: FORBIDDEN');

        defaultValidationAmount = _value;
    }

    function setMainToken(address _value) public {
        require(msg.sender == feeToSetter, 'LOVELY DEX: FORBIDDEN');
        mainToken = _value;
    }

    function getTokenList() public view returns (LOVELYTokenList) {
        return tokenList;
    }

    //
    // Creates a market pair.
    //
    // tokenA - the first token of a pair;
    // tokenB - the second token of a pair;
    // tokenC - the token in which the validation amount should be paid;
    // validationAmount - the amount to be deposited to validate the pair;
    // activationBlockNumber - block number, after which the swap is unlocked.
    //
    function createValidatedPair(address tokenA, address tokenB, address tokenC, uint validationAmount, uint fee) external returns (address pair) {

        require(tokenA != tokenB, 'LOVELY DEX: IDENTICAL_ADDRESSES');
        require(tokenList.validated(tokenA), "LOVELY DEX: FIRST_NOT_VALIDATED");
        require(tokenList.validated(tokenB), "LOVELY DEX: SECOND_NOT_VALIDATED");
        require(msg.sender == feeToSetter || validationAmount == defaultValidationAmount, "LOVELY DEX: FACTORY_VALIDATION_AMOUNT");
        require(mainToken == address(0) || tokenA == mainToken || tokenB == mainToken);

        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'LOVELY DEX: ZERO_ADDRESS');
        // Single check is sufficient
        require(getPair[token0][token1] == address(0), 'LOVELY DEX: PAIR_EXISTS');
        bytes memory bytecode = type(LOVELYPairToken).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        ILOVELYPairToken(pair).initialize(token0, token1);

        // Desired activation block number
        uint firstActivationBlockNumber = tokenList.activationBlockNumberFor(tokenA);
        uint secondActivationBlockNumber = tokenList.activationBlockNumberFor(tokenB);
        uint activationBlockNumber = firstActivationBlockNumber > secondActivationBlockNumber ? firstActivationBlockNumber : secondActivationBlockNumber;

        ILOVELYPairToken(pair).initializeValidated(tokenC, validationAmount, fee, activationBlockNumber);
        getPair[token0][token1] = pair;
        // Populate mapping in the reverse direction
        getPair[token1][token0] = pair;
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }
}
