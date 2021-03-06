// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.4.23;

import "./../stream.sol";
import "./../GTC.sol";
import "./../../lib/ds-test/src/test.sol";
import "./../../lib/forge-std/src/console.sol";
import "./../../lib/forge-std/src/Vm.sol";

/* contract GTC_Dummy is DSTest {
  GTC public token;
  address deployer = HEVM_ADDRESS;

  Vm internal constant hevm = Vm(HEVM_ADDRESS);

function setUp() public {
    token = new GTC(deployer);
  }
} */

// Fold at line below in your IDE for a better view...
interface CheatCodes {
    function warp(uint256) external;

    // Set block.timestamp

    function roll(uint256) external;

    // Set block.number

    function fee(uint256) external;

    // Set block.basefee

    function load(address account, bytes32 slot) external returns (bytes32);

    // Loads a storage slot from an address

    function store(
        address account,
        bytes32 slot,
        bytes32 value
    ) external;

    // Stores a value to an address' storage slot

    function sign(uint256 privateKey, bytes32 digest)
        external
        returns (
            uint8 v,
            bytes32 r,
            bytes32 s
        );

    // Signs data

    function addr(uint256 privateKey) external returns (address);

    // Computes address for a given private key

    function ffi(string[] calldata) external returns (bytes memory);

    // Performs a foreign function call via terminal

    function prank(address) external;

    // Sets the *next* call's msg.sender to be the input address

    function startPrank(address) external;

    // Sets all subsequent calls' msg.sender to be the input address until `stopPrank` is called

    function prank(address, address) external;

    // Sets the *next* call's msg.sender to be the input address, and the tx.origin to be the second input

    function startPrank(address, address) external;

    // Sets all subsequent calls' msg.sender to be the input address until `stopPrank` is called, and the tx.origin to be the second input

    function stopPrank() external;

    // Resets subsequent calls' msg.sender to be `address(this)`

    function deal(address who, uint256 newBalance) external;

    // Sets an address' balance

    function etch(address who, bytes calldata code) external;

    // Sets an address' code

    function expectRevert() external;

    function expectRevert(bytes calldata) external;

    function expectRevert(bytes4) external;

    // Expects an error on next call

    function record() external;

    // Record all storage reads and writes

    function accesses(address)
        external
        returns (bytes32[] memory reads, bytes32[] memory writes);

    // Gets all accessed reads and write slot from a recording session, for a given address

    function expectEmit(
        bool,
        bool,
        bool,
        bool
    ) external;

    // Prepare an expected log with (bool checkTopic1, bool checkTopic2, bool checkTopic3, bool checkData).
    // Call this function, then emit an event, then call a function. Internally after the call, we check if
    // logs were emitted in the expected order with the expected topics and data (as specified by the booleans)

    function mockCall(
        address,
        bytes calldata,
        bytes calldata
    ) external;

    // Mocks a call to an address, returning specified data.
    // Calldata can either be strict or a partial match, e.g. if you only
    // pass a Solidity selector to the expected calldata, then the entire Solidity
    // function will be mocked.

    function clearMockedCalls() external;

    // Clears all mocked calls

    function expectCall(address, bytes calldata) external;

    // Expect a call to an address with the specified calldata.
    // Calldata can either be strict or a partial match

    function getCode(string calldata) external returns (bytes memory);

    // Gets the bytecode for a contract in the project given the path to the contract.

    function label(address addr, string calldata label) external;

    // Label an address in test traces

    function assume(bool) external;
    // When fuzzing, generate new inputs if conditional not met
}

contract StreamTest is DSTest {
    CheatCodes cheats = CheatCodes(HEVM_ADDRESS);

    string _orgName = "GitcoinDAO";
    string _logoURI = "placeholder";
    string _orgDescription = "dem der public goods";

    address[] _managers = [0xa8B3478A436e8B909B5E9636090F2B15f9B311e7];
    address[] _addresses = [0xa8B3478A436e8B909B5E9636090F2B15f9B311e7];
    uint256[] _caps = [0.5 ether];
    uint256[] _freqs = [1296000];
    bool[] _startsF = [true];

    address payable me = payable(0xa8B3478A436e8B909B5E9636090F2B15f9B311e7);

    MultiStream internal stream;
    GTC token;
    address deployer = HEVM_ADDRESS;

    Vm internal constant hevm = Vm(HEVM_ADDRESS);

    uint256 initAmount = 1000000000000000000000; // or 1000 tokens

    function setUp() public {
        cheats.warp(1641070800);

        token = new GTC(deployer);
        stream = new MultiStream(
            _orgName,
            me,
            _addresses,
            _caps,
            _freqs,
            _startsF,
            address(token)
        );
        cheats.prank((address(deployer)));
        token.transfer(address(stream), 1000000000000000000000);
    }

    function testInitBalance() public {
        // Make sure we have an initial balance to test withdraws to authorized users
        assertEq(token.balanceOf(address(stream)), initAmount);
    }

    function testManagerFunctions(uint256 amount) public {
        // Address "me" was included in constructer as "owner", so it can assign roles
        cheats.prank((address(me)));
        // Gives self manager role
        stream.addManager(me);

        // Call addStream() with recently granted manager role
        cheats.prank((address(me)));
        stream.addStream(
            address(0xb010ca9Be09C382A9f31b79493bb232bCC319f01),
            0.5 ether,
            1296000,
            true
        );

        // Withdraw from newly created stream as it has "true" for startsFull
        cheats.prank(address(0xb010ca9Be09C382A9f31b79493bb232bCC319f01));
        stream.streamWithdraw(0.5 ether, "reason");
        assertEq(
            stream.streamBalance(0xb010ca9Be09C382A9f31b79493bb232bCC319f01),
            0
        );

        cheats.prank((address(me)));

        // We limit increases to under "1 ether" in contract to avoid int overflow in streamBalance
        cheats.assume(amount < 0.5 ether && amount > 0);
        stream.increaseCap(amount, 0xb010ca9Be09C382A9f31b79493bb232bCC319f01);

        // Warp two-weeks later, stream is full again.
        cheats.warp(1642366800);

        // Balance is updating correctly over time
        assertEq(
            stream.streamBalance(0xb010ca9Be09C382A9f31b79493bb232bCC319f01),
            0.5 ether + amount
        );

        cheats.prank(address(0xb010ca9Be09C382A9f31b79493bb232bCC319f01));

        // Withdraw new balance accumulated after stream cap update
        stream.streamWithdraw(0.5 ether + amount, "reason");
    }

    function testStreamWithdraw(uint256 amount) public {
        // Acting as permitted stream user address 0xa8B3...11e7
        hevm.prank(address(0xa8B3478A436e8B909B5E9636090F2B15f9B311e7));

        // Fuzz test all viable amounts, > would fail here..
        cheats.assume(amount < 0.5 ether);

        // Calls from 0xa8B3...11e7
        stream.streamWithdraw(amount, "reason");

        // Ensure contract balance is proper after withdraw from stream
        assertEq(token.balanceOf(address(stream)), initAmount - amount);

        /* try withdrawing again almost 2 weeks into the future, when stream should be full */
        hevm.prank(address(0xa8B3478A436e8B909B5E9636090F2B15f9B311e7));
        cheats.warp(1642366800);
        stream.streamWithdraw(0.5 ether, "reason");
    }

    function testFailWithdrawFromDisabled() public {
        // Warp to where stream should be full but disable it next
        cheats.warp(1643662800);

        // Disable it here
        cheats.prank((address(me)));
        stream.disableStream(0xb010ca9Be09C382A9f31b79493bb232bCC319f01);

        // User tries withdrawing from disabled stream
        cheats.prank(address(0xb010ca9Be09C382A9f31b79493bb232bCC319f01));
        // Fails
        stream.streamWithdraw(0.5 ether, "reason");
    }

    function testReactivateStream() public {
        /* cheats.prank(address(0xb010ca9Be09C382A9f31b79493bb232bCC319f01));
        stream.streamWithdraw(0.5 ether, "reason"); */

        // Lines above would fail currently, so let's re-activate the stream..

        // Not exactly sure why we need to re-init manager role, but here we are..
        cheats.prank((address(me)));
        // Gives self manager role
        stream.addManager(me);

        cheats.prank((address(me)));
        stream.enableStream(
            address(0xb010ca9Be09C382A9f31b79493bb232bCC319f01),
            0.5 ether,
            1296000,
            true
        );

        cheats.prank(address(0xb010ca9Be09C382A9f31b79493bb232bCC319f01));
        stream.streamWithdraw(0.5 ether, "reason");
        // Make sure balance is updating properly
        assertEq(
            stream.streamBalance(0xb010ca9Be09C382A9f31b79493bb232bCC319f01),
            0
        );
    }

    function testFailWithdrawTooMuchTooSoon() public {
        hevm.prank(address(0xa8B3478A436e8B909B5E9636090F2B15f9B311e7));

        stream.streamWithdraw(0.5 ether, "reason");

        // just testing logging through ds-test
        /* emit log_address(0xa8B3478A436e8B909B5E9636090F2B15f9B311e7); */

        // try withdrawing again *almost* 2 weeks into the future (fails)
        hevm.prank(address(0xa8B3478A436e8B909B5E9636090F2B15f9B311e7));
        cheats.warp(1642366799);
        stream.streamWithdraw(0.5 ether, "reason");
    }

    function testFailWithdrawTooMuch(uint256 amount) public {
        hevm.prank(address(0xa8B3478A436e8B909B5E9636090F2B15f9B311e7));
        cheats.assume(amount > 0.5 ether);
        stream.streamWithdraw(amount, "reason");

        /* // try withdrawing again
        stream.streamWithdraw(0.5 ether, "reason"); */
    }

    // Will pass as 0x is not beneficiary
    function testFailStreamWithdraw2() public {
        hevm.prank(address(0));
        stream.streamWithdraw(0.5 ether, "reason");
    }
}
