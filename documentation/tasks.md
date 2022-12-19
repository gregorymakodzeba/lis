# Project road-map
This document describes the DEX-related contracts mile-stones.

## Delivery #1 - basic DEX
This delivery includes the fully working DEX customized for token approval by paying the fee in the given token.
- [x] Basic Hardhat project and test environment configuration.
- [x] Uniswap V2 deployment for customization.
- [x] ERC-20 token implementation for the liquidity pair.
- [x] Basic liquidity pool / markets smart contract.
- [x] Automated integration tests for this functionality.
- [x] Market / pair / liquidity token approval by paying in the given ERC-20 token.

## Delivery #2 - advanced DEX + farming
This delivery includes the farming contract.
After implementing this contract, it is logical to start a staging website.
- [x] Automated integration tests for the pair approval.
- [x] Pool fee customization.
- [x] Exchange protocol implementation.
- [x] Automated integration tests for the exchange protocol implementation.
- [x] A farming contract.
- [x] Automated integration tests for the farming contract.

### Farming customization
For the project:
- [x] Enter the "Reward amount in LST (Lovely Swap Token)".
- [x] Select "Start/end time".
- [x] (In the front-end) Automatically define the APY according to entered details.

For the user:
- [x] Users will select a pool to participate in a farming pool.
- [x] They can put manually the amount of both tokens.
- [x] OR They just put their USDT amount, and 50% of USDT automatically buys the second token according to the slippage and added to the liquidity.
- [x] (In the front-end) Developers can manually set the fees for every harvest and every stake/un-stake fee in the smart contract.

### Liquidity pool changes
- [x] Transfer the validation amount immediately while creating a pool.
- [x] [16 hours] Locking liquidity pool until the given block is mined.

## Delivery #3 - trading competition
This delivery includes the trading competition contract.
- [x] Defining a competition.
- [x] Participating in a competition.
- [ ] Automated integration tests for the trading competition.
- [ ] For the requirement "Minimum of 5000$ equivalent in tokens will be accepted", we need to integrate the USD price oracle (to know the USD price). 
Also, after such integration we will be not able to accept tokens which are not supported by the USD price oracle.
- [ ] When a competition goes from one state to another 
(Registration -> Open -> Close -> Claiming -> Over), someone needs to perform this state transition.
Now I have implemented ability to move forward only for the DEX owner. 
But we can change so that transition will be perfomed by the competition owner.
Also, when the state moves from "Close" to "Claiming", the winners are calculated.
This costs some more gas. Ideally, we can let the trustful third-party to perform transitions by schedule.
- [ ] Should we allow moving the competition state forward respecting the competition start and end dates? Or can we keep ourselves flexible?

```
For the project party: 
- Start the trading competition; 
- DEX will detect approved token contracts from the connected wallet address;
- The project party needs to select the token contract;
- Minimum of 5000$ equivalent in tokens will be accepted;
- Enter the ""Total Reward Amount"";
- Select the ""Date Time Start & End"".

- Enter ""Top 5 Traders Reward"": 20%, 10%, 7%, 5%, 5%.
- Enter ""6-10 Traders Reward"": 20%.
- Enter ""11-20 Traders Reward"": 33%.
- Enter ""21-50 Traders Reward"": 0%."
"For the user party: 
- Pay fees to get entry in trading (fees will be automatically set from the total reward amount of 0.05%);
- The developer can set the percentage of fees for the entry ticket;
- All live/upcoming/completed trading competitions will be shown;
- User can click on upcoming/live/completed trading events to check more details;
- In Live/completed events there will shows top 10 traders (for more list dashboard will shows upto 50 Top Traders list); 
- Amount will be auto distributed to winners;
- According to Event Win details.
```
