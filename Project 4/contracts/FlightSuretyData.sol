pragma solidity >=0.4.25;

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract FlightSuretyData {
    using SafeMath for uint256;

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    address private contractOwner; // Account used to deploy contract
    bool private operational = true; // Blocks all state changes throughout the contract if false
    mapping(address => Airline) private airlines;

    struct Airline {
        bool isRegistered;
        bool isFunded;
        address[] votes;
        uint256 balance;
    }

    uint256 private operationalAirlinesCount = 0;

    /********************************************************************************************/
    /*                                       EVENT DEFINITIONS                                  */
    /********************************************************************************************/

    /**
     * @dev Constructor
     *      The deploying account becomes contractOwner
     */
    constructor() public {
        contractOwner = msg.sender;
        airlines[msg.sender] = Airline(true, false, new address[](0), 0);
        operationalAirlinesCount++;
    }

    /********************************************************************************************/
    /*                                       FUNCTION MODIFIERS                                 */
    /********************************************************************************************/

    // Modifiers help avoid duplication of code. They are typically used to validate something
    // before a function is allowed to be executed.

    /**
     * @dev Modifier that requires the "operational" boolean variable to be "true"
     *      This is used on all state changing functions to pause the contract in
     *      the event there is an issue that needs to be fixed
     */
    modifier requireIsOperational() {
        require(operational, "Contract is currently not operational");
        _; // All modifiers require an "_" which indicates where the function body will be added
    }

    /**
     * @dev Modifier that requires the "ContractOwner" account to be the function caller
     */
    modifier requireContractOwner() {
        require(msg.sender == contractOwner, "Caller is not contract owner");
        _;
    }

    modifier requireAirlineRegistered(address airlineAddress) {
        require(isAirlineRegistered(airlineAddress), "Only existing airlines can register airlines");
        _;
    }

    modifier requireAirlineFunded(address airlineAddress) {
        require(isAirlineFunded(airlineAddress), "Only funded airlines can participate");
        _;
    }

    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/

    /**
     * @dev Get operating status of contract
     *
     * @return A bool that is the current operating status
     */
    function isOperational() public view returns (bool) {
        return operational;
    }

    /**
     * @dev Sets contract operations on/off
     *
     * When operational mode is disabled, all write transactions except for this one will fail
     */
    function setOperatingStatus(bool mode) external requireContractOwner {
        operational = mode;
    }

    function isAirlineRegistered (address airlineAddress) returns (bool) {
        return airlines[airlineAddress].isRegistered;
    }

    function isAirlineFunded (address airlineAddress) returns (bool) {
        return airlines[airlineAddress].isFunded;
    }

    function isAirlineValid (address airlineAddress) returns (bool) {
        return isAirlineFunded(airlineAddress) && isAirlineRegistered(airlineAddress);
    }

    function getAirlineCount () returns (uint256) {
        return operationalAirlinesCount;
    }

    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/

    /**
     * @dev Add an airline to the registration queue
     *      Can only be called from FlightSuretyApp contract
     *
     */
    function registerAirline(address newAirlineAddress, address creator, bool requiresVotes) 
        external
        requireIsOperational
        requireAirlineRegistered(creator)
        requireAirlineFunded(creator) {
        if (requiresVotes) {
            airlines[creator] = Airline(false, false, new address[](0), 0);
        } else {
            airlines[creator] = Airline(true, false, new address[](0), 0);
        }
        operationalAirlinesCount++;
    }

    function voteForAirline(address airlineAddress, address creator)
        external
        requireIsOperational
        requireAirlineRegistered(creator)
        requireAirlineFunded(creator)
        returns (uint256 length) {

        bool isDuplicateVote = false;

        for (uint256 i = 0; i < airlines[airlineAddress].votes.length; i++) {
            if (airlines[airlineAddress].votes[i] == creator) {
                isDuplicateVote = true;
                break;
            }
        }

        require(isDuplicateVote, "Duplicated vote detected!");

        airlines[airlineAddress].votes.push(msg.sender);

        if (airlines[airlineAddress].votes.length >= (operationalAirlinesCount.div(2))) {
            airlines[airlineAddress].isRegistered = true;
        }
        return airlines[airlineAddress].votes.length;
    }

    /**
     * @dev Buy insurance for a flight
     *
     */
    function buy() external payable {}

    /**
     *  @dev Credits payouts to insurees
     */
    function creditInsurees() external pure {}

    /**
     *  @dev Transfers eligible payout funds to insuree
     *
     */
    function pay() external pure {}

    /**
     * @dev Initial funding for the insurance. Unless there are too many delayed flights
     *      resulting in insurance payouts, the contract should be self-sustaining
     *
     */
    function fund(address airlineToFund, uint256 balance)
        public
        payable
        requireIsOperational
        requireAirlineRegistered(airlineToFund) {
        airlines[airlineToFund].isFunded = true;
        airlines[airlineToFund].balance = airlines[airlineToFund].balance.add(balance);
    }

    function getFlightKey(
        address airline,
        string memory flight,
        uint256 timestamp
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }

    /**
     * @dev Fallback function for funding smart contract.
     *
     */
    // function() external payable {
    //     // fund();
    // }
}
