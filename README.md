# Flash Loan Contract

This is a basic Flash Loan Project deployed on the Fantom mainnet. It borrows any specified amount of a valid ERC-20 token from Aave V3 Pool utilizing the PoolAddressesProvider, and a script that deploys the contract and contains functions for loan, borrow, other logic etc. This flash loan can be used for various DeFi operations such as Arbitrage, DeFi liquidations etc. This flash loan must be paid in the same transaction as well as operations, else the entire transaction rolls back. This is known as the atomicity property i.e. either all transaction must work within same transaction or the entire transaction bundle fails.

daiFantomAddress = '0x8D11eC38a3EB5E956B052f67Da8Bdc9bef8Abf3E', aaveFlashLoanPoolAddressesProvider (on Fantom mainnet) = '0xa97684ead0e402dC232d5A977953DF7ECBaB3CDb' flashLoanContractAddress (created) = '0x2c1cFaC977A00d607c37508486A9b1374A6B6939'.

Try running some of the following tasks:

npx hardhat help 
npx hardhat node 
npx hardhat run scripts/flashLoan.js --network fantom 
Special credits to Gregory @DappUniversity, AAVE V3 docs.
