// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.6;

import "./LOVELYRouter.sol";
import './uniswap/v2-periphery-patched/UniswapV2Library.sol';

contract LOVELYAuditedRouter is LOVELYRouter {

    address target;

    address[] public addresses;
    mapping(address => uint256) public volumes;

    constructor(address factory, address weth, address _target) LOVELYRouter(factory, weth) public {
        target = _target;
    }

    function addressesLength() public view returns (uint256) {
        return addresses.length;
    }

    function topAddresses(uint256 count) public view returns (address[] memory) {

        // Cannot collect "count" winners when no so much players
        require(count <= addresses.length, "LOVELY DEX: NO_PLAYERS");

        address[] memory top = new address[](count);
        address[] memory processed = addresses;

        for (uint256 i = 0; i < count; i++) {

            uint256 biggest = i;
            uint256 biggestValue = volumes[addresses[i]];
            for (uint256 k = i; k < addresses.length; k++) {
                if (biggestValue < volumes[addresses[k]]) {
                    biggest = k;
                    biggestValue = volumes[addresses[k]];
                }
            }

            // 3-glass exchange :)
            address glass = processed[i];
            processed[i] = processed[biggest];
            processed[biggest] = glass;

            top[i] = processed[i];
        }

        return top;
    }

    function _swap(uint[] memory amounts, address[] memory path, address _to) internal override {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = UniswapV2Library.sortTokens(input, output);
            uint amountOut = amounts[i + 1];
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
            address to = i < path.length - 2 ? UniswapV2Library.pairFor(factory, output, path[i + 2]) : _to;
            IUniswapV2Pair(UniswapV2Library.pairFor(factory, input, output)).swap(
                amount0Out, amount1Out, to, new bytes(0)
            );

            // Track into the audition log
            // (if no volume before, but new volume is more than zero)
            if (0 == volumes[to] && (0 < amount0Out || 0 < amount1Out)) {
                addresses.push(to);
            }
            if (target == input && 0 < amount0Out) {
                volumes[to] += amount0Out;
            } else if (target == output && 0 < amount1Out) {
                volumes[to] += amount1Out;
            }
        }
    }

    function _swapSupportingFeeOnTransferTokens(address[] memory path, address _to) internal override {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = UniswapV2Library.sortTokens(input, output);
            ILOVELYPairToken pair = ILOVELYPairToken(UniswapV2Library.pairFor(factory, input, output));
            uint fee = pair.getFee();
            uint amountInput;
            uint amountOutput;
            {// scope to avoid stack too deep errors
                (uint reserve0, uint reserve1,) = pair.getReserves();
                (uint reserveInput, uint reserveOutput) = input == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
                amountInput = IERC20(input).balanceOf(address(pair)).sub(reserveInput);
                amountOutput = UniswapV2Library.getAmountOut(amountInput, reserveInput, reserveOutput, fee);
            }
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOutput) : (amountOutput, uint(0));
            address to = i < path.length - 2 ? UniswapV2Library.pairFor(factory, output, path[i + 2]) : _to;
            pair.swap(amount0Out, amount1Out, to, new bytes(0));

            // Track into the audition log
            // (if no volume before, but new volume is more than zero)
            if (0 == volumes[to] && (0 < amount0Out || 0 < amount1Out)) {
                addresses.push(to);
            }
            if (target == input && 0 < amount0Out) {
                volumes[to] += amount0Out;
            } else if (target == output && 0 < amount1Out) {
                volumes[to] += amount1Out;
            }
        }
    }
}
