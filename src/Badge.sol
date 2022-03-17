pragma solidity ^0.8.10;

import "./Soulbound.sol";
import "./OPCoFactory.sol";
import "../lib/openzeppelin/contracts/token/ERC721/ERC721.sol";
import "../lib/openzeppelin/contracts/access/AccessControl.sol";
import "../lib/openzeppelin/contracts/utils/Counters.sol";
import "./../lib/forge-std/src/console.sol";

import "../lib/openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "../lib/openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "../lib/openzeppelin/contracts/finance/PaymentSplitter.sol";
import "../lib/openzeppelin/contracts/access/Ownable.sol";
import "../lib/openzeppelin/contracts/security/ReentrancyGuard.sol";


contract Badge is Soulbound, OPCoFactory {
    
    uint256 public constant TOTAL_SUPPLY = 10_000;

    uint256 public totalSupply;

    string public baseURI;

    OPCoFactory factory;

    constructor(
        address admin, 
        string memory name,
        string memory symbol,
        string memory _baseURI
    ) payable Soulbound(admin, name, symbol) {
        baseURI = _baseURI;
        factory = new OPCoFactory();
    }

    function mint(address _to, uint16 _amount) external {
        require(isBadgeHolder[_to], "INVALID HOLDER");
        require(hasRole(BADGE_HOLDER_ROLE, _to), "INVALID ROLE");

        unchecked {
            for (uint16 index = 0; index < _amount; index++) {
                _mint(_to, totalSupply++);
            }
        }
	}

    function tokenURI(uint256 id) public view override returns (string memory) {

        return string(abi.encodePacked(baseURI, id));
    }

	// Should probably have a withdraw method
	
    function supportsInterface(bytes4 interfaceId)
        public
        pure
        override(Soulbound, AccessControl)
        returns (bool)
    {
        return
            interfaceId == 0x7f5828d0 || // ERC165 Interface ID for ERC173
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f || // ERC165 Interface ID for ERC165
            interfaceId == 0x01ffc9a7; // ERC165 Interface ID for ERC721Metadata
    }
}