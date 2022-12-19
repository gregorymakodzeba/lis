// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract BUSDToken is ERC20 {

    uint initialSupply = 1000000 * 1000000000000000000;

    constructor() ERC20("BUSD Token", "BUSD") {
        _mint(msg.sender, initialSupply);
    }
}
