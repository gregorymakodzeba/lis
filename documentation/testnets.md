# Test nets deployment
The following DEX contracts need to be deployed for testing:
- WETH;
- LOVELYFactory;
- LOVELYRouter.

Any LOVELYPair contracts are deployed by LOVELYFactory when requested.

HardHat configuration contains all necessary settings for contract deployment.
To deploy the contracts automatically need to run:

```shell
npm run deploy:testnet
```

After a successful deployment, the following JSON file is generated in the root project folder:
```json
{
  "WETH": "0x85CC0956Da49A5A5AD79565FfFbc95F8E4F36A92",
  "LOVELYFactory": "0x6d5D33924DEd836F444eF98C975F18AA6D7D79D2",
  "LOVELYRouter": "0x18C21a8A1db3308926Bed73dd0b3167E5c196c51"
}
```
This file together with build artifacts can be used to integrate to the contract.

# Running tests in test nets
The following NPM scripts are available to run a test in the test net.
```shell
npm run test:testnet
```
