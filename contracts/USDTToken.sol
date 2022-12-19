// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract USDTToken is ERC20 {

    uint initialSupply = 1000000 * 1000000000000000000;

    constructor() ERC20("USDT Token", "USDT") {
        _mint(msg.sender, initialSupply);
    }
}
