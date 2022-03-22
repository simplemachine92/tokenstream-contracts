// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.10;

import "./../lib/solmate/src/utils/SafeTransferLib.sol";
import "./../lib/solmate/src/tokens/ERC721.sol";
import "./../lib/openzeppelin-contracts/contracts/utils/cryptography/MerkleProof.sol";

error InvalidMinter();
error NotOwner();
error DoesNotExist();
error NoBadgesLeft();
error InvalidTransfer();
error AlreadyClaimed();
error NotOpCo();

contract Badge is ERC721 {
  uint256 public totalSupply;

  string public baseURI;
  address public owner;

  bytes32 public opCoRoot;
  mapping(address => bytes32) public opCoMinterRoots;
  mapping(address => bool) public claimed; 

  constructor(
    address admin,
    string memory name,
    string memory symbol,
    string memory _baseURI
  ) payable ERC721(name, symbol) {
    baseURI = _baseURI;
    owner = msg.sender;
  }

  function _leaf(address _adr) internal pure returns(bytes32) {
    return keccak256(abi.encodePacked(_adr));
  }

  function updateOpCoRoot(bytes32 _opCoRoot) public {
    opCoRoot = _opCoRoot;
  }

  function updateMinterRoot(bytes32 _root, bytes32[] memory _opCoProof) public {
    if (!MerkleProof.verify(_opCoProof, opCoRoot, _leaf(msg.sender))) revert NotOpCo();
    opCoMinterRoots[msg.sender] = _root; 
  }

  function withdraw() external {
    if (msg.sender != owner) revert NotOwner();
    SafeTransferLib.safeTransferETH(msg.sender, address(this).balance);
  }

  function mint(
    address _to,
    address _opCo, 
    bytes32[] calldata _proof
  ) payable external {
    if (claimed[_to]) revert AlreadyClaimed(); 
    if (!MerkleProof.verify(_proof, opCoMinterRoots[_opCo], _leaf(_to))) revert InvalidMinter();
    unchecked {
        _mint(_to, totalSupply++);
        claimed[_to] = true; 
    }
  }

  function burn(uint256 id) external {
    unchecked {
      _burn(id);
    }
  }

  function tokenURI(uint256 id) public view override returns (string memory) {
    if (msg.sender == address(0)) revert DoesNotExist();
    return string(abi.encodePacked(baseURI, id));
  }

  // Make it souldbound
  function transferFrom(
    address,
    address,
    uint256
  ) public override {
    revert InvalidTransfer();
  }

  function supportsInterface(bytes4 interfaceId)
    public
    pure
    override(ERC721)
    returns (bool)
  {
    return
      interfaceId == 0x7f5828d0 || // ERC165 Interface ID for ERC173
      interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
      interfaceId == 0x5b5e139f || // ERC165 Interface ID for ERC165
      interfaceId == 0x01ffc9a7; // ERC165 Interface ID for ERC721Metadata
  }
}
