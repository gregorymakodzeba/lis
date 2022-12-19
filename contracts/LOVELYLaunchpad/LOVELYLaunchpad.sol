// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./interfaces/ILOVELYILO.sol";
import "./interfaces/ISharedData.sol";
import "./security/LOVELYWhitelist.sol";
import "./proxy/SaleProxy.sol";

contract LOVELYLaunchpad is LOVELYWhitelist, ISharedData {
    uint256 public iloId;
    address[] public ilo;
    address[] public implementations;

    event CreateIlo(address indexed ilo, uint256 id);

    modifier paramsVerification(PublicSaleParams memory params) {
        require(
            params._minimumContributionLimit <=
                params._maximumContributionLimit,
            "Minimum Contribution Limit should be lower or equel than Maximum Contribution Limit"
        );
        require(
            params._softCap <= params._hardCap,
            "softCap should be lower or equel than hardCap"
        );
        require(
            params._startDepositTime < params._endDepositTime,
            "Start Deposit Time should be lower or equel than End Deposit Time"
        );

        require(params._vestingInfo.length > 0, "vesting Info needed");

        require(
            params._vestingInfo[0]._time >= params._endDepositTime,
            "Start Claim Time should be more than End Deposit Time"
        );

        if (params._vestingInfo.length > 1) {
            for (
                uint256 index = 0;
                index < params._vestingInfo.length - 1;
                index++
            ) {
                require(
                    params._vestingInfo[index + 1]._time >
                        params._vestingInfo[index]._time,
                    "Start Claim Time should be lower or equel than End Deposit Time"
                );
            }
        }

        require(
            params._maximumContributionLimit <= params._hardCap,
            "Maximum Contribution Limit should be lower or equel than Hard Cap"
        );
        _;
    }

    function initialize(address owner) public initializer {
        __Whitelist_init(owner);
        managerAdd(owner);
        iloId = 0;
    }

    function createIloContract(PublicSaleParams memory params)
        external
        onlyManager
        paramsVerification(params)
        onlyWhitelist(params._tokenAddress)
    {
        address newIlo;

        newIlo = address(new SaleProxy(implementations[iloId], owner()));
        ILOVELYILO(newIlo).initialize(params);

        ilo.push(newIlo);

        emit CreateIlo(newIlo, ilo.length - 1);
    }

    function setIloId(uint256 id) public onlyManager {
        iloId = id;
    }

    function addImplementation(address _address) public onlyManager {
        implementations.push(_address);
    }
}
