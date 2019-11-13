pragma solidity >=0.4.21 <0.6.0;

contract UniSwapExchangeIF {
  function ethToTokenSwapInput(uint256 min_tokens, uint256 deadline) external payable returns (uint256);
  function tokenToEthTransferInput(uint256 tokens_sold, uint256 min_eth,
                                    uint256 deadline, address recipient) external returns (uint256);
  function tokenToEthTransferOutput(uint256 eth_bought, uint256 max_tokens,
                                    uint256 deadline, address recipient) external returns (uint256);
}
