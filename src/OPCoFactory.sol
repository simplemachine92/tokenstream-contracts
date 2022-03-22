// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.10;

import "../lib/openzeppelin-contracts/contracts/access/AccessControl.sol";

error InvalidRole();

/**
OpCoFactory is responsible for managing the OpCo's.
 */
contract OpCoFactory is AccessControl {
  // bytes32 public constant OP_ROLE = keccak256("OP_ROLE");
  // bytes32 public constant OPCO_ROLE = keccak256("OPCO_ROLE");
  // bytes32 public constant BADGE_HOLDER_ROLE = keccak256("BADGE_HOLDER_ROLE");
  // Badge public badge; 
  constructor() {
    // // Grant the contract deployer the default admin role: it will be able
    // // to grant and revoke any roles
    // _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    // // Set the deployer to the OP ROLE for now
    // _setupRole(OP_ROLE, msg.sender);
    // // Set the deployer to the OPCo ROLE for now
    // _setupRole(OPCO_ROLE, msg.sender);

  }

  mapping(address => bytes32) public OpCoMap;

  // Set an OpCo
  function newOpCo(
    address _account
  ) public returns (bool) {
    // hmm
    return true;
  }

  function setOpCoBadgeMinters(address _account, bytes32 _root)
    public
    returns (bool)
  {
    OpCoMap[_account] = _root;
    return true;
  }
}
