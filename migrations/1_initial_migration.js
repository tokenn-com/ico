const Migrations = artifacts.require("Migrations");
const WhiteList = artifacts.require("Whitelist");
const Multisig = artifacts.require("MultiSig");
const Crodwsale = artifacts.require("TokennCrowdsale");
const Token = artifacts.require("TokennToken");
const Uniswapper = artifacts.require("Uniswapper");

const FACTORY_ADDRESS = "0xf5D915570BC477f9B8D6C0E980aA81757A3AaC36";
const FACTORY_ABI = [{"name":"NewExchange","inputs":[{"type":"address","name":"token","indexed":true},{"type":"address","name":"exchange","indexed":true}],"anonymous":false,"type":"event"},{"name":"initializeFactory","outputs":[],"inputs":[{"type":"address","name":"template"}],"constant":false,"payable":false,"type":"function","gas":35725},{"name":"createExchange","outputs":[{"type":"address","name":"out"}],"inputs":[{"type":"address","name":"token"}],"constant":false,"payable":false,"type":"function","gas":187911},{"name":"getExchange","outputs":[{"type":"address","name":"out"}],"inputs":[{"type":"address","name":"token"}],"constant":true,"payable":false,"type":"function","gas":715},{"name":"getToken","outputs":[{"type":"address","name":"out"}],"inputs":[{"type":"address","name":"exchange"}],"constant":true,"payable":false,"type":"function","gas":745},{"name":"getTokenWithId","outputs":[{"type":"address","name":"out"}],"inputs":[{"type":"uint256","name":"token_id"}],"constant":true,"payable":false,"type":"function","gas":736},{"name":"exchangeTemplate","outputs":[{"type":"address","name":"out"}],"inputs":[],"constant":true,"payable":false,"type":"function","gas":633},{"name":"tokenCount","outputs":[{"type":"uint256","name":"out"}],"inputs":[],"constant":true,"payable":false,"type":"function","gas":663}];
const factoryContract = new web3.eth.Contract(FACTORY_ABI, FACTORY_ADDRESS);

module.exports = async function(deployer, network, accounts) {
  const hour = 3600;
  const startTime = parseInt(new Date().getTime() / 1000) + 600; // now + 10 minute
  const endTime = startTime + hour;
  const buyRate = 1;
  const rewardWallet = accounts[0];
  const liquidityPercent = 20;

  await deployer.deploy(WhiteList);
  await deployer.deploy(Multisig);
  const cs = await deployer.deploy(Crodwsale, startTime, endTime, WhiteList.address, buyRate, Multisig.address, rewardWallet, liquidityPercent);
  await deployer.deploy(Token, Crodwsale.address);

  await factoryContract.methods.createExchange(Token.address).send({from: accounts[0]});
  const exchangeAddress = await factoryContract.methods.getExchange(Token.address).call();
  await deployer.deploy(Uniswapper, Token.address, exchangeAddress, buyRate);

  await cs.setTokenContractAddress(Token.address);
  await cs.setUniswapperAddress(Uniswapper.address);

  console.log("WhiteList: ", WhiteList.address);
  console.log("Multisig: ", Multisig.address);
  console.log("Token: ", Token.address);
  console.log("Crodwsale: ", Crodwsale.address);
  console.log("Uniswapper: ", Uniswapper.address);
  console.log("Exchange: ", exchangeAddress);
};
