const { ethers } = require('hardhat');

// Compound Base_Goerli Addresses
const usdcAddress = '0x31D3A7711a74b4Ec970F50c3eaf1ee47ba803A95'
const wethAddress = '0x4200000000000000000000000000000000000006'
const compAddress = '0x7c6b91D9Be155A6Db01f749217d76fF02A7227F2'
const cometAddress = '0xAC9fC1a9532BC92a9f33eD4c6Ce4A7a54930F376'
const compRewardsAddress = '0x0818165C053D325985d87F4b8646b3062C72C385'
const implementationAddress = '0x21aFad2CE08707218fE9e7AdBE618D55706e6825'

//deployedFlashLoanContractAddr = '0xff8b1487a541ED673880de0CFaB4bcd8ec023977'

let YieldFarmContractDeploy = {

    /** 
     * @dev Deploy the Flash loan contract.
     * This is the Flash loan contract and must be implemented first. 
     * Simply deploys the flash loan contract from Aave v3.
     * 
     * Requirements:
     * 
     */
    deploy: async function deployYieldFarmContract() {
        let deployer, yieldFarmContract
        [deployer,] = await ethers.getSigners()

        let YieldFarmContract = await ethers.getContractFactory(
            'YieldFarmCompoundV3', deployer
        )
        
        yieldFarmContract = await YieldFarmContract.deploy(
            cometAddress, compRewardsAddress, usdcAddress, compAddress,
            wethAddress,implementationAddress
        )
        await yieldFarmContract.deployed()
        console.log(yieldFarmContract.address)
        return yieldFarmContract
    }
}

let YieldFarm = {

    /** 
     * @dev Transfer funds (USDC).
     * Ensure approval of spending of funds is first done.
     * Call the doTransfer function from smart contract to transfer funds.
     * 
     * Requirements:
     * Should transfer successfully if, amount is less or equal to allowance.
     * 
     */
    fundsTransfer: async function allowTf(yieldFarmContractAddress) {
        let deployer_, yieldFarmContract
        [deployer_,] = await ethers.getSigners()
        let amount = ethers.utils.parseUnits('0.0000001', 'gwei')

        let YieldFarmContract = await ethers.getContractFactory(
            'YieldFarmCompoundV3'
        )
        yieldFarmContract = YieldFarmContract.attach(yieldFarmContractAddress)

        let transfer_ = await yieldFarmContract.connect(deployer_).functions.doTransfer(
            amount, {
                gasLimit: 1000000,
                gasPrice: Number(ethers.utils.parseUnits('2', 'gwei')),
                from: deployer_.address
            }
        )
        console.log(await transfer_.wait())
    },

    /** 
     * @dev Approve amount of funds to be transferred (USDC).
     * Ensure approval of spending of funds is done using only ethers.js, not, solidity.
     * Call the doTransfer function from smart contract to transfer funds.
     * 
     * Requirements:
     * Should transfer successfully if, amount is less or equal to allowance.
     * 
     */
    approveTransfer: async function allowTf(
        ProxyContractAddress, YieldFarmContractAddress
    ) {
        let deployer_, proxyContract, yieldFarmContract, usdcContract
        [deployer_,] = await ethers.getSigners()
        let approveAmount = ethers.utils.parseEther('1')
        let amount = ethers.utils.parseUnits('0.00001', 'gwei')

        let USDCContract = await ethers.getContractFactory('FiatTokenV2_1')
        let YieldFarmContract = await ethers.getContractFactory(
            'YieldFarmCompoundV3'
        )
        
        usdcContract = USDCContract.attach(ProxyContractAddress)
        yieldFarmContract = YieldFarmContract.attach(YieldFarmContractAddress)

        let approveTx = usdcContract.functions.approve(
            YieldFarmContractAddress, approveAmount
        )
        let approvalData = (await approveTx).data
        console.log((await approvalData))
        let approveTxObject = {
            gasLimit: 1000000,
            gasPrice: Number(ethers.utils.parseUnits('2', 'gwei')),
            from: deployer_.address,
            to: ProxyContractAddress,
            data: approvalData,
            nonce: deployer_.getTransactionCount()
        }

        let tx = await deployer_.sendTransaction(approveTxObject)

        console.log(await tx.wait())

    }
}

Main = async() => {
    // Deploy FlashLoan Contract.
    //await YieldFarmContractDeploy.deploy()

    // Perform the actual Flash Loan on Aave v3 Fantom using DAI as loaned token
    //await YieldFarm.approveTransfer('0x31D3A7711a74b4Ec970F50c3eaf1ee47ba803A95','0xff8b1487a541ED673880de0CFaB4bcd8ec023977')
    await YieldFarm.fundsTransfer('0xff8b1487a541ED673880de0CFaB4bcd8ec023977')
}

Main()