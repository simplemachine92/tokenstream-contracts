// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.10;

import "./../lib/solmate/src/utils/SafeTransferLib.sol";
import "./../lib/solmate/src/tokens/ERC721.sol";
import "./../lib/openzeppelin-contracts/contracts/utils/cryptography/MerkleProof.sol";
import "./../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "./../lib/openzeppelin-contracts/contracts/access/AccessControl.sol";

error InvalidMinter();
error DoesNotExist();
error Soulbound();
error AlreadyClaimed();
error NotOpCo();
error NotOp();
error InvalidBalance();
error AlreadyDelegated();
error NotDelegated();
error InvalidDelegation();
error InvalidBurn();
error InvalidSupply();

/// @notice A minimalist soulbound ERC-721 implementaion with hierarchical
///         whitelisting and token delegation.
/// @author MOONSHOT COLLECTIVE (https://github.com/moonshotcollective)
contract Badge is ERC721, Ownable, AccessControl {
  event UpdatedOpCoRoot(bytes32 _opCoRoot, address[] _opCoAdresses);
  event UpdatedOpCoMinterRoot(bytes32 _minterRoot, address[] _minterAdresses);
  event Minted(address _to, address _opCo);

  /*///////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

  bytes32 public constant OP_ROLE = keccak256("OP_ROLE");

  bytes32 internal opCoRoot;
  uint256 public totalSupply;
  string public baseURI;

  mapping(address => bytes32) internal opCoMinterRoots;
  mapping(address => uint256) public opCoSupply;

  mapping(address => uint256) public delegates;
  mapping(address => bool) public delegated;
  mapping(address => address) public delegatedTo;

  /*///////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

  constructor(
    address _op,
    string memory _name,
    string memory _symbol,
    string memory _baseURI
  ) payable ERC721(_name, _symbol) {
    baseURI = _baseURI;
    _setupRole(OP_ROLE, _op);
  }

  /*///////////////////////////////////////////////////////////////
                                OP  LOGIC
    //////////////////////////////////////////////////////////////*/

  /// @notice Update the OPCo Merkle Root
  /// @dev Updates the OPCo merkle root for OPCo whitelisting.
  /// @param _opCoRoot A merkle root of the OPCo address tree.
  /// @param _opCoAddresses The array of addresses hashed in the merkle tree.
  /// @param _opCoSupply The array of max supply each OPCo address is allowed.
  function updateOpCoRoot(
    bytes32 _opCoRoot,
    address[] memory _opCoAddresses,
    uint256[] memory _opCoSupply
  ) public {
    if (!hasRole(OP_ROLE, msg.sender)) revert NotOp();
    emit UpdatedOpCoRoot(_opCoRoot, _opCoAddresses);
    opCoRoot = _opCoRoot;
    for (uint256 i = 0; i < _opCoAddresses.length; ++i) {
      opCoSupply[_opCoAddresses[i]] = _opCoSupply[i];
    }
  }

  /*///////////////////////////////////////////////////////////////
                              OPCO  LOGIC
    //////////////////////////////////////////////////////////////*/

  /// @notice Update the OPCo Minters Merkle Root
  /// @dev Updates the OPCo minters merkle root for mint whitelisting.
  /// @param _minterRoot A merkle root of the OPCo's minters tree.
  /// @param _opCoProof A merkle proof of the OPCo's validity.
  /// @param _minterAddresses The array of addresses hashed in the minters tree.
  function updateMinterRoot(
    bytes32 _minterRoot,
    bytes32[] memory _opCoProof,
    address[] memory _minterAddresses
  ) public {
    if (!_verify(_opCoProof, opCoRoot, _leaf(msg.sender))) revert NotOpCo();
    if (_minterAddresses.length > opCoSupply[msg.sender])
      revert InvalidSupply();
    emit UpdatedOpCoMinterRoot(_minterRoot, _minterAddresses);
    opCoMinterRoots[msg.sender] = _minterRoot;
  }

  /*///////////////////////////////////////////////////////////////
                              BADGE LOGIC
    //////////////////////////////////////////////////////////////*/

  /// @notice Mint
  /// @dev Mints the soulbound ERC721 token.
  /// @param _to The address to mint the token to.
  /// @param _opCo The associated OPCo of the _to address.
  /// @param _proof The merkle proof associated with the minters validity.
  function mint(
    address _to,
    address _opCo,
    bytes32[] calldata _proof
  ) external payable {
    if (_to == address(0)) revert DoesNotExist();
    if (balanceOf[_to] > 0) revert AlreadyClaimed();
    if (!_verify(_proof, opCoMinterRoots[_opCo], _leaf(_to)))
      revert InvalidMinter();
    emit Minted(_to, _opCo);
    unchecked {
      opCoSupply[_opCo]--;
      _mint(_to, totalSupply++);
    }
  }

  /// @notice Burn
  /// @dev Burns the soulbound ERC721.
  /// @param _id The token URI.
  /// @param _opCo The OPCo associated with the token burner.
  function burn(uint256 _id, address _opCo) external {
    if (balanceOf[msg.sender] != 1 || ownerOf[_id] != msg.sender)
      revert InvalidBurn();
    unchecked {
      opCoSupply[_opCo]++;
      _burn(_id);
    }
  }

  /// @notice Delegate the token
  /// @dev Delegate a singular token (without transfer) to another holder.
  /// @param _to The address the sender is delegating to.
  function delegate(address _to) external {
    if (
      balanceOf[msg.sender] != 1 || delegated[msg.sender] || balanceOf[_to] == 0
    ) revert InvalidDelegation();
    delegatedTo[msg.sender] = _to;
    delegated[msg.sender] = true;
    unchecked {
      delegates[_to]++;
    }
  }

  /// @notice Un-Delegate the token
  /// @dev Un-Delegate a singular token (without transfer) from an address.
  /// @param _from The address the sender is un-delegating from.
  function undelegate(address _from) external {
    if (!delegated[msg.sender] || delegatedTo[msg.sender] != _from)
      revert InvalidDelegation();
    delegatedTo[msg.sender] = address(0);
    delegated[msg.sender] = false;
    unchecked {
      delegates[_from]--;
    }
  }

  /// @notice Token URI
  /// @dev Generate a token URI.
  /// @param _id The token URI.
  function tokenURI(uint256 _id) public view override returns (string memory) {
    if (msg.sender == address(0)) revert DoesNotExist();
    return string(abi.encodePacked(baseURI, _id));
  }

  /*///////////////////////////////////////////////////////////////
                          INTERNAL LOGIC
    //////////////////////////////////////////////////////////////*/

  function _leaf(address _adr) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(_adr));
  }

  function _verify(
    bytes32[] memory _proof,
    bytes32 _root,
    bytes32 _node
  ) internal pure returns (bool) {
    return MerkleProof.verify(_proof, _root, _node);
  }

  // Make it ~*~ Soulbound ~*~
  function transferFrom(
    address,
    address,
    uint256
  ) public pure override {
    revert Soulbound();
  }

  function withdraw() external onlyOwner {
    SafeTransferLib.safeTransferETH(msg.sender, address(this).balance);
  }

  function supportsInterface(bytes4 _interfaceId)
    public
    pure
    override(ERC721, AccessControl)
    returns (bool)
  {
    return
      _interfaceId == 0x7f5828d0 || // ERC165 Interface ID for ERC173
      _interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
      _interfaceId == 0x5b5e139f || // ERC165 Interface ID for ERC165
      _interfaceId == 0x01ffc9a7; // ERC165 Interface ID for ERC721Metadata
  }
}
