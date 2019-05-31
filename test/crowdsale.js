const timeTravel = require('./helpers/timeTravel').timeTravel;
const expectThrow = require('./helpers/expectThrow').expectThrow;

const Whitelist = artifacts.require('./Whitelist.sol');
const MultiSig = artifacts.require('./MultiSig.sol');
const Token = artifacts.require('./TokennToken.sol');
const Swapper = artifacts.require('./Uniswapper');
const Exchange = artifacts.require('./TokenExchange.sol');

let Crowdsale = artifacts.require('./TokennCrowdsale.sol');

contract('Crowdsale', async accounts => {
    let day = 86400;
    const hour = 3600;
    let crowdsalePeriod = 10 * day;

    let start = parseInt(new Date().getTime() / 1000) + hour; // now + 1 hour for presale
    let end = start + crowdsalePeriod;
    let tokenBuyRate = 1;
    let liquidityPercent = 20;

    let whitelist;
    let multisig;
    let token;
    let swapper;

    let crowdsale;
    let exchange;

    beforeEach(async () => {
        whitelist = await Whitelist.new();
        multisig = await MultiSig.new();
        exchange = await Exchange.new();

        crowdsale = await Crowdsale.new(start, end, whitelist.address, tokenBuyRate, multisig.address, accounts[0], accounts[1], liquidityPercent);
        token = await Token.new(crowdsale.address);
        swapper = await Swapper.new(token.address, exchange.address, tokenBuyRate);

        await exchange.setup(token.address);

        await whitelist.addToWhitelist(accounts);
        await crowdsale.setTokenContractAddress(token.address);
        await crowdsale.setUniswapperAddress(swapper.address);
    });

    it('should pass everything', async () => {

        // trying to buy tokens before crowdsale start
        expectThrow(
            crowdsale.sendTransaction({value: 50e18})
        );

        // mint token for pre crowdsale buyer
        await crowdsale.mintTokenForPreCrowdsale(accounts[5], 5000);
        const preMinted = await token.balanceOf.call(accounts[5]);
        assert.equal(parseInt(preMinted), 5000);

        // starting crowdsale...
        await timeTravel(hour);

        //trying to mint precrowd tokens after start
        expectThrow(
            crowdsale.mintTokenForPreCrowdsale(accounts[2], 5000)
        );

        //unpause crowdsale
        await crowdsale.unpause();

        // buying tokens...
        await crowdsale.sendTransaction({value: 50e18});
        await crowdsale.sendTransaction({from: accounts[1], value: 50e18});
        await crowdsale.sendTransaction({from: accounts[2], value: 50e18});

        assert.equal(parseInt(await token.getTotalSupply.call()), 150e18);

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
