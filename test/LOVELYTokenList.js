const {expect} = require("chai");
const {ethers} = require("hardhat");

describe("LOVELYTokenList contract", function () {

  // This condition is not possible anymore
  /*
  it("Added token can be not validated", async function () {

    const [owner] = await ethers.getSigners();

    // Tokens
    const first = await (await ethers.getContractFactory("LOVELYToken")).deploy();
    const second = await (await ethers.getContractFactory("LOVELYToken")).deploy();

    // Amount
    let amount = ethers.utils.parseEther('17.0');

    const TokenList = await ethers.getContractFactory("LOVELYTokenList");
    const hardhatTokenList = await TokenList.deploy(owner.address);
    await hardhatTokenList.add(first.address, second.address, amount);
    expect(await hardhatTokenList.validated(first.address)).to.equal(false);
  });
   */

  // This condition is not possible anymore
  /*
  it("Added token can be not validated by DEX owner with non-default validation amount", async function () {

    const [owner] = await ethers.getSigners();

    // Tokens
    const first = await (await ethers.getContractFactory("LOVELYToken")).deploy();
    const second = await (await ethers.getContractFactory("LOVELYToken")).deploy();

    // Amount
    let amount = ethers.utils.parseEther('17.0');
    let biggerAmount = ethers.utils.parseEther('17.0');

    const TokenList = await ethers.getContractFactory("LOVELYTokenList");
    const hardhatTokenList = await TokenList.deploy(owner.address);
    await hardhatTokenList.setDefaultValidationAmount(biggerAmount);
    await hardhatTokenList.add(first.address, second.address, amount);

    expect(await hardhatTokenList.validated(first.address)).to.equal(false);

    const defaultValidationAmount = await hardhatTokenList.getDefaultValidationAmount();
    expect(defaultValidationAmount).to.equal(biggerAmount);
  });
   */

  it("Added token can be validated", async function () {

    const [owner] = await ethers.getSigners();

    // Tokens
    const first = await (await ethers.getContractFactory("LOVELYToken")).deploy();
    const second = await (await ethers.getContractFactory("LOVELYToken")).deploy();

    // Amount
    let zero = ethers.utils.parseEther('0.0');

    const TokenList = await ethers.getContractFactory("LOVELYTokenList");
    const hardhatTokenList = await TokenList.deploy(owner.address);
    await hardhatTokenList.add(first.address, second.address, zero, zero);
    expect(await hardhatTokenList.validated(first.address)).to.equal(true);
  });

  it("Added token can be validated by paying the validation amount immediately", async function () {

    const [owner] = await ethers.getSigners();

    // Tokens
    const first = await (await ethers.getContractFactory("LOVELYToken")).deploy();
    const second = await (await ethers.getContractFactory("LOVELYToken")).deploy();

    // Amount
    let amount = ethers.utils.parseEther('17.0');
    let zero = ethers.utils.parseEther('0');

    const TokenList = await ethers.getContractFactory("LOVELYTokenList");
    const hardhatTokenList = await TokenList.deploy(owner.address);

    // Approve a payment in the second token
    await second.approve(hardhatTokenList.address, amount);

    await hardhatTokenList.add(first.address, second.address, amount, zero);

    expect(await hardhatTokenList.validated(first.address)).to.equal(true);
  });

  it("Should crash on validation when approval is not enough", async function () {

    const [owner] = await ethers.getSigners();

    // Tokens
    const first = await (await ethers.getContractFactory("LOVELYToken")).deploy();
    const second = await (await ethers.getContractFactory("LOVELYToken")).deploy();

    // Amount
    let amount1 = ethers.utils.parseEther('17.0');
    let amount2 = ethers.utils.parseEther('16.0');
    let zero = ethers.utils.parseEther('0');

    const TokenList = await ethers.getContractFactory("LOVELYTokenList");
    const hardhatTokenList = await TokenList.deploy(owner.address);

    // Approve a payment in the second token
    await second.approve(hardhatTokenList.address, amount2);

    try {
      await hardhatTokenList.add(first.address, second.address, amount1, zero);
    } catch (error) {
      expect(error.message).to.equal("VM Exception while processing transaction: reverted with reason string 'ERC20: insufficient allowance'");
    }
  });

  it("Address list should be readable", async function () {

    const [owner] = await ethers.getSigners();

    // Tokens
    const first = await (await ethers.getContractFactory("LOVELYToken")).deploy();
    const second = await (await ethers.getContractFactory("LOVELYToken")).deploy();

    // Amount
    let zero = ethers.utils.parseEther('0.0');

    const TokenList = await ethers.getContractFactory("LOVELYTokenList");
    const hardhatTokenList = await TokenList.deploy(owner.address);
    await hardhatTokenList.add(first.address, second.address, zero, zero);
    await hardhatTokenList.add(second.address, second.address, zero, zero);

    expect(await hardhatTokenList.at(0)).to.equal(first.address);
    expect(await hardhatTokenList.at(1)).to.equal(second.address);
  });

  it("Should crash on checking unknown tokens", async function () {

    const [owner] = await ethers.getSigners();

    // Tokens
    const first = await (await ethers.getContractFactory("LOVELYToken")).deploy();

    const TokenList = await ethers.getContractFactory("LOVELYTokenList");
    const hardhatTokenList = await TokenList.deploy(owner.address);

    // Validate the token
    try {
      await hardhatTokenList.validated(first.address);
    } catch (error) {
      expect(0 < error.message.indexOf("LOVELY DEX: NOT_EXISTS")).to.equal(true);
    }
  });
});
