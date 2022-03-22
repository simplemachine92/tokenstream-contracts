// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.4.23;

import "./../Badge.sol";
import "./../../lib/ds-test/src/test.sol";
import "./../../lib/forge-std/src/console.sol";
import "./../../lib/forge-std/src/Vm.sol";

contract BadgeTest is DSTest {
  Badge internal badge;
  address testOpCoAdr;
  bytes32 testRoot1; 
  bytes32[] testProof1;
  address testAdr1; 
  bytes32[] testProof2;

  bytes32 testOpCoRoot;
  bytes32[] testOpCoProof;
  
  Vm internal constant hevm = Vm(HEVM_ADDRESS);

  function setUp() public {
    badge = new Badge(HEVM_ADDRESS, "example", "ex", "example.com");

    // OpCos
    testOpCoRoot = 0x1dac86f4838acf3eba38c728988706e1aafc3e074c30e63bb654b7dddd52f3f1; 
    testOpCoProof = [
      bytes32(0x58e922ca56c46656fdce904b9a141e3763c341533cdcdef8e45debb0ed68d044), 
      bytes32(0xe9d4019878f17ef6a346770622e1ae23b0e0cbaca66aed7babebc98c1b4f26cf)
    ]; 
    testOpCoAdr = 0x0000024FCf3D09DfEe8E7C26f606aC201c505E58;

    // Minters
    testRoot1 = 0x0926c055075680425d93fbf1dd2133c7d61117ace2c9adfdfccc953909f417d1;
    testProof1 = [
      bytes32(0x60f68dc2a5e5cb431ab7283c4ca2f0e1c5d09b7e8c80a09a9e5febf091ee20e5), 
      bytes32(0x3a5aa50b74c3f0c7e703cd7ac6a0c6270442f5d396ecebf37ead7b5fd2c7564d)
    ];
    testAdr1 = 0x0000008735754EDa8dB6B50aEb93463045fc5c55;
  }

  function _setupRoots() public {
    badge.updateOpCoRoot(testOpCoRoot); 
    hevm.prank(testOpCoAdr);
    badge.updateMinterRoot(testRoot1, testOpCoProof);
  }

  function testUpdateOpCoRoot() public {
    badge.updateOpCoRoot(testOpCoRoot); 
  }

  function testUpdateMinterRoot() public {
    badge.updateOpCoRoot(testOpCoRoot); 
    hevm.prank(testOpCoAdr);
    badge.updateMinterRoot(testRoot1, testOpCoProof);
  }

  function testInvalidOpCoUpdateMinterRoot() public {
    _setupRoots();
    
    hevm.expectRevert(abi.encodeWithSignature("NotOpCo()"));
    badge.updateMinterRoot(testRoot1, testOpCoProof);
  }

  function testMint() public {
    _setupRoots();

    badge.mint(testAdr1, testOpCoAdr, testProof1);
  }

  function testInvalidMinterMint() public {
    _setupRoots();

    hevm.expectRevert(abi.encodeWithSignature("InvalidMinter()"));
    badge.mint(0x0984278a1099bdB47B39FD6B0Ac8Aa83b3000000, testOpCoAdr, testProof1);
  }

  function testInvalidBadgeTransfer() public {
    _setupRoots();

    badge.mint(testAdr1, testOpCoAdr, testProof1);

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
