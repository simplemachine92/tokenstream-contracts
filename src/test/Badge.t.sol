// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.4.23;

import "./../../lib/ds-test/src/test.sol";
import "./../OPCoFactory.sol";
import "./../Badge.sol";
import "./../../lib/forge-std/src/console.sol";
import "./../../lib/openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract BadgeTest is OPCoFactory, DSTest {
  OPCoFactory internal factory;
  Badge internal badge; 
  address deployerAcct; 
  address testOPCoAcct;
  address[] internal testBadgeHolders;

  function setUp() public {
    testBadgeHolders = [
      0x02Bb75dD262A7C1d9682c77fff54643a595176E5,
      0x0000008735754EDa8dB6B50aEb93463045fc5c55,
      0xc2102c929CF30A91A6244Dc8B21F048468DEC56A
    ];
    testOPCoAcct = 0x802999C71263f7B30927F720CF0AC10A76a0494C;
    badge = new Badge(msg.sender, "example", "ex", "example.com");

    badge.setOPCo(testOPCoAcct, "xx", 10e2);
    badge.setOPCoBadgeHolders(testBadgeHolders);
    badge.mint(testBadgeHolders[0], 1);

  }

  function testMint() public {
      badge.mint(testBadgeHolders[1], 1);
  }
  function testApprove() public { 
    //   badge.approve(testBadgeHolders[1], 1);
  }
}
