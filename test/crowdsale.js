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
    let crowdsalePeriod = 10 * day;

    let start = parseInt(new Date().getTime() / 1000) + 600; // now + 10 minute
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

        crowdsale = await Crowdsale.new(start, end, whitelist.address, tokenBuyRate, multisig.address, accounts[0], liquidityPercent);
        token = await Token.new(crowdsale.address);
        swapper = await Swapper.new(token.address, exchange.address, tokenBuyRate);

        await whitelist.addToWhitelist(accounts);
        await crowdsale.setTokenContractAddress(token.address);
        await crowdsale.setUniswapperAddress(swapper.address);

    });

    it('should buy tokens', async () => {
        await timeTravel(600 * 3);
        await crowdsale.sendTransaction({value: 1e18});
        assert.equal(parseInt(await token.getTotalSupply.call()), 1e18);

        await timeTravel(end + 600);
        await crowdsale.finalize();

        await timeTravel(day);
        console.log(parseInt(await web3.eth.getBalance(swapper.address)));
        await swapper.unlock();

        console.log(parseInt(await swapper.ethRemoved()));
        console.log(parseInt(await swapper.tokensRemoved()));

        console.log(parseInt(await web3.eth.getBalance(swapper.address)));
    });
});
