// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import 'hardhat/console.sol';
import '@aave/core-v3/contracts/flashloan/base/FlashLoanSimpleReceiverBase.sol';
import '@aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

/**
  * @author Lasborne
  * @notice Perform flashloans using Aave V3.
  * @dev The contract is FlashLoanSimpleReceiverBase from Aave to perform flash loans.
  */
contract FlashLoan is FlashLoanSimpleReceiverBase{
    using SafeMath for uint256;

    address owner;
    IERC20 public borrowedToken;

    constructor(address _flashLoanPool, address _borrowedToken)
      FlashLoanSimpleReceiverBase(IPoolAddressesProvider(_flashLoanPool))
    {
      owner = msg.sender;
      borrowedToken = IERC20(_borrowedToken);
    }

    /**
     * @notice Perform flash loan.
     * @param amount the amount of tokens to be loaned from Aave V3.
     * @dev Calls the FlashLoanSimple function from IPool to take the loan.
     */
    function flashLoan(uint256 amount) external {
        require(msg.sender == owner, "This function can be called by only the owner");
        // Flash Loan data
        address receiverAddress = address(this);
        address[] memory assets = new address[](1);
        assets[0] = address(borrowedToken);
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = amount;
        uint256[] memory modes = new uint256[](1);
        modes[0] = 0; // 0 means no debt swap

        //This is where the flash loan is performed
        POOL.flashLoanSimple(
          receiverAddress,
          assets[0],
          amounts[0],
          "0x",
          uint16(modes[0])
        );
        console.log('Flash Loan obtained');
    }

    /**
     * @notice Input all operations for the flash loan and approve payback.
     * @param asset the address of the borrowed token.
     * @param amount the amount of tokens to be loaned from Aave V3.
     * @param premium the small fee Aave charges for flash loans.
     * @param initiator the address of this contract to do the flash loan.
     * @param params bytes data input into the transaction.
     * @dev Code in the operations of what to do with the borrowed funds.
     * @dev Approve the total= amount + premium for Aave V3 to retrieve its
     * @dev loaned funds and interest all in one transaction, else, transaction
     * @dev rolls back.
     */
    function executeOperation(
      address asset, uint256 amount, uint256 premium, address initiator,
      bytes calldata params
    ) external returns (bool) {
      // Logic for using the Flash loaned amount is put in here.

      // Approval of the total amount so that Aave V3 can take back the loan.
      uint256 totalAmount = amount.add(premium);
      IERC20(asset).approve(address(POOL), totalAmount);
      return true;
    }

    /**
     * @notice Withdraw ERC-20 funds left in this contract address.
     * @dev Withdraw funds, by only the contract's owner, using the balanceOf function.
     */
    function withdrawFunds() external {
      require(msg.sender == owner, "Only the Owner can withdraw funds");
      uint256 balance = borrowedToken.balanceOf(address(this));
      borrowedToken.transfer(owner, balance);
    }

    /**
     * @notice Allow this contract to receive native currency i.e. ETHER.
     * @dev Special fall back function in the EVM that tells a contract address
     * @dev to support native currency receiving.
     */
    receive() external payable {}
}