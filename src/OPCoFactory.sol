// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "../lib/openzeppelin-contracts/contracts/access/AccessControl.sol";
// import "./Badge.sol";

/**
OPCoFactory is responsible for managing the OPCo's.
 */
contract OPCoFactory is AccessControl {
  bytes32 public constant OP_ROLE = keccak256("OP_ROLE");
  bytes32 public constant OPCO_ROLE = keccak256("OPCO_ROLE");
  bytes32 public constant BADGE_HOLDER_ROLE = keccak256("BADGE_HOLDER_ROLE");

  constructor() {
    // Grant the contract deployer the default admin role: it will be able
    // to grant and revoke any roles
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

    // Set the deployer to the OP ROLE for now
    _setupRole(OP_ROLE, msg.sender);
    // Set the deployer to the OPCo ROLE for now
    _setupRole(OPCO_ROLE, msg.sender);
  }

  struct OPCo {
    bytes32 id;
    uint256 amount;
    address[] holders;
  }

  mapping(address => OPCo) public OPCos;
  mapping(address => bool) public isOPCo;
  mapping(address => bool) isBadgeHolder;
  address[] public OPCoAccounts;
  address[] public OPCoBadgeHolders;

  // Set an OPCo
  function setOPCo(
    address _opCoAccount,
    string memory _opCoId,
    uint256 _badgeSupply
  ) public returns (bool) {
    require(hasRole(OP_ROLE, msg.sender));

    OPCo memory newOPCo;

    newOPCo.id = keccak256(abi.encodePacked(_opCoId));
    newOPCo.amount = _badgeSupply;

    OPCos[_opCoAccount] = newOPCo;
    OPCoAccounts.push(_opCoAccount);
    _setupRole(OPCO_ROLE, _opCoAccount);
    isOPCo[_opCoAccount] = true;
    return true;
  }

  function setOPCoBadgeHolders(address[] memory _holders)
    public
    returns (bool)
  {
    require(hasRole(OPCO_ROLE, msg.sender));
    OPCos[msg.sender].holders = _holders;
    	for (uint i = 0; i < _holders.length; ++i) {
		// OPCoBadgeHolders.push(_holders[i]);
        _setupRole(BADGE_HOLDER_ROLE, _holders[i]);
        isBadgeHolder[_holders[i]] = true;
	}
    return true;
  }

  function checkIsBadgeHolder(address _adr) external view returns(bool) {
      return isBadgeHolder[_adr];
  }
}

