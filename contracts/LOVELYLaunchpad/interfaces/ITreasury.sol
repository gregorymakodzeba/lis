// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ILOVELYTreasury {
    function _takeMoneyFromSender(
        IERC20 currency,
        address sender,
        uint256 amount
    ) external;

    function _sendMoneyToPublicSaleOwner(
        IERC20 currency,
        address to,
        uint256 amount
    ) external;
}
