import moment from "moment";

const fs = require('fs');
import '@nomiclabs/hardhat-ethers';
import {ethers} from "hardhat";

async function deploy() {

    const [owner] = await ethers.getSigners();
    const investor1 = "0x1cA939dAC75A5C6e81a14537A5EeBF23e5Ac11eE";

    const lovelyToken = await (await ethers.getContractFactory("LOVELYToken")).deploy();
    const wethToken = await (await ethers.getContractFactory("WETHToken")).deploy();
    const busdToken = await (await ethers.getContractFactory("BUSDToken")).deploy();
    const usdtToken = await (await ethers.getContractFactory("USDTToken")).deploy();
    const factory = await (await ethers.getContractFactory("LOVELYFactory")).deploy();
    const router = await (await ethers.getContractFactory("LOVELYRouter")).deploy(factory.address, wethToken.address);
    const farm = await (await ethers.getContractFactory("LOVELYFarm")).deploy();
    const controller = await (await ethers.getContractFactory("LOVELYController")).deploy(lovelyToken.address, owner.address, owner.address);

    // Amount
    let amount = ethers.utils.parseEther('17.0');
    let amount2 = ethers.utils.parseEther('17.0');
    let amount3 = ethers.utils.parseEther('1.7');
    let zero = ethers.utils.parseEther('0.0');

    const blockNumber = await ethers.provider.getBlockNumber();

    // Validate tokens
    const tokenList = await (await ethers.getContractFactory("LOVELYTokenList")).attach(await factory.getTokenList());
    await tokenList.add(wethToken.address, usdtToken.address, zero, zero);
    await tokenList.add(busdToken.address, usdtToken.address, zero, zero);
    await tokenList.add(usdtToken.address, usdtToken.address, zero, blockNumber + 100000);
    await tokenList.add(lovelyToken.address, usdtToken.address, zero, zero);

    // Create stable-coin liquidity pools
    await factory.createValidatedPair(wethToken.address, busdToken.address, wethToken.address, zero, 3);
    await factory.createValidatedPair(wethToken.address, usdtToken.address, wethToken.address, zero, 7);
    await factory.createValidatedPair(usdtToken.address, busdToken.address, wethToken.address, zero, 17);

    // Set the main token
    await factory.setMainToken(lovelyToken.address);

    // Create LOVELY liquidity pools
    await factory.createValidatedPair(lovelyToken.address, busdToken.address, wethToken.address, zero, 3);
    await factory.createValidatedPair(lovelyToken.address, usdtToken.address, wethToken.address, zero, 7);
    await factory.createValidatedPair(lovelyToken.address, wethToken.address, wethToken.address, zero, 17);

    // Add liquidity into pools
    async function addLiquidity(first: any, second: any, amountFirst: any, amountSecond: any) {
        await first.approve(router.address, amountFirst);
        await second.approve(router.address, amountSecond);
        await router.addLiquidity(
            first.address,
            second.address,
            amountFirst,
            amountSecond,
            0,
            0,
            owner.address,
            moment().utc().unix() + 500
        );
    }

    await addLiquidity(wethToken, busdToken, amount, amount2);
    await addLiquidity(wethToken, usdtToken, amount, amount2);
    await addLiquidity(usdtToken, busdToken, amount2, amount2);

    // Pair token
    let pair = await factory.getPair(wethToken.address, busdToken.address);
    const pairToken = await (await ethers.getContractFactory("LOVELYPairToken")).attach(pair);

    // Transfer tokens to test investors
    await lovelyToken.transfer(investor1, amount);
    await wethToken.transfer(investor1, amount);
    await busdToken.transfer(investor1, amount);
    await usdtToken.transfer(investor1, amount);

    // Transfer liquidity to test investors
    await pairToken.transfer(investor1, amount3);

    const addresses = {
        LOVELYToken: lovelyToken.address,
        WETHToken: wethToken.address,
        BUSDToken: busdToken.address,
        USDTToken: usdtToken.address,
        LOVELYFactory: factory.address,
        LOVELYRouter: router.address,
        LOVELYFarm: farm.address,
        LOVELYController: controller.address
    };
    fs.writeFileSync("./artifacts/addresses.json", JSON.stringify(addresses));
    // TODO: Remove that after updating CI/CD
    fs.writeFileSync("addresses.json", JSON.stringify(addresses));
}

deploy().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
