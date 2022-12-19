// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract LOVELYTreasury {
    using SafeERC20 for IERC20;

    function _takeMoneyFromSender(
        IERC20 currency,
        address sender,
        uint256 amount
    ) external {
        require(amount > 0, "You need to sell at least some tokens");
        uint256 allowance = currency.allowance(sender, address(this));
        require(allowance >= amount, "Check the token allowance");

        currency.safeTransferFrom(address(sender), address(this), amount);
    }

    function _sendMoneyToPublicSaleOwner(
        IERC20 currency,
        address to,
        uint256 amount
    ) external {
        currency.safeTransfer(to, amount);
    }
}
