// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.10;

import "./OPCoFactory.sol";
import "./../lib/solmate/src/utils/SafeTransferLib.sol";
import "./../lib/solmate/src/tokens/ERC721.sol";

error InvalidHolder();
error NotOwner();
error DoesNotExist();
error NoBadgesLeft();
error InvalidTransfer();

contract Badge is ERC721, OPCoFactory {
  uint256 public totalSupply;

  string public baseURI;
  address public owner;


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
    uint16 _amount,
    address _opCo
  ) external {
    if (!hasRole(BADGE_HOLDER_ROLE, _to)) revert InvalidRole();
    // if (!isBadgeHolder[_to]) revert InvalidHolder();
    if (totalSupply + _amount >= OPCos[_opCo].amount) revert NoBadgesLeft();

    unchecked {
      for (uint16 index = 0; index < _amount; index++) {
        _mint(_to, totalSupply++);
      }
    }
  }

  function burn(uint256 id) external {
    if (!hasRole(BADGE_HOLDER_ROLE, msg.sender)) revert InvalidRole();
    if (ownerOf[id] != msg.sender) revert InvalidHolder();
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
