// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import './CometMainInterface.sol';
import 'hardhat/console.sol';
import '@aave/core-v3/contracts/flashloan/base/FlashLoanSimpleReceiverBase.sol';
import '@aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {FiatTokenProxy} from './FiatTokenProxy.sol';
import {FiatTokenV2_1} from './FiatTokenV2_1.sol';

interface ICometRewards {
  function claim(address comet, address src, bool shouldAccrue) external view;
}

interface IAdminUpgradeabilityProxy {
  function implementation() external view returns (address);
}

/**
  * @author Lasborne
  * @notice Use FlashLoaned fund to farm yield in COMPOUND by supplying and borrowing.
  * @dev The contract is YieldFarm to farm COMP tokens using flash loan from Aave.
  */
contract YieldFarmCompoundV3 is FiatTokenProxy {
    using SafeMath for uint256;

    uint256 borrowAmount;
    uint256 amount;
    address owner;
    FiatTokenV2_1 public FiatToken;

    IERC20 public comp;
    IERC20 public weth;
    CometMainInterface public Comet;
    ICometRewards public cometRewards;
    FiatTokenProxy public borrowedToken;
    address public borrowedToken_;

    mapping(address => mapping(address => uint256)) internal _allowance;

    constructor(
      address _cometAddress, address _cometRewards, address _borrowedToken,
      address _comp, address _weth, address _implementationAddress
    ) FiatTokenProxy(_implementationAddress) {
      owner = msg.sender;
      Comet = CometMainInterface(_cometAddress);
      cometRewards = ICometRewards(_cometRewards);
      borrowedToken = FiatTokenProxy(payable(address(0x21aFad2CE08707218fE9e7AdBE618D55706e6825)));
      borrowedToken_ = _borrowedToken;
      comp = IERC20(_comp);
      weth = IERC20(_weth);
    }

    /**
     * @notice Function not yet in use.
     * @notice lend Flash loaned amount to Compound finance.
     * @param _amount the amount of tokens supplied.
     * @dev Approves the comet address to spend flashloaned fund.
     * @dev Calls the comet's supply function.
     */
    function lend(address _token, uint256 _amount) external {
      amount = _amount;
      doTransfer(amount);
      //borrowedToken.approve(address(Comet), _amount);
      (bool success, bytes memory result) = address(
        borrowedToken
      ).delegatecall(abi.encodeWithSignature(
        "approve(address, uint256)", address(Comet), _amount
      ));
      Comet.supply(address(borrowedToken), _amount);
    }

    /**
     * @notice Gets the amount of approved tokens to be spent by addresses.
     * @dev Proxy uses a call to get allowance function of the implementation contract.
     * @dev Returns allowance in uint256 if call is successful.
     */
    function getAllowance() internal returns (uint256) {
      (bool suc, bytes memory amountAllowed) = address(
        0x31D3A7711a74b4Ec970F50c3eaf1ee47ba803A95
      ).call(abi.encodeWithSignature(
        "allowance(address,address)", owner, address(this))
      );
      _allowance[owner][address(this)] = abi.decode(amountAllowed, (uint256));
      return _allowance[owner][address(this)];
    }

    /**
     * @notice Transfers an amount from the owner to this contract address.
     * @param _amount the amount to be transferred.
     * @dev First checks the allowance is atleast equal to the amount for transfer.
     * @dev Proxy uses a call to get transferFrom function of the implementation contract.
     * @dev Returns original result in bool if call is successful.
     */
    function doTransfer(uint256 _amount) public returns (
    bool) {
      require (getAllowance() >= _amount, "Inadequate approval amount!");
      (bool success2, bytes memory result2) = address(
        (0x31D3A7711a74b4Ec970F50c3eaf1ee47ba803A95)
      ).call(
        abi.encodeWithSignature(
          "transferFrom(address,address,uint256)", owner, address(this), _amount
      ));
      console.log(success2);
      return abi.decode(result2, (bool));
    }

    /**
     * @notice This function is not use yet.
     * @notice withdraw invested Flash loan funds and rewards given.
     * @dev Checks balance of this contract and withdraws all funds.
     * @dev Redeems rewards and funds from cTokens to regular tokens.
     */
    function withdrawAll() external {
      withdrawRewards();
      Comet.withdraw(address(borrowedToken), type(uint256).max);
    }

    /**
     * @notice This function is not in use yet.
     * @notice withdraw rewards given.
     * @dev Checks balance of this contract and withdraws COMP.
     * @dev Transfers Comp rewards to msg.sender
     */
    function withdrawRewards() internal {
      cometRewards.claim(address(Comet), address(this), false);
      uint256 balanceComp = comp.balanceOf(address(this));
      comp.transfer(msg.sender, balanceComp);
    }

    /**
     * @notice This function is not in use yet.
     * @notice borrow funds.
     * @dev Approves the cToken address for borrowing.
     * @dev Create an array containing cToken address.
     * @dev Enter the borrow market.
     */
    function borrow() external{
      borrowAmount = (amount.div(2));

      //borrowedToken.approve(address(cBorrowedToken), borrowAmount);

      // Signals to compound that a token lent will be used as a collateral.

      // Borrow 50% of the same collateral provided.
      
      Comet.withdraw(address(borrowedToken), borrowAmount);
    }

    /**
     * @notice This function is not in use yet.
     * @notice pay back borrowed funds.
     * @dev Approve the cToken address for repay with a higher amount.
     * @dev Repay borrowed amount and reset.
     * @dev Enter the borrow market.
     */
    function payback() external {
      //borrowedToken.approve(address(Comet), (type(uint256).max));
      (bool success3, bytes memory result3) = address(
        borrowedToken
      ).delegatecall(abi.encodeWithSignature(
        "approve(address, uint256)", address(Comet), type(uint256).max
      ));
      Comet.supply(
        address(borrowedToken), Comet.borrowBalanceOf(address(this))
      );
      // Reset borrow amount back to 0 after pay out is executed.
      borrowAmount = 0;
    }
}