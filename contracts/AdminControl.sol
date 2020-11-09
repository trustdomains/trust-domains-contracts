// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2 <0.7.0;

import "@openzeppelin/contracts/access/Ownable.sol";
//import "@openzeppelin/contracts/access/AccessControl.sol";


import "./utils/Roles.sol";



contract AdminControl is Ownable {

    using Roles for Roles.Role;

    Roles.Role private _controllerRoles;


    modifier onlyMinterController() {
      require (
        hasRole(msg.sender), 
        "AdminControl: sender must has minting role"
      );
      _;
    }

    modifier onlyMinter() {
      require (
        hasRole(msg.sender), 
        "AdminControl: sender must has minting role"
      );
      _;
    }

    constructor() public {
      _grantRole(msg.sender);
    }

    function grantMinterRole (address account) public  onlyOwner {
      _grantRole(account);
    }

    function revokeMinterRole (address account) public  onlyOwner {
      _revokeRole(account);
    }

    function hasRole(address account) public view returns (bool) {
      return _controllerRoles.has(account);
    }
    
    function _grantRole (address account) internal {
      _controllerRoles.add(account);
    }

    function _revokeRole (address account) internal {
      _controllerRoles.remove(account);
    }

}
