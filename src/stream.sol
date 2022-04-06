//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "./../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "./../lib/openzeppelin-contracts/contracts/access/AccessControl.sol";

error NotYourStream();
error NotEnoughBalance();
error SendMore();
error IncreaseByMore();
error CantWithdrawToBurn();
error StreamDisabled();

/// @title Simple Stream Contract
/// @author ghostffcode, jaxcoder
/// @notice the meat and potatoes of the stream
contract NotSimpleStream is Ownable, AccessControl {

    event Withdraw(address indexed to, uint256 amount, string reason);
    event Deposit(address indexed from, uint256 amount); 

    /* mapping(address => uint256) balances; */
    mapping(address => uint256) caps;
    mapping(address => uint256) frequencies;
    mapping(address => uint256) last;
    mapping(address => uint256) payouts;
    mapping(address => bool) disabled;

    address[] public users;

    IERC20 public dToken;

    constructor(
        address _owner,
        address[] memory _addresses,
        uint256[] memory _caps,
        uint256[] memory _frequency,
        bool[] memory _startsFull,
        IERC20 _dToken
    ) {
        transferOwnership(_owner);
        for (uint256 i = 0; i < _addresses.length; ++i) {
            caps[_addresses[i]] = _caps[i];
            frequencies[_addresses[i]] = _frequency[i];
            users.push(_addresses[i]);

            if (_startsFull[i] == true) {
                last[_addresses[i]] = block.timestamp - _frequency[i];
            } else {
                last[_addresses[i]] = block.timestamp;
            }
            dToken = _dToken;
        }
    }

    /// @dev add a stream for user
    function addStream(
        address _beneficiary,
        uint256 _cap,
        uint256 _frequency,
        bool _startsFull
    ) public onlyOwner {
        caps[_beneficiary] = _cap;
        frequencies[_beneficiary] = _frequency;
        users.push(_beneficiary);

        if (_startsFull == true) {
                last[_beneficiary] = block.timestamp - _frequency;
            } else {
                last[_beneficiary] = block.timestamp;
            }
    }

    /// @dev Transfers remaining balance and disables stream
    function disableStream(
        address _beneficiary
    ) public onlyOwner {

        uint256 totalAmount = streamBalance(_beneficiary);

        uint256 cappedLast = block.timestamp - frequencies[_beneficiary];
        if (last[_beneficiary] < cappedLast) {
            last[_beneficiary] = cappedLast;
        }
        last[_beneficiary] =
            last[_beneficiary] +
            (((block.timestamp - last[_beneficiary]) * totalAmount) /
                totalAmount);

        require(dToken.transfer(_beneficiary, totalAmount), "Transfer failed");
        
        disabled[_beneficiary] == true;
        caps[_beneficiary] == 0;
    }

    /// @dev Reactivates a stream for user
    function enableStream(
        address _beneficiary,
        uint256 _cap,
        uint256 _frequency,
        bool _startsFull
    ) public onlyOwner {

        caps[_beneficiary] = _cap;
            frequencies[_beneficiary] = _frequency;

        if (_startsFull == true) {
                last[_beneficiary] = block.timestamp - _frequency;
            } else {
                last[_beneficiary] = block.timestamp;
            }

        disabled[_beneficiary] == false;
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
        string memory reason,
        address beneficiary
    ) external {
        if (msg.sender != beneficiary) revert NotYourStream();
        if (beneficiary == address(0)) revert CantWithdrawToBurn();
        if (disabled[beneficiary] == true ) revert StreamDisabled();
        
        uint256 totalAmountCanWithdraw = streamBalance(beneficiary);
        if (totalAmountCanWithdraw < amount ) revert NotEnoughBalance();

        uint256 cappedLast = block.timestamp - frequencies[beneficiary];
        if (last[beneficiary] < cappedLast) {
            last[beneficiary] = cappedLast;
        }
        last[beneficiary] =
            last[beneficiary] +
            (((block.timestamp - last[beneficiary]) * amount) /
                totalAmountCanWithdraw);
        emit Withdraw(beneficiary, amount, reason);
        require(dToken.transfer(beneficiary, amount), "Transfer failed");
    }

    /// @notice Explain to an end user what this does
    /// @dev Explain to a developer any extra details
    /// @param  value the amount of the deposit
    function streamDeposit(uint256 value) external {
        require(
            dToken.transferFrom(_msgSender(), address(this), value),
            "Transfer of tokens is not approved or insufficient funds"
        );
         emit Deposit(_msgSender(), value); 
    }

    /// @dev Increase the cap of the stream
    /// @param _increase how much to increase the cap
    function increaseCap(uint256 _increase, address beneficiary)
        public
        onlyOwner
    {
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
