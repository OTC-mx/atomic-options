// Modified from Marble: https://github.com/marbleprotocol/flash-lending
/*
  Copyright 2018 Contra Labs Inc.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
  http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity >=0.4.21 <0.6.0;


interface IBank {
    function totalSupplyOf(address token) external view returns (uint256 balance);
    function borrowFor(address token, address borrower, uint256 amount) external;
    function repay(address token, uint256 amount) external payable;
}
