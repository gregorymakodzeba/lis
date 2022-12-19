# DEX integration examples
This document describes how the developer can integrate project's specific features.

## Order routing to a validated pair
This manual describes how to create a validated pool and then transfer liquidity to this pool.

### Basic initialization
In a test, we need to initialize:
- The owner of everything.
- Two ERC-20 contracts for which we want to create a pool.
- One WETH contract so that DEX knows where the Wrapped Ethereum is.

```javascript
const [owner] = await ethers.getSigners();

// Tokens
const first = await (await ethers.getContractFactory("LOVELYToken")).deploy();
const second = await (await ethers.getContractFactory("LOVELYToken")).deploy();
const weth = await (await ethers.getContractFactory("LOVELYToken")).deploy();
```

### Creating the whole DEX
The DEX consists of the:
- Factory, which creates pools.
- Order router, which handles financial operations.
While creating a DEX factory, we also set the receiver of all DEX fees.
```javascript
// DEX
const factory = await (await ethers.getContractFactory("LOVELYFactory")).deploy();
await factory.setFeeTo(owner.address);
const router = await (await ethers.getContractFactory("LOVELYRouter")).deploy(factory.address, weth.address);
```

### Creating a pool, setting the pool operation fee
The pool is created for two given ERC-20 contracts.
Also, we specify another ERC-20 token, in which the pool validation fee is received and the amount of this fee.
```javascript
// Amount
let amount = ethers.utils.parseEther('17.0');

// Create a pair
await factory.createValidatedPair(first.address, second.address, weth.address, amount);
```

### Reading the validation constraint
After creating a liquidity pool, it may be necessary to determine
the validation token and validation token amount.
```javascript
let pair = await factory.getPair(first.address, second.address);
const pairToken = await (await ethers.getContractFactory("LOVELYPairToken")).attach(pair);
let validationConstraint = await pairToken.getValidationConstraint();
```

### Validating this pool
After getting a created pair from the factory,
the "validate" method can be called taking-out the validation amount
in the token specified for paying this validation amount.
```javascript
let pair = await factory.getPair(first.address, second.address);
await weth.approve(pair, amount);
const pairToken = await (await ethers.getContractFactory("LOVELYPairToken")).attach(pair);
await pairToken.validate();
```

### Adding liquidity to the pool
Finally, we add the liquidity.
This action also defines the pair initial exchange rate 
or changes the exchange rate on sub-sequent calls.
```javascript
// Allow the "router" to spend liquidity amounts
await first.approve(router.address, amount);
await second.approve(router.address, amount);

// Add liquidity
await router.addLiquidity(
    first.address,
    second.address,
    amount,
    amount,
    0,
    0,
    owner.address,
    moment().unix() + 500
);
```

### Rejecting liquidity to the pool
In case, when the pool was not validated,
any operations on it will be rejected.
In the test above, this is easy to be accomplished 
by commenting-out the "validate" call.
