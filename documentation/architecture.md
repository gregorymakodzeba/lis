# Architecture

## LOVELY Pair Token
This is the ERC-20 token which represents the liquidity pool.
I.e. "the liquidity pool token".
Contains the Uniswap V2 customization code which:
- Defines the fee after paying which the liquidity pool becomes operational.
- Blocks pool operations before paying the fee.
Blocking the pool is performed in the "getReserves" method which is called for any balance change operations.
- Validates the pool by calling the "validate" method, which accepts
the given fee amount in the specified ERC-20 token.

## LOVELY Factory
This is a factory class which creates validated pools.
While creating a pool, you specify:
- Pool pair contracts.
- A contract for the ERC-20 token in which the fees are paid.
- Validation fee amount.

## LOVELY Router
The router is the contract responsible for various exchange operations.
It wraps the pool in a safe way convenient for developing.
Also, it can be replaced to implement new operations on the pool.

## LOVELY Token
This ERC-20 token is currently used for testing.
It is used instead of the existing LOVELY token.
