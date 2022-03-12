/**
 * https://www.youtube.com/watch?v=uFdjZ-B3GCM
 * Inside Ethereum Transactions · Web3.js ·
 * Ethereum Blockchain Development Crash Course
 * #3 Transactions on the ETH network
 */

var Tx = require('ethereumjs-tx');
const Web3 = require('web3');
const url = 'https://rinkeby.infura.io/v3/082639b1acca463aa008842fe39bf748';
const web3 = new Web3(url);

// metamask account on rinkeby
var account1 = '0xEAd512784C92797Fdc037Ee8135FfFfD0f01C250';
var privateKey1 = Buffer.from('45282e83fbf6e56396f634c20417bd5d3f5a715355d1b49b513c05bf4875b3e6', 'hex');
// bitbox address on rinkeby
var account2 = '0x3CeD54309C06E0830607F8565B56C443708363d8';

// let us get the latest tranaction number and then let us build the transaction
web3.eth.getTransactionCount(account1, (err, txCount) => {
    const txObject = {
      nonce: web3.utils.toHex(txCount),
      to: account2,
      value: web3.utils.toHex(web3.utils.toWei('0.01', 'ether')),
      gasLimit: web3.utils.toHex(21000),
      gasPrice: web3.utils.toHex(web3.utils.toWei('10', 'gwei'))
    };

    // sign the transaction
    const tx = new Tx(txObject);
    tx.sign(privateKey1);
    const serializedTransaction = tx.serialize();
    const raw = '0x'+ serializedTransaction.toString('hex');

    // broadcast the transaction
    web3.eth.sendSignedTransaction(raw, (err, txHash) => {
        if (err){
           console.log("err:", err);
        } else {
            console.log("txHash:", txHash);
        }
    });

    /**
     * get the balance of accounts
     */
    web3.eth.getBalance(account1, (err, result) => {
        console.log('Account 1:', web3.utils.fromWei(result, 'ether'));
    });
    web3.eth.getBalance(account2, (err, result) => {
        console.log('Account 2:', web3.utils.fromWei(result, 'ether'));
    });

});
