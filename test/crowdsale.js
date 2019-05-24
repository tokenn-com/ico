let timeTravel = require('./helpers/timeTravel').timeTravel;
let expectThrow = require('./helpers/expectThrow').expectThrow;

let Whitelist = artifacts.require('./Whitelist.sol');
let MultiSig = artifacts.require('./MultiSig.sol');
let Token = artifacts.require('./TokennToken.sol');

let Crowdsale = artifacts.require('./TokennCrowdsale.sol');

contract('Crowdsale', async accounts => {
    let day = 86400;
    let crowdsalePeriod = day;

    let start = parseInt(new Date().getTime() / 1000); // now + 1 minute
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

        console.log(start);
        console.log(end);
        crowdsale = await Crowdsale.new.call(start, end, whitelist.address, tokenBuyRate, multisig.address, accounts[0], liquidityPercent);

        // token = await Token.new(crowdsale.address);

        // console.log(await crowdsale.token);

        // await crowdsale.setTokenContractAddress(token.address, {from: accounts[0]});
    });

    it('should deploy crodwsale', async () => {});

    it('should buy tokens', async () => {});
});
