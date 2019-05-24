let timeTravel = require('./helpers/timeTravel').timeTravel;
let expectThrow = require('./helpers/expectThrow').expectThrow;

let Whitelist = artifacts.require('./Whitelist.sol');
let MultiSig = artifacts.require('./MultiSig.sol');
let Token = artifacts.require('./TokennToken.sol');

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

    let crowdsale;

    beforeEach(async () => {
        whitelist = await Whitelist.new();
        multisig = await MultiSig.new();

        crowdsale = await Crowdsale.new(start, end, whitelist.address, tokenBuyRate, multisig.address, accounts[0], liquidityPercent);
        token = await Token.new(crowdsale.address);

        await crowdsale.setTokenContractAddress(token.address);

    });

    it('should deploy crodwsale', async () => {});

    it('should buy tokens', async () => {});
});
