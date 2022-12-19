// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract WETHToken is ERC20 {

    uint initialSupply = 1000000 * 1000000000000000000;

    constructor() ERC20("WETH Token", "WETH") {
        _mint(msg.sender, initialSupply);
    }
}
