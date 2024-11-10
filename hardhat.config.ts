import { HardhatUserConfig } from 'hardhat/config'
import '@nomicfoundation/hardhat-toolbox'
import 'hardhat-contract-sizer'
import 'hardhat-gas-reporter'
import 'solidity-coverage'
import '@typechain/hardhat'
import '@nomicfoundation/hardhat-network-helpers'
import '@nomicfoundation/hardhat-ethers'
import 'hardhat-deploy'
import 'hardhat-deploy-ethers'

import dotenv from 'dotenv'
dotenv.config()

const config: HardhatUserConfig = {
  solidity: {
    compilers: [
      {
        version: '0.8.27',
      },
    ],
  },
  networks: {
    hardhat: {
      tags: ['localhost'],
      deploy: ['deploy/localhost/'],
      forking: {
        url: process.env.RPC_BSC_MAIN || 'NO RPC',
      },
    },
    bsc_testnet: {
      tags: ['localhost'],
      deploy: ['deploy/localhost/'],
      url: process.env.RPC_BSC_TEST || 'NO RPC',
      accounts: process.env.PRIVATE_TEST?.split(',') || [],
    },
  },
  etherscan: {
    apiKey: {
      bsc_testnet: process.env.API_BSC || 'NO API KEY',
    },
  },
  gasReporter: {
    enabled: true,
    currency: 'USD',
  },
  contractSizer: {
    alphaSort: true,
    disambiguatePaths: false,
    runOnCompile: true,
  },
}

export default config
