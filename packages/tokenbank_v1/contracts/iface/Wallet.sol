

/*

  Copyright 2017 Loopring Project Ltd (Loopring Foundation).

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
pragma solidity ^0.5.11;


contract Wallet
{
    address public owner;

    event ModuleAdded   (address indexed module);
    event ModuleRemoved (address indexed module);
    event MethodBinded  (bytes4  indexed method, address indexed module);

    event Transacted(
        address indexed module,
        address indexed to,
        uint            value,
        bytes           data
    );

    function init(address _owner, address[] calldata _modules) external;

    function addModule(address _module) external;
    function removeModule(address _module) external;
    function getModules() public view returns (address[] memory);

    function bindMethod(bytes4 _method, address _module) external;
    function getMethodModule(bytes4 _method) public view returns (address);

    function transact(
        address _to,
        uint    _value,
        bytes   calldata _data
        )
        external
        returns (bytes memory);
}