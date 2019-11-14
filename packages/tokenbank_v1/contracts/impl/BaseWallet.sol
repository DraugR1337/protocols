

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

import "../iface/Wallet.sol";
import "../iface/Module.sol";

import "../lib/NamedAddressSet.sol";


contract BaseWallet is Wallet, NamedAddressSet
{
    string private constant MODULE = "__MODULE__";

    mapping (bytes4  => address) internal methods;

    event Received(
        address indexed sender,
        uint    value,
        bytes   data
    );

    modifier onlyOwner
    {
        require(msg.sender == owner, "NOT_A_OWNER");
        _;
    }

    modifier onlyModule
    {
        require(isAddressInSet(MODULE, msg.sender), "NOT_A_MODULE");
        _;
    }

    function init(
        address            _owner,
        address[] calldata _modules
        )
        external
        // nonReentry
    {
        require(owner == address(0) && numAddressesInSet(MODULE) == 0, "INITIALIZED_ALREADY");
        require(_owner != address(0), "ZERO_ADDRESS");
        require(_modules.length > 0, "EMPTY_MODULES");

        owner = _owner;
        emit Initialized(owner);

        for(uint i = 0; i < _modules.length; i++) {
            address module = _modules[i];
            require(module != address(0), "NULL_MODULE");
            addAddressToSet(MODULE, module);
            Module(module).init(address(this));
            emit ModuleAdded(module);
        }


    }

    function addModule(address _module)
        external
        onlyModule
    {
        require(_module != address(0), "NULL_MODULE");
        addAddressToSet(MODULE, _module);
        Module(_module).init(address(this));
        emit ModuleAdded(_module);
    }

    function removeModule(address _module)
        external
        onlyModule
    {
        require(numAddressesInSet(MODULE) > 1, "PROHIBITED");
        removeAddressFromSet(MODULE, _module);
        emit ModuleRemoved(_module);
    }

    function getModules()
        public
        view
        returns (address[] memory)
    {
        return getAddressesInSet(MODULE);
    }

    function bindMethod(bytes4 _method, address _module)
        external
        onlyModule
    {
        methods[_method] = _module;
        emit MethodBinded(_method, _module);
    }

    function getMethodModule(bytes4 _method)
        public
        view
        returns (address)
    {
        return methods[_method];
    }

    function transact(
        address _to,
        uint    _value,
        bytes   calldata _data
        )
        external
        onlyModule
        returns (bytes memory _result)
    {
        bool success;
        // solium-disable-next-line security/no-call-value
        (success, _result) = _to.call.value(_value)(_data);
        if(!success) {
            assembly {
                returndatacopy(0, 0, returndatasize)
                revert(0, returndatasize)
            }
        }
        emit Transacted(msg.sender, _to, _value, _data);
    }

    function() external payable
    {
        address module = msg.data.length == 0 ? address(0) : methods[msg.sig];

        if(module == address(0)) {
            if (msg.value > 0) {
                emit Received(msg.sender, msg.value, msg.data);
            }
            return;
        }

        require(isAddressInSet(MODULE, module), "MODULE_UNAUTHORIZED");
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := staticcall(gas, module, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 {revert(0, returndatasize())}
            default {return (0, returndatasize())}
        }
    }
}