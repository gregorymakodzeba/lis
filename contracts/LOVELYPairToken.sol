// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.5.16;

import "./uniswap/v2-core-patched/UniswapV2Pair.sol";

contract LOVELYPairToken is UniswapV2Pair {

    address _validationToken;
    uint _validationTokenAmount;
    uint _activationBlockNumber;

    function initializeValidated(address _token, uint _amount, uint _fee, uint __activationBlockNumber) external {
        require(msg.sender == factory, 'LOVELY DEX: FORBIDDEN');
        _validationToken = _token;
        _validationTokenAmount = _amount;
        fee = _fee;
        _activationBlockNumber = __activationBlockNumber;
    }

    // Getting reserves is the first step of adding liquidity.
    // So, assuming that blocking getting reserves for non-validated pairs will block creating liquidity.
    function getReserves() public view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) {
        require(0 == _validationTokenAmount, "LOVELY DEX: NON_VALIDATED_PAIR");
        return super.getReserves();
    }

    function getValidationConstraint() public view returns (address validationToken, uint validationTokenAmount)
    {
        return (_validationToken, _validationTokenAmount);
    }

    function getRemainingActivationBlocks() public view returns (uint) {
        if (_activationBlockNumber <= block.number) {
            return 0;
        }
        return _activationBlockNumber - block.number;
    }

    function setFee(uint _fee) public {
        require(msg.sender == IUniswapV2Factory(factory).feeToSetter(), "LOVELY DEX: FORBIDDEN");
        fee = _fee;
    }

    function validate() public {
        address feeTo = IUniswapV2Factory(factory).feeTo();
        require(feeTo != address(0), "LOVELY DEX: NON_FEE_PAIR");
        IERC20(_validationToken).transferFrom(msg.sender, feeTo, _validationTokenAmount);
        _validationTokenAmount = 0;
    }
}
