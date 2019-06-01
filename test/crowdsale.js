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
    const day = 86400;
    const hour = 3600;
    const crowdsalePeriod = 10 * day;

    const start = parseInt(new Date().getTime() / 1000) + hour; // now + 1 hour for presale
    const end = start + crowdsalePeriod;
    const tokenBuyRate = 1;
    const liquidityPercent = 20;

    const rewardWallet = accounts[1];
    const nonVestedWallet = accounts[2];

    let whitelist;
    let multisig;
    let token;
    let swapper;
    let taa;
    let crowdsale;
    let exchange;

    beforeEach(async () => {
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

    it('should pass everything', async () => {

        // trying to buy tokens before crowdsale start
        expectThrow(
            crowdsale.sendTransaction({value: 50e18})
        );

        // mint token for pre crowdsale buyer
        await crowdsale.mintTokenForPreCrowdsale(accounts[5], 2);
        const preMinted = await token.balanceOf.call(accounts[5]);
        assert.equal(parseInt(preMinted), 2);

        // starting crowdsale...
        await timeTravel(hour);

        //trying to mint precrowd tokens after start
        expectThrow(
            crowdsale.mintTokenForPreCrowdsale(accounts[2], 5000)
        );

        //unpause crowdsale
        await crowdsale.unpause();

        // buying tokens...
        await crowdsale.sendTransaction({value: 1e18});
        await crowdsale.sendTransaction({from: accounts[1], value: 1e18});
        await crowdsale.sendTransaction({from: accounts[2], value: 1e18});

        assert.equal(parseInt(await token.getTotalSupply.call()), 3e18);

        // ending crowdsale with sending tokens and ether to uniswap exchange
        await timeTravel(end + 600);
        await crowdsale.finalize();

        const ethSent = await swapper.ethSent();
        const tokensSent = await swapper.tokenSent();

        // unlocking liquidity after certain period of time
        await timeTravel(3600);
        await swapper.unlock();

        const ethRemoved = await swapper.ethRemoved();
        const tokensRemoved = await swapper.tokensRemoved();

        assert.equal(parseInt(ethSent), parseInt(ethRemoved));
        assert.equal(parseInt(tokensSent), parseInt(tokensRemoved));

    });
});
