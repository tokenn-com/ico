const timeTravel = require('./helpers/timeTravel').timeTravel;
const expectThrow = require('./helpers/expectThrow').expectThrow;

const Whitelist = artifacts.require('./Whitelist.sol');
const MultiSig = artifacts.require('./MultiSig.sol');
const Token = artifacts.require('./TokennToken.sol');
const Swapper = artifacts.require('./Uniswapper');
const Exchange = artifacts.require('./TokenExchange.sol');
const TAA = artifacts.require('./TeamAndAdvisorsAllocation.sol');

const Crowdsale = artifacts.require('./TokennCrowdsale.sol');

contract('Crowdsale', async accounts => {
    const minute = 60;
    const hour = 3600;
    const day = 86400;

    const crowdsalePeriod = hour;
    const tokenBuyRate = 25;
    const rewardWallet = accounts[1];
    const nonVestedWallet = accounts[2];
    const liquidityPercent = 20;

    const earlyBuyerValue = web3.utils.toHex(80000000000000000);
    const buyerValue =  web3.utils.toHex(2e18);

    let whitelist;
    let multisig;
    let token;
    let swapper;
    let taa;
    let crowdsale;
    let exchange;

    beforeEach(async () => {
        const block = await web3.eth.getBlock("latest");

        const start = block.timestamp + hour; // now + 1 hour for presale
        const end = start + crowdsalePeriod;

        whitelist = await Whitelist.new();
        multisig = await MultiSig.new();
        exchange = await Exchange.new();
        crowdsale = await Crowdsale.new(start, end, whitelist.address, tokenBuyRate, multisig.address, rewardWallet, nonVestedWallet, liquidityPercent);
        token = await Token.new(crowdsale.address);
        swapper = await Swapper.new(token.address, exchange.address, tokenBuyRate);
        taa = await TAA.new(token.address);

        await exchange.setup(token.address);

        await whitelist.addToWhitelist(accounts);
        await crowdsale.setTokenContractAddress(token.address);
        await crowdsale.setUniswapperAddress(swapper.address);
        await crowdsale.setTeamWalletAddress(taa.address);
    });

    it("should revert buying tokens in pre crowdsale", async () => {
        await expectThrow(
            crowdsale.sendTransaction({value: buyerValue})
        );
    });

    it("should mint tokens for pre crowdsale investors", async () => {
        await crowdsale.mintTokenForPreCrowdsale(accounts[2], buyerValue);
        const minted = await token.balanceOf.call(accounts[2]);
        assert.equal(parseInt(minted), parseInt(buyerValue));
    });

    it("should throw minting tokens after crowdsale start time", async () => {
        timeTravel(hour);
        await expectThrow(
            crowdsale.mintTokenForPreCrowdsale(accounts[2], buyerValue)
        );
    });

    it("should throw early tokens with big amount", async () => {
        timeTravel(hour);
        await crowdsale.unpause();
        await expectThrow(
            crowdsale.sendTransaction({value: buyerValue})
        );
    });

    it("should buy early tokens", async () => {
        timeTravel(hour);
        await crowdsale.unpause();
        await crowdsale.sendTransaction({value: earlyBuyerValue});
        const bought = await token.balanceOf(accounts[0]);
        assert.equal(parseInt(bought), parseInt(earlyBuyerValue) * tokenBuyRate);
    });

    it("should by big token amount after early period eneded", async () => {
        timeTravel(hour);
        await crowdsale.unpause();
        timeTravel(10 * minute);
        crowdsale.sendTransaction({from: accounts[1], value: buyerValue});
        const bought = await token.balanceOf(accounts[1]);
        assert.equal(parseInt(bought), parseInt(buyerValue) * tokenBuyRate);
    });

    it("should finalize crowdsale", async () => {
        await crowdsale.unpause();
        timeTravel(hour);
        timeTravel(10 * minute);
        await crowdsale.sendTransaction({value: buyerValue * 5});
        timeTravel(hour);
        await crowdsale.finalize();
        console.log(parseInt(await swapper.ethSent.call()));
        console.log(parseInt(await swapper.tokenSent.call()));
        console.log(parseInt(await token.balanceOf(swapper.address)));
    });

    it("should unlock liquidity", async () => {
        await crowdsale.unpause();
        timeTravel(hour);
        timeTravel(10 * minute);
        await crowdsale.sendTransaction({value: buyerValue * 5});
        timeTravel(hour);
        await crowdsale.finalize();
        timeTravel(hour);
        await swapper.unlock();
        console.log(parseInt(await swapper.ethRemoved.call()));
        console.log(parseInt(await swapper.tokensRemoved.call()));
    });
});
