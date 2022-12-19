const {expect} = require("chai");
const {ethers} = require("hardhat");
const moment = require("moment");
const constants = require("./constants");

describe("LOVELYFarm contract", function () {

    it("Should create a farming pool with a balance and time span", async function () {

        const [owner] = await ethers.getSigners();

        // 1 day from now
        const now = Math.floor(Date.now() / 1000) + 1 * 24 * 60 * 60;
        // 3 more days from then
        const then = now + 3 * 24 * 60 * 60;

        // Tokens
        const first = await (await ethers.getContractFactory("LOVELYToken")).deploy();
        const second = await (await ethers.getContractFactory("LOVELYToken")).deploy();
        const weth = await (await ethers.getContractFactory("LOVELYToken")).deploy();

        // DEX
        const factory = await (await ethers.getContractFactory("LOVELYFactory")).deploy();

        // Farm
        const farm = await (await ethers.getContractFactory("LOVELYFarm")).deploy();

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
        const pairToken = await (await ethers.getContractFactory("LOVELYPairToken")).attach(pair);

        async function ensurePoolWithIdentifier(checkedIdentifier) {
            await farm.createPool(pairToken.address, owner.address, owner.address, amount, now.valueOf(), then.valueOf());
            let poolIdentifier = await farm.poolCount() - 1;
            expect(poolIdentifier).to.equal(checkedIdentifier);
            await farm.add(poolIdentifier, weth.address);
            await weth.transfer(farm.address, amount);

            const status = await farm.getStatus(poolIdentifier);
            const left = await farm.left(poolIdentifier);
            const period = await farm.blockPeriod(poolIdentifier);
            const liquidityTokenBalance = await farm.liquidityTokenBalanceOfPool(poolIdentifier);

            // Pool has not started yet
            expect(status).to.equal(0);
            // Amount should be available as reward
            expect(left).to.equal(amount);
            // Liquidity token balance should be all left
            expect(liquidityTokenBalance).to.equal(left);
            // Block period for 28000 blocks each of 3 days
            expect(period).to.equal(84000);
        }

        await ensurePoolWithIdentifier(0);
    });


    it("Should create a farming pool with a fee", async function () {

        const [owner] = await ethers.getSigners();

        // 1 day from now
        const now = Math.floor(Date.now() / 1000) + 1 * 24 * 60 * 60;
        // 3 more days from then
        const then = now + 3 * 24 * 60 * 60;

        // Tokens
        const first = await (await ethers.getContractFactory("LOVELYToken")).deploy();
        const second = await (await ethers.getContractFactory("LOVELYToken")).deploy();
        const weth = await (await ethers.getContractFactory("LOVELYToken")).deploy();

        // DEX
        const factory = await (await ethers.getContractFactory("LOVELYFactory")).deploy();

        // Farm
        const farm = await (await ethers.getContractFactory("LOVELYFarm")).deploy();

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
        const pairToken = await (await ethers.getContractFactory("LOVELYPairToken")).attach(pair);

        await farm.createPool(pairToken.address, owner.address, owner.address, amount, now.valueOf(), then.valueOf());
        let poolIdentifier = await farm.poolCount() - 1;
        await farm.add(poolIdentifier, weth.address);

        await farm.setFee(poolIdentifier, 17);
        const fee = await farm.getFee(poolIdentifier);
        expect(fee).to.equal(17);
    });

    it("Should keep fee out from withdrawals", async function () {

        // TODO:
        // expect(0).to.equal(1);
    });

    it("Should get pair address at position", async function () {

        const [owner] = await ethers.getSigners();

        // 1 day from now
        const now = Math.floor(Date.now() / 1000) + 1 * 24 * 60 * 60;
        // 3 more days from then
        const then = now + 3 * 24 * 60 * 60;

        // Tokens
        const first = await (await ethers.getContractFactory("LOVELYToken")).deploy();
        const second = await (await ethers.getContractFactory("LOVELYToken")).deploy();
        const weth = await (await ethers.getContractFactory("LOVELYToken")).deploy();

        // DEX
        const factory = await (await ethers.getContractFactory("LOVELYFactory")).deploy();

        // Farm
        const farm = await (await ethers.getContractFactory("LOVELYFarm")).deploy();

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
        const pairToken = await (await ethers.getContractFactory("LOVELYPairToken")).attach(pair);

        await farm.createPool(pairToken.address, owner.address, owner.address, amount, now.valueOf(), then.valueOf());
        let poolIdentifier = await farm.poolCount() - 1;
        await farm.add(poolIdentifier, weth.address);

        const pairAddress = await farm.at(0);
        expect(pairAddress).to.equal(weth.address);
    });

    it("Should deposit to a farming pool", async function () {

        const [owner] = await ethers.getSigners();

        // 1 day from now
        const now = Math.floor(Date.now() / 1000) + 1 * 24 * 60 * 60;
        // 3 more days from then
        const then = now + 3 * 24 * 60 * 60;

        // Tokens
        const first = await (await ethers.getContractFactory("LOVELYToken")).deploy();
        const second = await (await ethers.getContractFactory("LOVELYToken")).deploy();
        const weth = await (await ethers.getContractFactory("LOVELYToken")).deploy();

        // DEX
        const factory = await (await ethers.getContractFactory("LOVELYFactory")).deploy();
        const router = await (await ethers.getContractFactory("LOVELYRouter")).deploy(factory.address, weth.address);

        // Farm
        const farm = await (await ethers.getContractFactory("LOVELYFarm")).deploy();

        // Amount
        let amount = ethers.utils.parseEther('17.0');
        let biggerAmount = ethers.utils.parseEther('170.0');
        let zero = ethers.utils.parseEther('0.0');

        // Validate tokens
        const tokenList = await (await ethers.getContractFactory("LOVELYTokenList")).attach(await factory.getTokenList());
        await tokenList.add(first.address, first.address, zero, zero);
        await tokenList.add(second.address, first.address, zero, zero);

        // Create a pair
        await factory.createValidatedPair(first.address, second.address, weth.address, zero, 7);

        let pair = await factory.getPair(first.address, second.address);
        const pairToken = await (await ethers.getContractFactory("LOVELYPairToken")).attach(pair);

        // Allow the "router" to spend liquidity amounts
        await first.approve(router.address, biggerAmount);
        await second.approve(router.address, biggerAmount);

        // Add liquidity
        await router.addLiquidity(
            first.address,
            second.address,
            biggerAmount,
            biggerAmount,
            0,
            0,
            owner.address,
            moment().unix() + constants.TRANSACTION_DEADLINE
        );

        await farm.createPool(weth.address, owner.address, owner.address, amount, now.valueOf(), then.valueOf());
        let poolIdentifier = await farm.poolCount() - 1;
        await farm.add(poolIdentifier, pairToken.address);

        // Allow the "farm" to spend liquidity amounts
        await pairToken.approve(farm.address, amount);

        // Deposit to a farm
        await farm.deposit(0, amount);

        const userBalance = await farm.liquidityPoolBalanceOfUser(0);
        expect(userBalance).to.equal(amount);

        const farmBalance = await farm.liquidityTokenBalanceOfPool(0);
        expect(farmBalance).to.equal(amount);
    });

    it("Should withdraw from a farming pool", async function () {

        const [owner] = await ethers.getSigners();

        // 1 day from now
        const now = Math.floor(Date.now() / 1000) + 1 * 24 * 60 * 60;
        // 3 more days from then
        const then = now + 3 * 24 * 60 * 60;

        // Tokens
        const first = await (await ethers.getContractFactory("LOVELYToken")).deploy();
        const second = await (await ethers.getContractFactory("USDTToken")).deploy();
        const weth = await (await ethers.getContractFactory("WETHToken")).deploy();

        // DEX
        const factory = await (await ethers.getContractFactory("LOVELYFactory")).deploy();
        const router = await (await ethers.getContractFactory("LOVELYRouter")).deploy(factory.address, weth.address);

        // Farm
        const farm = await (await ethers.getContractFactory("LOVELYFarm")).deploy();

        // Amount
        let amount = ethers.utils.parseEther('17.0');
        let feeAmount = ethers.utils.parseEther('0.289');
        let biggerAmount = ethers.utils.parseEther('170.0');
        let zero = ethers.utils.parseEther('0.0');

        // Validate tokens
        const tokenList = await (await ethers.getContractFactory("LOVELYTokenList")).attach(await factory.getTokenList());
        await tokenList.add(first.address, first.address, zero, zero);
        await tokenList.add(second.address, first.address, zero, zero);

        // Create a pair
        await factory.createValidatedPair(first.address, second.address, weth.address, zero, 3);

        let pair = await factory.getPair(first.address, second.address);
        const pairToken = await (await ethers.getContractFactory("LOVELYPairToken")).attach(pair);

        // Allow the "router" to spend liquidity amounts
        await first.approve(router.address, biggerAmount);
        await second.approve(router.address, biggerAmount);

        // Add liquidity
        await router.addLiquidity(
            first.address,
            second.address,
            biggerAmount,
            biggerAmount,
            0,
            0,
            owner.address,
            moment().unix() + constants.TRANSACTION_DEADLINE
        );

        await farm.createPool(weth.address, owner.address, owner.address, amount, now.valueOf(), then.valueOf());
        let poolIdentifier = await farm.poolCount() - 1;
        await farm.add(poolIdentifier, pairToken.address);
        await farm.setFee(poolIdentifier, 17);

        // Allow the "farm" to spend liquidity amounts
        await pairToken.approve(farm.address, amount);

        // Deposit to a farm
        await farm.deposit(0, amount);

        let userBalance = await farm.liquidityPoolBalanceOfUser(0);
        expect(userBalance).to.equal(amount);

        let farmBalance = await farm.liquidityTokenBalanceOfPool(0);
        expect(farmBalance).to.equal(amount);

        await farm.withdraw(0, amount);

        userBalance = await farm.liquidityPoolBalanceOfUser(0);
        expect(userBalance).to.equal(0);

        farmBalance = await farm.liquidityTokenBalanceOfPool(0);
        expect(farmBalance).to.equal(feeAmount);
    });

    it("Should return block period to start", async function () {

        const [owner] = await ethers.getSigners();

        // 1 day from now
        const now = Math.floor(Date.now() / 1000) + 1 * 24 * 60 * 60;
        // 3 more days from then
        const then = now + 3 * 24 * 60 * 60;

        // Tokens
        const first = await (await ethers.getContractFactory("LOVELYToken")).deploy();
        const second = await (await ethers.getContractFactory("LOVELYToken")).deploy();
        const weth = await (await ethers.getContractFactory("LOVELYToken")).deploy();

        // DEX
        const factory = await (await ethers.getContractFactory("LOVELYFactory")).deploy();
        const router = await (await ethers.getContractFactory("LOVELYRouter")).deploy(factory.address, weth.address);

        // Farm
        const farm = await (await ethers.getContractFactory("LOVELYFarm")).deploy();

        // Amount
        let amount = ethers.utils.parseEther('17.0');
        let biggerAmount = ethers.utils.parseEther('170.0');
        let zero = ethers.utils.parseEther('0.0');

        // Validate tokens
        const tokenList = await (await ethers.getContractFactory("LOVELYTokenList")).attach(await factory.getTokenList());
        await tokenList.add(first.address, first.address, zero, zero);
        await tokenList.add(second.address, first.address, zero, zero);

        // Create a pair
        await factory.createValidatedPair(first.address, second.address, weth.address, zero, 7);

        let pair = await factory.getPair(first.address, second.address);
        const pairToken = await (await ethers.getContractFactory("LOVELYPairToken")).attach(pair);

        // Allow the "router" to spend liquidity amounts
        await first.approve(router.address, biggerAmount);
        await second.approve(router.address, biggerAmount);

        // Add liquidity
        await router.addLiquidity(
            first.address,
            second.address,
            biggerAmount,
            biggerAmount,
            0,
            0,
            owner.address,
            moment().unix() + constants.TRANSACTION_DEADLINE
        );

        await farm.createPool(weth.address, owner.address, owner.address, amount, now.valueOf(), then.valueOf());
        let poolIdentifier = await farm.poolCount() - 1;
        await farm.add(poolIdentifier, pairToken.address);

        const blockPeriodToStart = await farm.blockPeriodToStart(poolIdentifier);
        // expect(blockPeriodToStart).to.approximately(27905, 500);
    });
});
