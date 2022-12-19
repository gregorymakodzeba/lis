const {ethers} = require("hardhat");

async function testTokenListAdd() {

  const lovelyFactory = "0x55eb8ae8e9a5c30bd7d85a72eca2539fc39aabbd";
  const lovelyToken = "0x0fd5f4a2e4247cb774a47b112cea8586b38fcc7f";
  const second = lovelyToken;

  // Amount
  let amount = ethers.utils.parseEther('17.0');

  const Factory = await ethers.getContractFactory("LOVELYFactory");
  const hardhatFactory = await Factory.attach(lovelyFactory);
  const TokenList = await ethers.getContractFactory("LOVELYTokenList");
  const hardhatTokenList = await TokenList.attach(await hardhatFactory.getTokenList());
  await hardhatTokenList.add(lovelyToken, second, amount);
}

async function testTokenListAtFirst() {

  const lovelyFactory = "0x55eb8ae8e9a5c30bd7d85a72eca2539fc39aabbd";
  const lovelyToken = "0x0fd5f4a2e4247cb774a47b112cea8586b38fcc7f";
  const second = lovelyToken;

  // Amount
  let amount = ethers.utils.parseEther('17.0');

  const Factory = await ethers.getContractFactory("LOVELYFactory");
  const hardhatFactory = await Factory.attach(lovelyFactory);
  const TokenList = await ethers.getContractFactory("LOVELYTokenList");
  const hardhatTokenList = await TokenList.attach(await hardhatFactory.getTokenList());
  await hardhatTokenList.add(lovelyToken, second, amount);
  const tokenAt = await hardhatTokenList.at(0);
  console.log(tokenAt);
}

async function testTokenListFeeAt() {
  const lovelyFactory = "0x55a4D1D8E256A9e71F003c4D2A7Bd1272B594B31";
  // const lovelyToken = "0x0fd5f4a2e4247cb774a47b112cea8586b38fcc7f";
  // const second = lovelyToken;

  // Amount
  // let amount = ethers.utils.parseEther('17.0');

  const Factory = await ethers.getContractFactory("LOVELYFactory");
  const hardhatFactory = await Factory.attach(lovelyFactory);
  const TokenList = await ethers.getContractFactory("LOVELYTokenList");
  const hardhatTokenList = await TokenList.attach(await hardhatFactory.getTokenList());
  // await hardhatTokenList.add(lovelyToken, second, amount);
  const feeAt = await hardhatTokenList.feeAt(0);
  console.log(feeAt);
}

async function testFarmDeposit() {

  const lovelyFarm = "0xcbba19c0b3ad83a16be5aef6d6f19222f64417aa";
  const Farm = await ethers.getContractFactory("LOVELYFarm");
  const hardhatFarm = await Farm.attach(lovelyFarm);

  // const poolIdentifier = 1;
  for (let poolIdentifier = 0; poolIdentifier < 5; poolIdentifier++) {
    const userBalance = await hardhatFarm.liquidityPoolBalanceOfUser(poolIdentifier, {from: "0xc1ccad02d138293b633bf20ce20425056baf2076"});
    const farmBalance = await hardhatFarm.liquidityTokenBalanceOfPool(poolIdentifier, {from: "0xc1ccad02d138293b633bf20ce20425056baf2076"});
    console.log("Pool balance of user / token balance of pool", userBalance, farmBalance);
  }
}


async function deploy() {
  // await testTokenListAdd();
  // await testTokenListAtFirst();
  // await testTokenListFeeAt();
  await testFarmDeposit();
}

deploy().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
