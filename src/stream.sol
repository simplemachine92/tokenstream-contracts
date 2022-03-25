//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "./../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "./../lib/openzeppelin-contracts/contracts/access/AccessControl.sol";

error NotYourStream();
error NotEnoughBalance();
error SendMore();
error IncreaseByMore();

/// @title Simple Stream Contract
/// @author ghostffcode, jaxcoder
/// @notice the meat and potatoes of the stream
contract NotSimpleStream is Ownable, AccessControl {
    /* event Withdraw(address indexed to, uint256 amount, string reason);
    event Deposit(address indexed from, uint256 amount, string reason); */

    mapping(address => uint256) balances;
    mapping(address => uint256) caps;
    mapping(address => uint256) frequencies;
    mapping(address => uint256) last;

    /* address payable public toAddress; */
    // = payable(0xD75b0609ed51307E13bae0F9394b5f63A7f8b6A1);
    /* uint256 public cap; // = 0.5 ether;
    uint256 public frequency; // 1296000 seconds == 2 weeks;
    uint256 public last; */
    // stream starts empty (last = block.timestamp) or full (block.timestamp - frequency)
    IERC20 public dToken;

    constructor(
        address[] memory _addresses,
        uint256[] memory _caps,
        uint256[] memory _frequency,
        bool[] memory _startsFull,
        IERC20 _dToken
    ) {
        /* transferOwnership(msg.sender); */
        for (uint256 i = 0; i < _addresses.length; ++i) {
            caps[_addresses[i]] = _caps[i];
            frequencies[_addresses[i]] = _frequency[i];

            if (_startsFull[i] == true) {
                last[_addresses[i]] = block.timestamp - _frequency[i];
            } else {
                last[_addresses[i]] = block.timestamp;
            }
            dToken = _dToken;
        }
        /* toAddress = _addresses;
        cap = _cap;
        frequency = _frequency;
        gtc = _gtc; */
        /* if (_startsFull) {
            last = block.timestamp - frequency;
        } else {
            last = block.timestamp;
        } */
    }

    /// @dev get the balance of a stream
    /// @return the balance of the stream
    function streamBalance(address _beneficiary) public view returns (uint256) {
        if (block.timestamp - last[_beneficiary] > frequencies[_beneficiary]) {
            return caps[_beneficiary];
        }
        return
            (caps[_beneficiary] * (block.timestamp - last[_beneficiary])) /
            frequencies[_beneficiary];
    }

    /// @dev withdraw from a stream
    /// @param amount amount of withdraw
    function streamWithdraw(
        uint256 amount,
        /* string memory reason, */
        address beneficiary
    ) external {
        /* if (msg.sender != beneficiary) revert NotYourStream(); */
        require(_msgSender() == beneficiary, "this stream is not for you ser");
        require(beneficiary != address(0), "cannot send to zero address");
        uint256 totalAmountCanWithdraw = streamBalance(beneficiary);
        require(totalAmountCanWithdraw >= amount, "not enough in the stream");
        /* if (totalAmountCanWithdraw < amount) revert NotEnoughBalance(); */
        uint256 cappedLast = block.timestamp - frequencies[beneficiary];
        if (last[beneficiary] < cappedLast) {
            last[beneficiary] = cappedLast;
        }
        last[beneficiary] =
            last[beneficiary] +
            (((block.timestamp - last[beneficiary]) * amount) /
                totalAmountCanWithdraw);
        /* emit Withdraw(beneficiary, amount, reason); */
        require(dToken.transfer(beneficiary, amount), "Transfer failed");
    }

    /// @notice Explain to an end user what this does
    /// @dev Explain to a developer any extra details
    /// @param  value the amount of the deposit
    function streamDeposit(uint256 value, address beneficiary) external {
        /* require(value >= caps[beneficiary] / 10, "Not big enough, sorry."); */
        if (value >= caps[beneficiary] / 10) revert SendMore();
        require(
            dToken.transferFrom(_msgSender(), address(this), value),
            "Transfer of tokens is not approved or insufficient funds"
        );
        /* emit Deposit(_msgSender(), value, reason); */
    }

    /// @dev Increase the cap of the stream
    /// @param _increase how much to increase the cap
    function increaseCap(uint256 _increase, address beneficiary)
        public
        onlyOwner
    {
        /* require(_increase > 0, "Increase cap by more than 0"); */
        if (_increase == 0) revert IncreaseByMore();
        caps[beneficiary] = caps[beneficiary] + _increase;
    }

    /// @dev Update the frequency of a stream
    /// @param _frequency the new frequency
    function updateFrequency(uint256 _frequency, address beneficiary)
        public
        onlyOwner
    {
        require(_frequency > 0, "Must be greater than 0");
        if (_frequency == 0) revert IncreaseByMore();
        frequencies[beneficiary] = _frequency;
    }
}
