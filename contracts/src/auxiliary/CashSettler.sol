pragma solidity >=0.4.21 <0.6.0;

import "../../lib/openzeppelin-solidity/ERC20.sol";
import "../../lib/flash-lending/FlashLender.sol";
import "../../lib/flash-lending/interface/IArbitrage.sol";
import "../../lib/uniswap/UniSwapExchangeIF.sol";
import "../parent_contracts/OptionCommon.sol";

contract CashSettler is IArbitrage {
  address public base_addr;
  address public asset_addr;
  address public owner;
  address public option_addr;
  address public flash_lender_addr;
  address public base_exchange_addr;
  address public asset_exchange_addr;

  ERC20 public base;
  ERC20 public asset;
  OptionCommon public option;
  FlashLender public flash_lender;
  UniSwapExchangeIF public base_exchange;
  UniSwapExchangeIF public asset_exchange;

  // Temporary variables
  bool eth_payout;
  bool is_silent;
  uint256 strike_price_base;
  uint256 strike_price_quote;
  bytes32 salt;

  constructor(address _base_addr, address _asset_addr, address _owner,
              address _option_addr,
              address _flash_lender_addr,
              address _base_exchange_addr, address _asset_exchange_addr) public {
    reinit(_base_addr, _asset_addr, _owner,
            _option_addr,
            _flash_lender_addr,
            _base_exchange_addr, _asset_exchange_addr);
  }

  // Reinitialize the CashSettler (for reuse)
  function reinit(address _base_addr, address _asset_addr, address _owner,
                  address _option_addr,
                  address _flash_lender_addr,
                  address _base_exchange_addr, address _asset_exchange_addr) public {
    require(owner == address(0x0) || msg.sender == owner);
    base_addr = _base_addr;
    asset_addr = _asset_addr;
    owner = _owner;
    option_addr = _option_addr;
    flash_lender_addr = _flash_lender_addr;
    base_exchange_addr = _base_exchange_addr;
    asset_exchange_addr = _asset_exchange_addr;

    base = ERC20(_base_addr);
    asset = ERC20(_asset_addr);
    option = OptionCommon(option_addr);
    flash_lender = FlashLender(_flash_lender_addr);
    base_exchange = UniSwapExchangeIF(_base_exchange_addr);
    asset_exchange = UniSwapExchangeIF(_asset_exchange_addr);
  }

  // Functions for arbitrage on standard and silent options
  function option_arbitrage(uint256 amount, bool _eth_payout) public {
    eth_payout = _eth_payout;
    is_silent = false;
    flash_lender.borrow(address(0x0), amount, owner, bytes(""));
  }

  function silent_option_arbitrage(uint256 amount, bool _eth_payout,
                                    uint256 _strike_price_base, uint256 _strike_price_quote,
                                    bytes32 _salt) public {
    eth_payout = _eth_payout;
    is_silent = true;
    strike_price_base = _strike_price_base;
    strike_price_quote = _strike_price_quote;
    salt = _salt;
    flash_lender.borrow(address(0x0), amount, owner, bytes(""));
  }

  // Callback for FlashLender
  // Token is always ETH (0x0)
  // Pays out in ETH if eth_payout, else asset
  function executeArbitrage(address token, uint256 amount, address dest,
                            bytes calldata data) external returns (bool) {
    require(msg.sender == flash_lender_addr);
    // Exchange token for base currency
    uint256 base_bought = base_exchange.ethToTokenSwapInput.value(amount)(1, block.timestamp);
    // Approve the option for base
    base.approve(option_addr, base_bought);
    // Exercise the option
    uint256 asset_bought;
    if (is_silent) {
      asset_bought = option.exercise_from_base(strike_price_base, strike_price_quote, salt, base_bought);
    } else {
      asset_bought = option.exercise_from_base(base_bought);
    }
    // Exchange asset currency for token
    // Return amount + fee to flash_lender
    asset.approve(asset_exchange_addr, asset_bought);
    uint256 fee = flash_lender.fee();
    uint256 asset_sold = asset_exchange.tokenToEthTransferOutput(amount + fee, asset_bought,
                                                                  block.timestamp, flash_lender_addr);
    if (eth_payout) {
      asset_exchange.tokenToEthTransferInput(asset_bought - asset_sold, 1, block.timestamp, owner);
    } else {
      asset.transfer(owner, asset_bought - asset_sold);
    }
    return true;
  }

  // Return option's buyer status to owner
  function transfer_option() public {
    require(msg.sender == owner);
    option.transfer_buyer(owner);
  }
}
