// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.4.23;

import "./../../lib/ds-test/src/test.sol";
import "./../OPCoFactory.sol";
import "./../Badge.sol";
import "./../../lib/forge-std/src/console.sol";
import "./../../lib/forge-std/src/Vm.sol";

contract BadgeTest is OpCoFactory, DSTest {
  OpCoFactory internal factory;
  Badge internal badge;
  address testOpCoAdr;
  bytes32 testRoot1; 
  bytes32[] testProof1;
  address testAdr1; 
  bytes32[] testProof2;
  Vm internal constant hevm = Vm(HEVM_ADDRESS);

  /**
    [
    "0x0000008735754EDa8dB6B50aEb93463045fc5c55",
    "0x802999C71263f7B30927F720CF0AC10A76a0494C",
    "0x02Bb75dD262A7C1d9682c77fff54643a595176E5"
  ]
   */

  function setUp() public {
    badge = new Badge(HEVM_ADDRESS, "example", "ex", "example.com");
    factory = new OpCoFactory();
    testOpCoAdr = 0x802999C71263f7B30927F720CF0AC10A76a0494C;
    testRoot1 = 0x0926c055075680425d93fbf1dd2133c7d61117ace2c9adfdfccc953909f417d1;
    testProof1 = [bytes32(0x60f68dc2a5e5cb431ab7283c4ca2f0e1c5d09b7e8c80a09a9e5febf091ee20e5), bytes32(0x3a5aa50b74c3f0c7e703cd7ac6a0c6270442f5d396ecebf37ead7b5fd2c7564d)];
    testAdr1 = 0x0000008735754EDa8dB6B50aEb93463045fc5c55;
    testProof2 = [
      bytes32(0x10f68dc2a5e5cb431ab7283c4ca2f0e1c5d09b7e8c80a09a9e5febf091ee20e5),
      bytes32(0xc643c4b4209cd4a6a5668deac1b7740f1ff652416f21234c83af793d220282a3)
    ];
    factory.newOpCo(testOpCoAdr);
    factory.setOpCoBadgeMinters(testOpCoAdr, testRoot1);
  }

  function testMint() public {
    badge.mint(testAdr1, testRoot1, testProof1);
  }

  function testInvalidHolderMint() public {
    hevm.expectRevert(abi.encodeWithSignature("InvalidHolder()"));
    badge.mint(0x0984278a1099bdB47B39FD6B0Ac8Aa83b3000000, testRoot1, testProof1);
  }

  function testInvalidBadgeTransfer() public {
    badge.mint(testAdr1, testRoot1, testProof1);
    hevm.expectRevert(abi.encodeWithSignature("InvalidTransfer()"));
    badge.transferFrom(testAdr1, 0x0984278a1099bdB47B39FD6B0Ac8Aa83b3000000, 0);
  }

  function testBadgeBurn() public {
	  // badge.mint(testBadgeHolders[1], 1, testOPCoAcct[0]);
	  // hevm.prank(testBadgeHolders[1]);
	  // badge.burn(0);
  }
  function testInvalidBadgeBurn() public {
	  // badge.mint(testBadgeHolders[1], 1, testOPCoAcct[0]);
    // hevm.expectRevert(abi.encodeWithSignature("InvalidHolder()"));
	  // hevm.prank(testBadgeHolders[1]);
	  // badge.burn(1);
  }
}
