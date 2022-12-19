// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./ISharedData.sol";

interface ILOVELYILO {
    event Claim(address indexed user, uint256 amount);
    event Refund(address indexed user, uint256 amount);
    event Deposit(address indexed user, uint256 amount);
    event DepositToken(
        address indexed currency,
        address indexed user,
        uint256 amount
    );

    function initialize(ISharedData.PublicSaleParams memory params) external;
}
