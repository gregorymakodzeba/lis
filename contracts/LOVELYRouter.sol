// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.6;

import "./uniswap/v2-periphery-patched/UniswapV2Router02.sol";

contract LOVELYRouter is UniswapV2Router02 {
    constructor(address factory, address weth) UniswapV2Router02(factory, weth) public {
    }
}
