// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.4.23;

import "./../Badge.sol";
import "./../../lib/ds-test/src/test.sol";
import "./../../lib/forge-std/src/console.sol";
import "./../../lib/forge-std/src/Vm.sol";

contract BadgeTest is DSTest {
  Badge internal badge;
  address deployer = HEVM_ADDRESS;

  address opAdr = 0xa8B3478A436e8B909B5E9636090F2B15f9B311e7;
  address testOpCoAdr = 0x0000024FCf3D09DfEe8E7C26f606aC201c505E58;

  bytes32 testRoot1;
  bytes32[] testProof1;
  address testAdr1;

  bytes32[] testProof2;
  address testAdr2;

  address testBadAdr;

  bytes32 testOpCoRoot;
  bytes32[] testOpCoProof;

  address[] testAdrArr;
  uint256[] testOpCoSupply;

  uint256[] testFailSupply;

  Vm internal constant hevm = Vm(HEVM_ADDRESS);

  function setUp() public {
    badge = new Badge(opAdr, "example", "ex", "example.com");

    // OpCos
    testOpCoRoot = 0x1dac86f4838acf3eba38c728988706e1aafc3e074c30e63bb654b7dddd52f3f1;
    testOpCoProof = [
      bytes32(
        0x58e922ca56c46656fdce904b9a141e3763c341533cdcdef8e45debb0ed68d044
      ),
      bytes32(
        0xe9d4019878f17ef6a346770622e1ae23b0e0cbaca66aed7babebc98c1b4f26cf
      )
    ];

    // Minters
    testRoot1 = 0x0926c055075680425d93fbf1dd2133c7d61117ace2c9adfdfccc953909f417d1;
    testProof1 = [
      bytes32(
        0x60f68dc2a5e5cb431ab7283c4ca2f0e1c5d09b7e8c80a09a9e5febf091ee20e5
      ),
      bytes32(
        0x3a5aa50b74c3f0c7e703cd7ac6a0c6270442f5d396ecebf37ead7b5fd2c7564d
      )
    ];
    testAdr1 = 0x0000008735754EDa8dB6B50aEb93463045fc5c55;

    testProof2 = [
      bytes32(
        0xf643c4b4209cd4a6a5668deac1a7740f1ff652416f21234c83af793d220282a3
      ),
      bytes32(
        0x3a5aa50b74c3f0c7e703cd7ac6a0c6270442f5d396ecebf37ead7b5fd2c7564d
      )
    ];
    testAdr2 = 0x802999C71263f7B30927F720CF0AC10A76a0494C;

    testBadAdr = 0x0984278a1099bdB47B39FD6B0Ac8Aa83b3000000;
	
	testAdrArr = [testOpCoAdr, testAdr1, testAdr2, testBadAdr];
	testOpCoSupply = [8008, 100, 69, 420];

  }

  function testUpdateOpCoRoot() public {
    hevm.prank(opAdr);
    badge.updateOpCoRoot(testOpCoRoot, testAdrArr, testOpCoSupply);
  }

  function testInvalidUpdateOpCoRoot() public {
    hevm.expectRevert(abi.encodeWithSignature("NotOp()"));
    hevm.prank(0xffffff308539Da3d54F90676b52568515Ed43F39);
    badge.updateOpCoRoot(testOpCoRoot, testAdrArr, testOpCoSupply);
  }

  function testUpdateMinterRoot() public {
    hevm.prank(opAdr);
    badge.updateOpCoRoot(testOpCoRoot, testAdrArr, testOpCoSupply);
    hevm.prank(testOpCoAdr);
    badge.updateMinterRoot(testRoot1, testOpCoProof, testAdrArr);
  }

  function _setupRoots() public {
    hevm.prank(opAdr);
    badge.updateOpCoRoot(testOpCoRoot, testAdrArr, testOpCoSupply);
    hevm.prank(testOpCoAdr);
    badge.updateMinterRoot(testRoot1, testOpCoProof, testAdrArr);
  }

  function testInvalidOpCoUpdateMinterRoot() public {
    _setupRoots();

    hevm.expectRevert(abi.encodeWithSignature("NotOpCo()"));
    badge.updateMinterRoot(testRoot1, testOpCoProof, testAdrArr);
  }

  function testMint() public {
    _setupRoots();

    badge.mint(testAdr1, testOpCoAdr, testProof1);
  }

  function testInvalidMinterMint() public {
    _setupRoots();

    hevm.expectRevert(abi.encodeWithSignature("InvalidMinter()"));
    badge.mint(testBadAdr, testOpCoAdr, testProof1);
  }

  function testInvalidAlreadyClaimedMint() public {
    _setupRoots();

    badge.mint(testAdr1, testOpCoAdr, testProof1);
    hevm.expectRevert(abi.encodeWithSignature("AlreadyClaimed()"));
    badge.mint(testAdr1, testOpCoAdr, testProof1);
  }

  function testInvalidBadgeTransfer() public {
    _setupRoots();

    badge.mint(testAdr1, testOpCoAdr, testProof1);

    hevm.expectRevert(abi.encodeWithSignature("Soulbound()"));
    badge.transferFrom(testAdr1, 0x0984278a1099bdB47B39FD6B0Ac8Aa83b3000000, 0);
  }

  function testBurn() public {
    _setupRoots();

    badge.mint(testAdr1, testOpCoAdr, testProof1);
    hevm.prank(testAdr1);
    badge.burn(0, testOpCoAdr);
  }

  function testInvalidBurn() public {
    _setupRoots();

    badge.mint(testAdr1, testOpCoAdr, testProof1);
    hevm.expectRevert(abi.encodeWithSignature("InvalidBurn()"));
    hevm.prank(testAdr1);
    badge.burn(1, testOpCoAdr);
  }

  function testDelegation() public {
    _setupRoots();

    badge.mint(testAdr1, testOpCoAdr, testProof1);
    badge.mint(testAdr2, testOpCoAdr, testProof2);

    hevm.prank(testAdr1);
    badge.delegate(testAdr2);
  }

  function testInvalidDelegation() public {
    _setupRoots();

    // -- Un/Comment out any of these to test various cases --
    badge.mint(testAdr1, testOpCoAdr, testProof1);
    badge.mint(testAdr2, testOpCoAdr, testProof2);
    // hevm.prank(testAdr1);
    // -- --

    hevm.expectRevert(abi.encodeWithSignature("InvalidDelegation()"));
    badge.delegate(testAdr2);
  }

  function testUndelegation() public {
    _setupRoots();

    badge.mint(testAdr1, testOpCoAdr, testProof1);
    badge.mint(testAdr2, testOpCoAdr, testProof2);

    hevm.prank(testAdr1);
    badge.delegate(testAdr2);

    hevm.prank(testAdr1);
    badge.undelegate(testAdr2);
  }

  function testInvalidUndelegation() public {
    _setupRoots();

    // -- Un/Comment out any of these to test various cases --
    badge.mint(testAdr1, testOpCoAdr, testProof1);
    badge.mint(testAdr2, testOpCoAdr, testProof2);
    hevm.prank(testAdr1);
    badge.delegate(testAdr2);
    // -- --

    hevm.expectRevert(abi.encodeWithSignature("InvalidDelegation()"));
    badge.undelegate(testAdr2);
  }
}
