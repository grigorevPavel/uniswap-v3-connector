import { deployContract } from '@nomicfoundation/hardhat-ethers/types'
import { ethers } from 'hardhat'
import type { DeployFunction } from 'hardhat-deploy/types'
import { HardhatRuntimeEnvironment } from 'hardhat/types'

const func: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
    const {deployments} = hre
    const {deploy} = deployments
    const [deployer] = await ethers.getSigners()

    // await deploy("Lock", {
    //     from: deployer.address,
    //     args: [10n ** 10n],
    //     log: true
    // })
}
export default func

func.tags = ['Token.deploy']
