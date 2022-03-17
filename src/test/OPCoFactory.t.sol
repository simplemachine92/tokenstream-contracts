// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.4.23;

import "../../lib/ds-test/src/test.sol";
import "./../OPCoFactory.sol";
import "./../../lib/forge-std/src/Vm.sol";
import "./../../lib/forge-std/src/Vm.sol";

contract OPCoFactoryTest is DSTest {
  OPCoFactory internal factory;
  address deployerAcct;
  address testOPCoAcct;
  address invalidAccount;
  address[] internal testBadgeHolders;
  Vm internal constant hevm = Vm(HEVM_ADDRESS);

  function setUp() public {
    factory = new OPCoFactory();
    testBadgeHolders = [
      0x02Bb75dD262A7C1d9682c77fff54643a595176E5,
      0x0000008735754EDa8dB6B50aEb93463045fc5c55,
      0xc2102c929CF30A91A6244Dc8B21F048468DEC56A
    ];
    testOPCoAcct = 0x802999C71263f7B30927F720CF0AC10A76a0494C;
    invalidAccount = 0xFe59E676BaB8698c70F01023747f2E27e8A065B9;
  }

  function testSetOpCo() public {
    factory.setOPCo(testOPCoAcct, "xx", 10e2);
  }

  function testSetOPCo_InvalidRole() public {
    hevm.expectRevert(abi.encodeWithSignature("InvalidRole()"));
    hevm.prank(invalidAccount);
    factory.setOPCo(testOPCoAcct, "xx", 10e2);
  }

  function testSetOPCoBadgeHolders() public {
    factory.setOPCoBadgeHolders(testBadgeHolders);
  }

  function testSetOPCoBadgeHolders_InvalidRole() public {
    hevm.expectRevert(abi.encodeWithSignature("InvalidRole()"));
    hevm.prank(invalidAccount);
    factory.setOPCoBadgeHolders(testBadgeHolders);
  }
}
