const moment = require("moment");
const {expect} = require("chai");
const {ethers} = require("hardhat");

describe("LOVELYFactory contract", function () {

    it("The factory should create a pair", async function () {
        const first = await (await ethers.getContractFactory("LOVELYToken")).deploy();
        const second = await (await ethers.getContractFactory("LOVELYToken")).deploy();
        const weth = await (await ethers.getContractFactory("LOVELYToken")).deploy();

        let zero = ethers.utils.parseEther('0.0');

        const factory = await (await ethers.getContractFactory("LOVELYFactory")).deploy();

        // Validate tokens
        const tokenList = await (await ethers.getContractFactory("LOVELYTokenList")).attach(await factory.getTokenList());
        await tokenList.add(first.address, first.address, zero, zero);
        await tokenList.add(second.address, first.address, zero, zero);

        await factory.createValidatedPair(first.address, second.address, weth.address, 0, 7);
        const length = await factory.allPairsLength();
        expect(length).to.equal(1);
    });

    it("The factory should create a pair with default validation amount skipped for DEX owner", async function () {
        const first = await (await ethers.getContractFactory("LOVELYToken")).deploy();
        const second = await (await ethers.getContractFactory("LOVELYToken")).deploy();
        const weth = await (await ethers.getContractFactory("LOVELYToken")).deploy();

        let zero = ethers.utils.parseEther('0.0');
        let amount = ethers.utils.parseEther('17.0');

        const factory = await (await ethers.getContractFactory("LOVELYFactory")).deploy();

        // Set default validation amount
        await factory.setDefaultValidationAmount(amount);

        // Validate tokens
        const tokenList = await (await ethers.getContractFactory("LOVELYTokenList")).attach(await factory.getTokenList());
        await tokenList.add(first.address, first.address, zero, zero);
        await tokenList.add(second.address, first.address, zero, zero);

        await factory.createValidatedPair(first.address, second.address, weth.address, 0, 7);
        const length = await factory.allPairsLength();
        expect(length).to.equal(1);

        const defaultValidationAmount = await factory.getDefaultValidationAmount();
        expect(defaultValidationAmount).to.equal(amount);
    });

    it("Should inform about the validation constraint", async function () {

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

        let pair = await factory.getPair(first.address, second.address);
        const pairToken = await (await ethers.getContractFactory("LOVELYPairToken")).attach(pair);
        let validationConstraint = await pairToken.getValidationConstraint();
        expect(validationConstraint.validationToken).to.equal(weth.address);
        expect(validationConstraint.validationTokenAmount).to.equal(amount);
    });
});
