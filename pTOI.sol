pragma solidity ^0.5.0;

import "./Token.sol";
import "./SafeMath.sol";
import "./IERC20.sol";

contract pTOI is Token {
    constructor(IERC20 _token, address _dev) public {
        token = _token;
        devAddress = _dev;
        owner = msg.sender;
    }

    using SafeMath for uint256;
    /**
     * @notice address of contract
     */
    struct User {
        uint256 payouts;
        uint256 deposit_amount;
        uint256 deposit_payouts;
        uint40 deposit_time;
        uint256 total_deposits;
        uint256 total_payouts;
    }
    mapping(address => User) public users;
    address public devAddress;
    address public contractAddress = address(this);
    /**
     * @notice address of owener
     */
    address payable owner;
    /**
     * @notice total stake holders.
     */
    address[] public stakeholders;

    /**
     * @notice The stakes for each stakeholder.
     */

    IERC20 public token;
    //========Modifiers========
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    //=========**============

    // ---------- STAKES ----------
    /**
     * @notice A method for a stakeholder to create a stake.
     * @param _stake The size of the stake to be created.
     */
    function stakeTOI(uint256 _stake) public {
        uint256 _amount = users[msg.sender].deposit_amount.div(25000);
        require(
            token.balanceOf(msg.sender) >= _stake,
            "You dont have enough coin to stake!"
        );
        if (users[msg.sender].deposit_time > 0) {
            require(
                users[msg.sender].payouts >= this.maxPayoutOf(_amount),
                "Deposit already exists"
            );
        }
        token.transferFrom(msg.sender, address(this), _stake);
        token.transfer(devAddress, (_stake * 3) / 100);
        users[msg.sender].deposit_time = uint40(block.timestamp);
        users[msg.sender].payouts = 0;
        users[msg.sender].deposit_payouts = 0;
        users[msg.sender].total_deposits += _stake;
        if (users[msg.sender].deposit_amount == 0) addStakeholder(msg.sender);
        users[msg.sender].deposit_amount = _stake;
    }

    //------------Add Stake holders----------
    /**
     * @notice A method to add a stakeholder.
     * @param _stakeholder The stakeholder to add.
     */
    function addStakeholder(address _stakeholder) private {
        (bool _isStakeholder, ) = isStakeholder(_stakeholder);
        if (!_isStakeholder) stakeholders.push(_stakeholder);
    }

    // ---------- STAKEHOLDERS ----------

    /**
     * @notice A method to check if an address is a stakeholder.
     * @param _address The address to verify.
     * @return bool, uint256 Whether the address is a stakeholder,
     * and if so its position in the stakeholders array.
     */
    function isStakeholder(address _address)
        public
        view
        returns (bool, uint256)
    {
        for (uint256 s = 0; s < stakeholders.length; s += 1) {
            if (_address == stakeholders[s]) return (true, s);
        }
        return (false, 0);
    }

    /**
     * @notice A simple method that calculates the rewards for each stakeholder.
     */
    function maxPayoutOf(uint256 _amount) external pure returns (uint256) {
        return ((_amount * 150) / 100);
    }

    function payoutOf(address _addr)
        external
        view
        returns (uint256 payout, uint256 max_payout)
    {
        uint256 _amount = (users[_addr].deposit_amount.div(25000));
        max_payout = this.maxPayoutOf(_amount);

        if (users[_addr].deposit_payouts < max_payout) {
            payout = (((_amount *
                ((block.timestamp - users[_addr].deposit_time) / 1 days)) /
                10) - users[_addr].deposit_payouts);
            if (users[_addr].deposit_payouts + payout > max_payout) {
                payout = max_payout - users[_addr].deposit_payouts;
            }
        }
    }

    /**
     * @notice A method to allow a stakeholder to withdraw his rewards.
     */
    function withdrawReward() public {
        (uint256 to_payout, uint256 max_payout) = this.payoutOf(msg.sender);
        require(users[msg.sender].payouts < max_payout, "Full payouts");
        // Deposit payout
        if (to_payout > 0) {
            if (users[msg.sender].payouts + to_payout > max_payout) {
                to_payout = max_payout - users[msg.sender].payouts;
            }

            users[msg.sender].deposit_payouts += to_payout;
            users[msg.sender].payouts += to_payout;
        }
        uint256 burnPercentage = (to_payout * 3) / 100;
        _transfer(address(this), msg.sender, to_payout - burnPercentage);
        _burn(msg.sender, burnPercentage);
        (bool _isStakeholder, uint256 s) = isStakeholder(msg.sender);
        users[msg.sender].total_payouts += to_payout;
    }
}
