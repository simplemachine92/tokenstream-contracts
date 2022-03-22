// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.10;

import "./OPCoFactory.sol";
import "./../lib/solmate/src/utils/SafeTransferLib.sol";
import "./../lib/solmate/src/tokens/ERC721.sol";
import "./../lib/openzeppelin-contracts/contracts/utils/cryptography/MerkleProof.sol";

error InvalidHolder();
error NotOwner();
error DoesNotExist();
error NoBadgesLeft();
error InvalidTransfer();
error AlreadyClaimed();

contract Badge is ERC721, OpCoFactory {
  uint256 public totalSupply;

  string public baseURI;
  address public owner;

  mapping(address => bool) claimed; 

  constructor(
    address admin,
    string memory name,
    string memory symbol,
    string memory _baseURI
  ) payable ERC721(name, symbol) {
    baseURI = _baseURI;
    owner = msg.sender;
  }

  function withdraw() external {
    if (msg.sender != owner) revert NotOwner();
    SafeTransferLib.safeTransferETH(msg.sender, address(this).balance);
  }

  function mint(
    address _to,
    bytes32 _root, 
    bytes32[] calldata _proof
  ) external {
    if (claimed[_to]) revert AlreadyClaimed(); 
    if (!MerkleProof.verify(_proof, _root, keccak256(abi.encodePacked(_to)))) revert InvalidHolder();
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
    override(ERC721, AccessControl)
    returns (bool)
  {
    return
      interfaceId == 0x7f5828d0 || // ERC165 Interface ID for ERC173
      interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
      interfaceId == 0x5b5e139f || // ERC165 Interface ID for ERC165
      interfaceId == 0x01ffc9a7; // ERC165 Interface ID for ERC721Metadata
  }
}
