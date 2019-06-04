const WhiteList = artifacts.require("Whitelist");
const Multisig = artifacts.require("MultiSig");
const Crodwsale = artifacts.require("TokennCrowdsale");
const Token = artifacts.require("TokennToken");
const Uniswapper = artifacts.require("Uniswapper");
const TAA = artifacts.require("TeamAndAdvisorsAllocation");

const FACTORY_ADDRESS = "0xf5D915570BC477f9B8D6C0E980aA81757A3AaC36";
const FACTORY_ABI = [{"name":"NewExchange","inputs":[{"type":"address","name":"token","indexed":true},{"type":"address","name":"exchange","indexed":true}],"anonymous":false,"type":"event"},{"name":"initializeFactory","outputs":[],"inputs":[{"type":"address","name":"template"}],"constant":false,"payable":false,"type":"function","gas":35725},{"name":"createExchange","outputs":[{"type":"address","name":"out"}],"inputs":[{"type":"address","name":"token"}],"constant":false,"payable":false,"type":"function","gas":187911},{"name":"getExchange","outputs":[{"type":"address","name":"out"}],"inputs":[{"type":"address","name":"token"}],"constant":true,"payable":false,"type":"function","gas":715},{"name":"getToken","outputs":[{"type":"address","name":"out"}],"inputs":[{"type":"address","name":"exchange"}],"constant":true,"payable":false,"type":"function","gas":745},{"name":"getTokenWithId","outputs":[{"type":"address","name":"out"}],"inputs":[{"type":"uint256","name":"token_id"}],"constant":true,"payable":false,"type":"function","gas":736},{"name":"exchangeTemplate","outputs":[{"type":"address","name":"out"}],"inputs":[],"constant":true,"payable":false,"type":"function","gas":633},{"name":"tokenCount","outputs":[{"type":"uint256","name":"out"}],"inputs":[],"constant":true,"payable":false,"type":"function","gas":663}];
const factoryContract = new web3.eth.Contract(FACTORY_ABI, FACTORY_ADDRESS);

module.exports = async function(deployer, network, accounts) {
  // const hour = 3600;
  // const startTime = parseInt(new Date().getTime() / 1000) + hour; // now + 1 hour for presale
  // const endTime = startTime + hour;
  // const buyRate = 1;
  // const rewardWallet = "0x123be8890f375398d17137da322d2154c07259a2";
  // const nonVestedWallet = "0x434ae4f0353ddfe55ca98e88fde13b6c1f92fd2d";
  //
  // const liquidityPercent = 20;
  //
  // await deployer.deploy(WhiteList);
  // await deployer.deploy(Multisig);
  // const cs = await deployer.deploy(Crodwsale, startTime, endTime,
  //     WhiteList.address, buyRate, Multisig.address, rewardWallet, nonVestedWallet, liquidityPercent);
  // await deployer.deploy(Token, Crodwsale.address);
  // await deployer.deploy(TAA, Token.address);
  // await factoryContract.methods.createExchange(Token.address).send({from: accounts[0]});
  // const exchangeAddress = await factoryContract.methods.getExchange(Token.address).call();
  // await deployer.deploy(Uniswapper, Token.address, exchangeAddress, buyRate);
  //
  // await cs.setTokenContractAddress(Token.address);
  // await cs.setUniswapperAddress(Uniswapper.address);
  // await cs.setTeamWalletAddress(TAA.address);
  //
  // console.log("WhiteList: ", WhiteList.address);
  // console.log("Multisig: ", Multisig.address);
  // console.log("Token: ", Token.address);
  // console.log("Crodwsale: ", Crodwsale.address);
  // console.log("Uniswapper: ", Uniswapper.address);
  // console.log("TeamAndAdvisors: ", TAA.address);
  // console.log("Exchange: ", exchangeAddress);
};
