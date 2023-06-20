import { HardhatUserConfig, task } from 'hardhat/config'
import '@nomicfoundation/hardhat-toolbox'
import '@nomiclabs/hardhat-web3'
import '@nomiclabs/hardhat-ethers'
import dotenv from 'dotenv'

dotenv.config()

const ALCHEMY_MUMBAI_API_KEY = process.env.ALCHEMY_MUMBAI_API_KEY ? process.env.ALCHEMY_MUMBAI_API_KEY : '';
const ALCHEMY_SEPOLIA_API_KEY = process.env.ALCHEMY_SEPOLIA_API_KEY ?  process.env.ALCHEMY_SEPOLIA_API_KEY : "";
const PRIVATE_KEY = process.env.PRIVATE_KEY ? process.env.PRIVATE_KEY : "";

const config: HardhatUserConfig = {
  solidity: "0.8.18",
  defaultNetwork: "local",
  networks: {
    mumbai:{
      url: `https://polygon-mumbai.g.alchemy.com/v2/${ALCHEMY_MUMBAI_API_KEY}`,
      chainId: 80001,
      accounts: [PRIVATE_KEY],
    },
    local: {
      url: "http://127.0.0.1:8545",
    },
    sepolia:{
      url: `https://eth-sepolia.g.alchemy.com/v2/${ALCHEMY_SEPOLIA_API_KEY}`,
      chainId: 11155111,
      accounts: [PRIVATE_KEY],
    },
    bscMainnet:{
      url: `https://bsc-dataseed.binance.org/`,
      chainId: 56,
      accounts: [PRIVATE_KEY],
    },
    bscTestnet:{
      url: `https://data-seed-prebsc-1-s1.binance.org:8545/`,
      chainId: 97,
      accounts: [PRIVATE_KEY],
    },
  }
};

task('address', 'Convert mnemonic to address')
  .addParam('mnemonic', "The account's mnemonic")
  .setAction(async (taskArgs, hre) => {
    const something = hre.ethers.Wallet.fromMnemonic(taskArgs.mnemonic)
    console.log(something.address)
  })

task('balance', "Prints an account's balance")
  .addParam('account', "The account's address")
  .setAction(async (taskArgs, hre) => {
    const account = hre.web3.utils.toChecksumAddress(taskArgs.account)
    const balance = await hre.web3.eth.getBalance(account)
    console.log(hre.web3.utils.fromWei(balance, 'ether'), 'KLAY')
  })

task('deploy', 'Deploy SBT')
  .addParam('name', 'SBT name')
  .addParam('symbol', 'SBT symbol')
  .addParam('baseUri', 'URI (must end with /) that will be used as prefix when returning tokenURI')
  .setAction(async (args, hre) => {
    const sbtContract = await hre.ethers.getContractFactory('SBT')
    const sbt = await sbtContract.deploy(args.name, args.symbol, args.baseUri)
    await sbt.deployed()
    console.log(
      `SBT was deployed to ${hre.network.name} network and can be interacted with at address ${sbt.address}`
    )
  })

task('mint', 'Mint SBT')
  .addParam('address', 'Address of deployed SBT')
  .addParam('to', 'Address receiving SBT token')
  .addParam('tokenId', 'ID of SBT token that is being minted')
  .setAction(async (args, hre) => {
    const sbt = await hre.ethers.getContractAt('SBT', args.address)
    const [owner] = await hre.ethers.getSigners()
    const tx = await (await sbt.safeMint(args.to, args.tokenId)).wait()
    console.log(tx)
    console.log(`SBT with tokenId ${args.tokenId} was minted for address ${args.to}`)
  })

export default config
