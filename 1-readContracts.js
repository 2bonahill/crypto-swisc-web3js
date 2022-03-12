var Web3 = require('web3');

// main ethereum network
var url = 'https://rinkeby.infura.io/v3/082639b1acca463aa008842fe39bf748';

var web3 = new Web3(url);

// abi and address of SWISC token
var rinkebyAddresses = require('./resources/rinkeby.json');
var tokenABI = require('./resources/SWISCTokenABI.json');
var crowdSaleABI = require('./resources/SWISCCrowdSaleABI.json');
var tokenContractAddress = rinkebyAddresses.SWISCTokenContractAddress;
var crowdSaleContractAddress = rinkebyAddresses.SWISCCrowdSaleContractAddress;
var bitboxAddress = rinkebyAddresses.bitboxAddress;
var metamaskAddress = rinkebyAddresses.metamaskAddress;
var trezorAddress = rinkebyAddresses.trezorAddress;
var cryptoBrokerWalletAddress = rinkebyAddresses.CryptoBrokerWalletAddress;

// instanstiate the contracts
var tokenContract = new web3.eth.Contract (tokenABI, tokenContractAddress);
var crowdSaleContract = new web3.eth.Contract (crowdSaleABI, crowdSaleContractAddress);

/*
* get some information about the SWISC contracts
*/
asynchRead();
async function asynchRead(){
  console.log("\nSWISC Crowd Sale Contract");
  console.log("=========================");
  await crowdSaleContract.methods.chfTokenRate().call((err,result) => {console.log("- chfTokenRate:", result)});
  await crowdSaleContract.methods.hasClosed().call((err,result) => {console.log("- hasClosed:", result)});
  await crowdSaleContract.methods.isFinalized().call((err,result) => {console.log("- isFinalized:", result)});
  var currentPriceIndex = await crowdSaleContract.methods.currentPriceIndex().call();
  await crowdSaleContract.methods.tokenPriceIndex(currentPriceIndex).call((err,result) => {console.log("- SwiscPerEtherRate:", result)});
  await crowdSaleContract.methods.cap().call((err,result) => {console.log("- cap:", result)});
  await crowdSaleContract.methods.weiRaised().call((err,result) => {console.log("- weiRaised:", result)});
  await crowdSaleContract.methods.openingTime().call((err,result) => {console.log("- openingTime:", new Date(result*1000).toString())});
  await crowdSaleContract.methods.closingTime().call((err,result) => {console.log("- closingTime:", new Date(result*1000).toString())});
  await crowdSaleContract.methods.min_contribution_chf().call((err,result) => {console.log("- min_contribution_chf:", result)});
  await crowdSaleContract.methods.tokensMinted().call((err,result) => {console.log("- tokensMinted:", result)});
  await crowdSaleContract.methods.capReached().call((err,result) => {console.log("- capReached:", result)});
  await web3.eth.getBalance(cryptoBrokerWalletAddress, (err, bal) => {console.log("- Contract wallet (future crypto broker) balance in ETH:", web3.utils.fromWei(bal, 'ether'));})

  console.log("\nSWISC Token Contract");
  console.log("====================");
  await tokenContract.methods.name().call((err,result) => {console.log("- Name:", result)});
  await tokenContract.methods.symbol().call((err,result) => {console.log("- Symbol:", result)});
  await tokenContract.methods.totalSupply().call((err,result) => {console.log("- Total supply:", result)});
  await tokenContract.methods.mintingFinished().call((err,result) => {console.log("- Minting finished:", result)});
  await tokenContract.methods.balanceOf(bitboxAddress).call((err,result) => {console.log("- Bitbox account balance in SWISC (" + bitboxAddress + "):", web3.utils.fromWei(result, 'ether'))});
  await tokenContract.methods.balanceOf(metamaskAddress).call((err,result) => {console.log("- Metamask account balance in SWISC (" + metamaskAddress + "):", web3.utils.fromWei(result, 'ether'))});
  await tokenContract.methods.balanceOf(trezorAddress).call((err,result) => {console.log("- TREZOR account balance in SWISC (" + trezorAddress + "):", web3.utils.fromWei(result, 'ether'))});
}
