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

contract Badge is ERC721, Ownable, AccessControl {
  event UpdatedOpCoRoot(bytes32 _opCoRoot, address[] _opCoAdresses);
  event UpdatedOpCoMinterRoot(bytes32 _minterRoot, address[] _minterAdresses);
  event Minted(address _to, address _opCo);

  bytes32 public constant OP_ROLE = keccak256("OP_ROLE");

  bytes32 public opCoRoot;
  uint256 public totalSupply;
  string public baseURI;

  mapping(address => bytes32) public opCoMinterRoots;
  mapping(address => uint256) public opCoSupply;

  mapping(address => uint256) public delegates;
  mapping(address => bool) public delegated;
  mapping(address => address) public delegatedTo;

  constructor(
    address _op,
    string memory _name,
    string memory _symbol,
    string memory _baseURI
  ) payable ERC721(_name, _symbol) {
    baseURI = _baseURI;
    _setupRole(OP_ROLE, _op);
  }

  function updateOpCoRoot(
    bytes32 _opCoRoot,
    address[] memory _opCoAddresses,
    uint256[] memory _opCoSupply
  ) public {
    if (!hasRole(OP_ROLE, msg.sender)) revert NotOp();
    emit UpdatedOpCoRoot(_opCoRoot, _opCoAddresses);
    opCoRoot = _opCoRoot;
    for (uint i = 0; i < _opCoAddresses.length; ++i) {
      opCoSupply[_opCoAddresses[i]] = _opCoSupply[i];
    }
  }

  function updateMinterRoot(
    bytes32 _root,
    bytes32[] memory _opCoProof,
    address[] memory _minterAddresses
  ) public {
    if (!_verify(_opCoProof, opCoRoot, _leaf(msg.sender))) revert NotOpCo();
    if (_minterAddresses.length > opCoSupply[msg.sender]) revert InvalidSupply();
    emit UpdatedOpCoMinterRoot(_root, _minterAddresses);
    opCoMinterRoots[msg.sender] = _root;
  }

  function withdraw() external onlyOwner {
    SafeTransferLib.safeTransferETH(msg.sender, address(this).balance);
  }

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

  function burn(uint256 _id, address _opCo) external {
    if (balanceOf[msg.sender] != 1 || ownerOf[_id] != msg.sender)
      revert InvalidBurn();
    unchecked {
      opCoSupply[_opCo]++;
      _burn(_id);
    }
  }

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

  function undelegate(address _from) external {
    if (!delegated[msg.sender] || delegatedTo[msg.sender] != _from)
      revert InvalidDelegation();
    delegatedTo[msg.sender] = address(0);
    delegated[msg.sender] = false;
    unchecked {
      delegates[_from]--;
    }
  }

  function tokenURI(uint256 _id) public view override returns (string memory) {
    if (msg.sender == address(0)) revert DoesNotExist();
    return string(abi.encodePacked(baseURI, _id));
  }

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
