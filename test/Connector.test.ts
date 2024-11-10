import { SignerWithAddress } from '@nomicfoundation/hardhat-ethers/signers'
import { loadFixture } from '@nomicfoundation/hardhat-toolbox/network-helpers'
import { ethers } from 'hardhat'
import {
  IERC20,
  INonfungiblePositionManager,
  IUniswapV3Factory,
  IUniswapV3Pool,
  UniswapV3Connector,
  UniswapV3Connector__factory,
} from '../typechain-types'
import { deployDefaultFixture } from './index'
import { ADDRESSES } from './helper'

describe('UniswapV3Connector', function () {
  let deployer: SignerWithAddress
  let user0: SignerWithAddress
  let user1: SignerWithAddress
  let uniswapConnectorFactory: UniswapV3Connector__factory
  let connector: UniswapV3Connector
  let pool: IUniswapV3Pool
  let router: INonfungiblePositionManager
  let factory: IUniswapV3Factory
  let btcb: IERC20
  let usdt: IERC20
  let fee = 5_00n // 0.05%

  beforeEach(async () => {
    const state = await loadFixture(deployDefaultFixture)

    deployer = state.signers[0]
    user0 = state.signers[1]
    user1 = state.signers[2]

    uniswapConnectorFactory = state.uniswapConnectorFactory
    connector = state.connector

    factory = await ethers.getContractAt('IUniswapV3Factory', ADDRESSES.uniV3Factory)
    router = await ethers.getContractAt(
      'INonfungiblePositionManager',
      ADDRESSES.uniV3PositionManager
    )

    btcb = await ethers.getContractAt('IERC20', ADDRESSES.btcb)
    usdt = await ethers.getContractAt('IERC20', ADDRESSES.usdt)

    const pool = await ethers.getContractAt(
      'IUniswapV3Pool',
      await factory.getPool(btcb.target, usdt.target, fee)
    )

    console.log(pool.target)
  })

  it('constructor', async () => {})
})
