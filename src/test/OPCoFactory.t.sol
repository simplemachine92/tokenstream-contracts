// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.4.23;

import "../../lib/ds-test/src/test.sol";
import "./../OPCoFactory.sol";
import "./../../lib/forge-std/src/Vm.sol";
import "./../../lib/forge-std/src/Vm.sol";

contract OpCoFactoryTest is DSTest {
  OpCoFactory internal factory;
  address testAdr1;
  bytes32 testRoot1; 
  address invalidAccount;
  Vm internal constant hevm = Vm(HEVM_ADDRESS);

  function setUp() public {
    factory = new OpCoFactory();

    testAdr1 = 0x802999C71263f7B30927F720CF0AC10A76a0494C;
    testRoot1 = 0x5b0ec3549017db66eb94fc10219382abaf1ba8ca50a2c33931589d67a22e9103;
  }

  function testSetOpCo() public {
    factory.newOpCo(testAdr1);
  }

  function testSetOPCo_InvalidRole() public {
    // hevm.expectRevert(abi.encodeWithSignature("InvalidRole()"));
    // hevm.prank(invalidAccount);
    // factory.setOPCo(testOPCoAcct, "xx", 10e2);
  }

  function testSetOpCoBadgeHolders() public {
    factory.setOpCoBadgeMinters(testAdr1, testRoot1);
  }

  function testSetOPCoBadgeHolders_InvalidRole() public {
    // hevm.expectRevert(abi.encodeWithSignature("InvalidRole()"));
    // hevm.prank(invalidAccount);
    // factory.setOPCoBadgeHolders(testBadgeHolders);
  }
}
