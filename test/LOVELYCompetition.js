const {expect} = require("chai");
const {ethers} = require("hardhat");
const moment = require("moment");
const constants = require("./constants");

Math.randomValue = function (min, max, asFloat){
    var r = Math.random() * (max - min) + min;
    return asFloat ? r : Math.round(r);
}

// 
// Events can be created with the following tiers.
//
// Tiers: 5-10-20-50.
// Which is 5 + 5 + 10 + 30 amount of users.
//
// Which can be the 5 * 5% + 5 * 5% + 10 * 2% + 30 * 1% percentage distribution.
//
describe("LOVELYCompetition contract", function () {

    it("Should create a competition for (1) a validated token, (2) a future block range, (3) a valid reward amount", async function () {

        const [owner] = await ethers.getSigners();

        // Tokens
        const first = await (await ethers.getContractFactory("LOVELYToken")).deploy();
        const second = await (await ethers.getContractFactory("USDTToken")).deploy();
        const weth = await (await ethers.getContractFactory("WETHToken")).deploy();

        // DEX
        const factory = await (await ethers.getContractFactory("LOVELYFactory")).deploy();

        // Amount
        let amount = ethers.utils.parseEther('17.0');
        let smallerAmount = ethers.utils.parseEther('11.0');
        let zero = ethers.utils.parseEther('0.0');

        // Validate tokens
        const tokenList = await (await ethers.getContractFactory("LOVELYTokenList")).attach(await factory.getTokenList());
        await tokenList.add(first.address, first.address, zero, zero);
        await tokenList.add(second.address, first.address, zero, zero);

        // Competition
        const competition = await (await ethers.getContractFactory("LOVELYCompetition")).deploy(factory.address, weth.address, tokenList.address);
        await competition.setMinimumRewardAmount(smallerAmount);

        // Allowance for the reward amount
        await first.approve(competition.address, amount);

        // Create an event
        const blockNumber = await ethers.provider.getBlockNumber() + 1;
        await competition.create(blockNumber, blockNumber + 1000, amount, first.address, [5, 5, 2, 1]);

        expect(await competition.eventCount()).to.equal(1);
    });

    it("Should not create a competition for a non-validated token", async function () {

        const [owner] = await ethers.getSigners();

        // Tokens
        const first = await (await ethers.getContractFactory("LOVELYToken")).deploy();
        const second = await (await ethers.getContractFactory("USDTToken")).deploy();
        const third = await (await ethers.getContractFactory("BUSDToken")).deploy();
        const weth = await (await ethers.getContractFactory("WETHToken")).deploy();

        // DEX
        const factory = await (await ethers.getContractFactory("LOVELYFactory")).deploy();

        // Amount
        let amount = ethers.utils.parseEther('17.0');
        let smallerAmount = ethers.utils.parseEther('11.0');
        let zero = ethers.utils.parseEther('0.0');

        // Validate tokens
        const tokenList = await (await ethers.getContractFactory("LOVELYTokenList")).attach(await factory.getTokenList());
        await tokenList.add(first.address, first.address, zero, zero);
        await tokenList.add(second.address, first.address, zero, zero);

        // Competition
        const competition = await (await ethers.getContractFactory("LOVELYCompetition")).deploy(factory.address, weth.address, tokenList.address);
        await competition.setMinimumRewardAmount(smallerAmount);

        // Allowance for the reward amount
        await first.approve(competition.address, amount);

        // Create an event
        const blockNumber = await ethers.provider.getBlockNumber();
        try {
            await competition.create(blockNumber, blockNumber + 1000, amount, third.address, [5, 5, 2, 1]);
        } catch(error) {
        }

        expect(await competition.eventCount()).to.equal(0);
    });

    it("Should not create a competition for a past block range", async function () {

        const [owner] = await ethers.getSigners();

        // Tokens
        const first = await (await ethers.getContractFactory("LOVELYToken")).deploy();
        const second = await (await ethers.getContractFactory("USDTToken")).deploy();
        const weth = await (await ethers.getContractFactory("WETHToken")).deploy();

        // DEX
        const factory = await (await ethers.getContractFactory("LOVELYFactory")).deploy();

        // Amount
        let amount = ethers.utils.parseEther('17.0');
        let zero = ethers.utils.parseEther('0.0');

        // Validate tokens
        const tokenList = await (await ethers.getContractFactory("LOVELYTokenList")).attach(await factory.getTokenList());
        await tokenList.add(first.address, first.address, zero, zero);
        await tokenList.add(second.address, first.address, zero, zero);

        // Competition
        const competition = await (await ethers.getContractFactory("LOVELYCompetition")).deploy(factory.address, weth.address, tokenList.address);

        // Allowance for the reward amount
        await first.approve(competition.address, amount);

        // Create an event
        const blockNumber = await ethers.provider.getBlockNumber() - 1;
        try {
            await competition.create(blockNumber, blockNumber + 1000, amount, first.address, [5, 5, 2, 1]);
        } catch (error) {
        }

        expect(await competition.eventCount()).to.equal(0);
    });

    it("Should not create a competition for a small reward amount", async function () {

        const [owner] = await ethers.getSigners();

        // Tokens
        const first = await (await ethers.getContractFactory("LOVELYToken")).deploy();
        const second = await (await ethers.getContractFactory("USDTToken")).deploy();
        const weth = await (await ethers.getContractFactory("WETHToken")).deploy();

        // DEX
        const factory = await (await ethers.getContractFactory("LOVELYFactory")).deploy();

        // Amount
        let amount = ethers.utils.parseEther('17.0');
        let smallerAmount = ethers.utils.parseEther('11.0');
        let zero = ethers.utils.parseEther('0.0');

        // Validate tokens
        const tokenList = await (await ethers.getContractFactory("LOVELYTokenList")).attach(await factory.getTokenList());
        await tokenList.add(first.address, first.address, zero, zero);
        await tokenList.add(second.address, first.address, zero, zero);

        // Competition
        const competition = await (await ethers.getContractFactory("LOVELYCompetition")).deploy(factory.address, weth.address, tokenList.address);
        await competition.setMinimumRewardAmount(amount);

        // Allowance for the reward amount
        await first.approve(competition.address, amount);

        // Create an event
        const blockNumber = await ethers.provider.getBlockNumber() + 1;
        try {
            await competition.create(blockNumber, blockNumber + 1000, smallerAmount, first.address, [5, 5, 2, 1]);
        } catch (error) {
        }

        expect(await competition.eventCount()).to.equal(0);
    });


    it("Should not create a competition for tiers sum not being 100%", async function () {

        const [owner] = await ethers.getSigners();

        // Tokens
        const first = await (await ethers.getContractFactory("LOVELYToken")).deploy();
        const second = await (await ethers.getContractFactory("USDTToken")).deploy();
        const weth = await (await ethers.getContractFactory("WETHToken")).deploy();

        // DEX
        const factory = await (await ethers.getContractFactory("LOVELYFactory")).deploy();

        // Amount
        let amount = ethers.utils.parseEther('17.0');
        let smallerAmount = ethers.utils.parseEther('11.0');
        let zero = ethers.utils.parseEther('0.0');

        // Validate tokens
        const tokenList = await (await ethers.getContractFactory("LOVELYTokenList")).attach(await factory.getTokenList());
        await tokenList.add(first.address, first.address, zero, zero);
        await tokenList.add(second.address, first.address, zero, zero);

        // Competition
        const competition = await (await ethers.getContractFactory("LOVELYCompetition")).deploy(factory.address, weth.address, tokenList.address);
        await competition.setMinimumRewardAmount(smallerAmount);

        // Allowance for the reward amount
        await first.approve(competition.address, amount);

        // Create an event
        const blockNumber = await ethers.provider.getBlockNumber() + 1;
        try {
            await competition.create(blockNumber, blockNumber + 1000, amount, first.address, [5, 5, 2, 2]);
        } catch (error) {
        }

        expect(await competition.eventCount()).to.equal(0);
    });


    it("User should be able to register in the competition", async function () {

        const [owner, address1, address2] = await ethers.getSigners();

        // Tokens
        const first = await (await ethers.getContractFactory("LOVELYToken")).deploy();
        const second = await (await ethers.getContractFactory("USDTToken")).deploy();
        const weth = await (await ethers.getContractFactory("WETHToken")).deploy();

        // DEX
        const factory = await (await ethers.getContractFactory("LOVELYFactory")).deploy();

        // Amount
        let amount = ethers.utils.parseEther('17.0');
        let smallerAmount = ethers.utils.parseEther('11.0');
        let zero = ethers.utils.parseEther('0.0');

        // Validate tokens
        const tokenList = await (await ethers.getContractFactory("LOVELYTokenList")).attach(await factory.getTokenList());
        await tokenList.add(first.address, first.address, zero, zero);
        await tokenList.add(second.address, first.address, zero, zero);

        // Competition
        const competition = await (await ethers.getContractFactory("LOVELYCompetition")).deploy(factory.address, weth.address, tokenList.address);
        await competition.setMinimumRewardAmount(smallerAmount);

        // Allowance for the reward amount
        await first.approve(competition.address, amount);

        // Create an event
        const blockNumber = await ethers.provider.getBlockNumber() + 1;
        await competition.create(blockNumber, blockNumber + 1000, amount, first.address, [5, 5, 2, 1]);

        expect(await competition.eventCount()).to.equal(1);

        await competition.connect(address1).register(1);
        const registered = await competition.connect(address1).registered(1);

        expect(registered).to.equal(true);
    });

    it("Competition should transition to the claiming state and return the list of winners when enough participants were gathered", async function () {

        const [owner] = await ethers.getSigners();

        // Tokens
        const first = await (await ethers.getContractFactory("LOVELYToken")).deploy();
        const second = await (await ethers.getContractFactory("USDTToken")).deploy();
        const weth = await (await ethers.getContractFactory("WETHToken")).deploy();

        // DEX
        const factory = await (await ethers.getContractFactory("LOVELYFactory")).deploy();

        // Amount
        let amount = ethers.utils.parseEther('17.0');
        let hugeAmount = ethers.utils.parseEther('1700.0');
        let smallerAmount = ethers.utils.parseEther('11.0');
        let zero = ethers.utils.parseEther('0.0');

        // Validate tokens
        const tokenList = await (await ethers.getContractFactory("LOVELYTokenList")).attach(await factory.getTokenList());
        await tokenList.add(first.address, first.address, zero, zero);
        await tokenList.add(second.address, first.address, zero, zero);

        // Competition
        const competition = await (await ethers.getContractFactory("LOVELYCompetition")).deploy(factory.address, weth.address, tokenList.address);
        await competition.setMinimumRewardAmount(smallerAmount);

        // Allowance for the reward amount
        await first.approve(competition.address, amount);

        // Create an event
        const blockNumber = await ethers.provider.getBlockNumber() + 1;
        await competition.create(blockNumber, blockNumber + 1000, amount, first.address, [5, 5, 2, 1]);

        expect(await competition.eventCount()).to.equal(1);

        // Competition's audited router
        const auditedRouterAddress = await competition.eventRouter(0);
        const auditedRouter = await (await ethers.getContractFactory("LOVELYAuditedRouter")).attach(auditedRouterAddress);

        // Allow the "auditedRouter" to spend liquidity amounts
        await first.approve(auditedRouter.address, hugeAmount);
        await second.approve(auditedRouter.address, hugeAmount);

        // Add liquidity
        await auditedRouter.addLiquidity(
            first.address,
            second.address,
            hugeAmount,
            hugeAmount,
            0,
            0,
            owner.address,
            moment().unix() + constants.TRANSACTION_DEADLINE
        );

        async function participate(user) {

            const address = user.address;

            // Register in the competition
            await competition.connect(user).register(0);
            const registered = await competition.connect(user).registered(0);
            expect(registered).to.equal(true);

            // Get the balance
            await first.transfer(address, amount);
            await second.transfer(address, amount);

            // Swap randomly
            let randomAmount = Math.randomValue(1, 17);
            randomAmount = ethers.utils.parseEther(`${randomAmount}.0`);
            await first.connect(user).approve(auditedRouter.address, randomAmount);
            await auditedRouter
                .connect(user)
                .swapExactTokensForTokens(
                    randomAmount, 
                    0, 
                    [first.address, second.address], 
                    address, 
                    moment().unix() + constants.TRANSACTION_DEADLINE
                );
        }

        // Participate with 57 random participants
        for (let i = 0; i < 57; i++) {

            let user = ethers.Wallet.createRandom();
            user =  user.connect(ethers.provider);

            await owner.sendTransaction({
                to: user.address, 
                value: ethers.utils.parseEther("1")
            });

            await participate(user);
        }

        // Transition to the "Claiming" state
        await competition.eventTransition(0);
        await competition.eventTransition(0);
        await competition.eventTransition(0);
        const status = await competition.eventStatus(0);
        // "3" for "Claiming"
        expect(status).to.equal(3);

        // Get the list of winners
        const winners = await competition.eventWinners(0);
        expect(winners.length).to.equal(50);

        // for (const winner of winners) {
        //     const balance = await first.balanceOf(winner);
        //     console.log(`Balance of ${winner}`, balance);
        // }
    });

    it("Competition should not transition to the claiming state when not enough participants were gathered", async function () {

        const [owner, address1, address2] = await ethers.getSigners();

        // Tokens
        const first = await (await ethers.getContractFactory("LOVELYToken")).deploy();
        const second = await (await ethers.getContractFactory("USDTToken")).deploy();
        const weth = await (await ethers.getContractFactory("WETHToken")).deploy();

        // DEX
        const factory = await (await ethers.getContractFactory("LOVELYFactory")).deploy();

        // Amount
        let amount = ethers.utils.parseEther('17.0');
        let smallerAmount = ethers.utils.parseEther('11.0');
        let zero = ethers.utils.parseEther('0.0');

        // Validate tokens
        const tokenList = await (await ethers.getContractFactory("LOVELYTokenList")).attach(await factory.getTokenList());
        await tokenList.add(first.address, first.address, zero, zero);
        await tokenList.add(second.address, first.address, zero, zero);

        // Competition
        const competition = await (await ethers.getContractFactory("LOVELYCompetition")).deploy(factory.address, weth.address, tokenList.address);
        await competition.setMinimumRewardAmount(smallerAmount);

        // Allowance for the reward amount
        await first.approve(competition.address, amount);

        // Create an event
        const blockNumber = await ethers.provider.getBlockNumber() + 1;
        await competition.create(blockNumber, blockNumber + 1000, amount, first.address, [5, 5, 2, 1]);

        expect(await competition.eventCount()).to.equal(1);

        await competition.connect(address1).register(1);
        const registered = await competition.connect(address1).registered(1);

        expect(registered).to.equal(true);

        await competition.eventTransition(0);
        await competition.eventTransition(0);
        try {

        } catch (error) {
            await competition.eventTransition(0);
        }
        const status = await competition.eventStatus(0);
        // "2" for "Close"
        expect(status).to.equal(2);
    });
});
