const {ethers} = require("hardhat");
const moment = require("moment");
const {expect} = require("chai");
const constants = require("./constants");

describe("LOVELYRouter contract", function () {

    it("Should not route to non-validated pairs", async function () {

        const [owner] = await ethers.getSigners();

        // Tokens
        const first = await (await ethers.getContractFactory("LOVELYToken")).deploy();
        const second = await (await ethers.getContractFactory("LOVELYToken")).deploy();
        const weth = await (await ethers.getContractFactory("LOVELYToken")).deploy();

        // DEX
        const factory = await (await ethers.getContractFactory("LOVELYFactory")).deploy();
        const router = await (await ethers.getContractFactory("LOVELYRouter")).deploy(factory.address, weth.address);

        // Amount
        let amount = ethers.utils.parseEther('17.0');
        let zero = ethers.utils.parseEther('0.0');

        // Validate tokens
        const tokenList = await (await ethers.getContractFactory("LOVELYTokenList")).attach(await factory.getTokenList());
        await tokenList.add(first.address, first.address, zero, zero);
        await tokenList.add(second.address, first.address, zero, zero);

        // Create a pair
        await factory.createValidatedPair(first.address, second.address, weth.address, amount, 7);

        // Allow the "router" to spend liquidity amounts
        await first.approve(router.address, amount);
        await second.approve(router.address, amount);

        // Add liquidity
        try {
            await router.addLiquidity(
                first.address,
                second.address,
                amount,
                amount,
                0,
                0,
                owner.address,
                moment().unix() + constants.TRANSACTION_DEADLINE
            );
        } catch (error) {
            expect(error.message).to.equal("VM Exception while processing transaction: reverted with reason string 'LOVELY DEX: NON_VALIDATED_PAIR'");
        }
    });

    it("Should route to validated pairs", async function () {

        const [owner] = await ethers.getSigners();

        // Tokens
        const first = await (await ethers.getContractFactory("LOVELYToken")).deploy();
        const second = await (await ethers.getContractFactory("LOVELYToken")).deploy();
        const weth = await (await ethers.getContractFactory("LOVELYToken")).deploy();

        // DEX
        const factory = await (await ethers.getContractFactory("LOVELYFactory")).deploy();
        await factory.setFeeTo(owner.address);
        const router = await (await ethers.getContractFactory("LOVELYRouter")).deploy(factory.address, weth.address);

        // Amount
        let amount = ethers.utils.parseEther('17.0');
        let zero = ethers.utils.parseEther('0.0');

        // Validate tokens
        const tokenList = await (await ethers.getContractFactory("LOVELYTokenList")).attach(await factory.getTokenList());
        await tokenList.add(first.address, first.address, zero, zero);
        await tokenList.add(second.address, first.address, zero, zero);

        // Create a pair
        await factory.createValidatedPair(first.address, second.address, weth.address, amount, 7);

        let pair = await factory.getPair(first.address, second.address);
        await weth.approve(pair, amount);
        const pairToken = await (await ethers.getContractFactory("LOVELYPairToken")).attach(pair);
        await pairToken.validate();

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
            moment().unix() + constants.TRANSACTION_DEADLINE
        );
    });

    it("Should route twice", async function () {

        const [owner] = await ethers.getSigners();

        // Tokens
        const first = await (await ethers.getContractFactory("LOVELYToken")).deploy();
        const second = await (await ethers.getContractFactory("LOVELYToken")).deploy();
        const weth = await (await ethers.getContractFactory("LOVELYToken")).deploy();

        // DEX
        const factory = await (await ethers.getContractFactory("LOVELYFactory")).deploy();
        await factory.setFeeTo(owner.address);
        const router = await (await ethers.getContractFactory("LOVELYRouter")).deploy(factory.address, weth.address);

        // Amount
        let amount = ethers.utils.parseEther('17.0');
        let smallerAmount = ethers.utils.parseEther('3.0');
        let zero = ethers.utils.parseEther('0.0');

        // Validate tokens
        const tokenList = await (await ethers.getContractFactory("LOVELYTokenList")).attach(await factory.getTokenList());
        await tokenList.add(first.address, first.address, zero, zero);
        await tokenList.add(second.address, first.address, zero, zero);

        // Create a pair
        await factory.createValidatedPair(first.address, second.address, weth.address, amount, 7);

        let pair = await factory.getPair(first.address, second.address);
        await weth.approve(pair, amount);
        const pairToken = await (await ethers.getContractFactory("LOVELYPairToken")).attach(pair);
        await pairToken.validate();

        // Allow the "router" to spend liquidity amounts
        await first.approve(router.address, amount);
        await second.approve(router.address, amount);

        // Add liquidity
        await router.addLiquidity(
            first.address,
            second.address,
            smallerAmount,
            smallerAmount,
            0,
            0,
            owner.address,
            moment().unix() + constants.TRANSACTION_DEADLINE
        );
        await router.addLiquidity(
            first.address,
            second.address,
            smallerAmount,
            smallerAmount,
            0,
            0,
            owner.address,
            moment().unix() + constants.TRANSACTION_DEADLINE
        );
    });

    it("Should change the pool fee", async function () {

        const [owner] = await ethers.getSigners();

        // Tokens
        const first = await (await ethers.getContractFactory("LOVELYToken")).deploy();
        const second = await (await ethers.getContractFactory("LOVELYToken")).deploy();
        const weth = await (await ethers.getContractFactory("LOVELYToken")).deploy();

        // DEX
        const factory = await (await ethers.getContractFactory("LOVELYFactory")).deploy();
        await factory.setFeeTo(owner.address);
        const router = await (await ethers.getContractFactory("LOVELYRouter")).deploy(factory.address, weth.address);

        // Amount
        let amount = ethers.utils.parseEther('17.0');
        let zero = ethers.utils.parseEther('0.0');

        // Validate tokens
        const tokenList = await (await ethers.getContractFactory("LOVELYTokenList")).attach(await factory.getTokenList());
        await tokenList.add(first.address, first.address, zero, zero);
        await tokenList.add(second.address, first.address, zero, zero);

        // Create a pair
        await factory.createValidatedPair(first.address, second.address, weth.address, amount, 7);

        let pair = await factory.getPair(first.address, second.address);
        await weth.approve(pair, amount);
        const pairToken = await (await ethers.getContractFactory("LOVELYPairToken")).attach(pair);
        await pairToken.validate();

        // Change the fee
        await pairToken.setFee(17);

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
            moment().unix() + constants.TRANSACTION_DEADLINE
        );
    });

    async function testSwapWithFee(fee, activationBlock) {

        const [owner] = await ethers.getSigners();

        const now = Math.floor(Date.now() / 1000) + 1 * 24 * 60 * 60;

        // Tokens
        const first = await (await ethers.getContractFactory("LOVELYToken")).deploy();
        const second = await (await ethers.getContractFactory("LOVELYToken")).deploy();
        const weth = await (await ethers.getContractFactory("LOVELYToken")).deploy();

        // DEX
        const factory = await (await ethers.getContractFactory("LOVELYFactory")).deploy();
        await factory.setFeeTo(owner.address);
        const router = await (await ethers.getContractFactory("LOVELYRouter")).deploy(factory.address, weth.address);

        // Amount
        let amount = ethers.utils.parseEther('17.0');
        let zero = ethers.utils.parseEther('0.0');

        // Validate tokens
        const tokenList = await (await ethers.getContractFactory("LOVELYTokenList")).attach(await factory.getTokenList());
        await tokenList.add(first.address, first.address, zero, activationBlock);
        await tokenList.add(second.address, first.address, zero, activationBlock);

        // Create a pair
        await factory.createValidatedPair(first.address, second.address, weth.address, amount, 7);

        let pair = await factory.getPair(first.address, second.address);
        await weth.approve(pair, amount);
        const pairToken = await (await ethers.getContractFactory("LOVELYPairToken")).attach(pair);
        await pairToken.validate();

        // Change the fee
        await pairToken.setFee(fee);

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
            moment().unix() + constants.TRANSACTION_DEADLINE
        );

        await first.approve(router.address, amount);

        await router.swapExactTokensForTokens(
            amount,
            0,
            [first.address, second.address],
            owner.address,
            now + 120
        );
    }

    it("Should swap with 0% fee", async function () {
        await testSwapWithFee(0, 0);
    });

    it("Should swap with 0.3% fee", async function () {
        await testSwapWithFee(3, 0);
    });

    it("Should swap with 17% fee", async function () {
        await testSwapWithFee(17, 0);
    });

    it("Should swap with 100% fee", async function () {
        await testSwapWithFee(100, 0);
    });

    it("Should swap with 117% fee", async function () {
        await testSwapWithFee(117, 0);
    });

    it("Should fail swapping on inactive pools", async function () {
        const blockNumber = await ethers.provider.getBlockNumber();
        try {
            await testSwapWithFee(117, blockNumber + 1000);
        } catch (error) {
            expect(error.message).to.equal("VM Exception while processing transaction: reverted with reason string 'LOVELY DEX: INACTIVE_PAIR'");
        }
    })
});
