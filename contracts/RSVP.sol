//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";

// @title A program that lets people pay a small amount, RSVP for an event,
// and if they don’t show up then everyone who did shares in the reward.
// A person can create and event, and check people in.
// If someone RSVPs but doesn't get checked in they lose their staked ETH.

contract RSVP {
    address  owner;
    uint256 totalEvents;
    uint256 eventIds = 1;

    mapping(uint => Event) internal events;

    event NewEventCreated (string indexed _eventName, uint256 indexed _registerPrice, uint256 indexed _registrationDays);
    event SignUpCompleted (uint256 _amount, uint56 indexed _eventId);
    event PayoutComplete (uint256 indexed _eventId);
    event CheckedIn (address payable indexed _checkInAddress, uint256 indexed _eventId);
    event BatchCheckedIn (address payable[] indexed _checkInAddresses, uint256 indexed _eventId);

    // @notice This struct defines an event
    // @param `eventName` is the name of any one event
    // @param `maxNumber` is the max number of people allowed in an event
    // @param `registerPrice` is how much it costs to register for an event
    // @param `registrationDays` specifies for how many days registration is open
    // @param `amountCollected` is how much has been collected from rsvp and will be the total payout amount
    // @param `eventOwner` is the address of the event creator
    // @param `allAddress` is an array of addresses that keeps track of all rsvp'd addresses
    // @param `checkedInAddressed` is an array of addresses that have been checked in for any one event
    struct Event {
        string eventName;
        uint256 maxNumber;
        uint256 registerPrice;
        uint256 registrationDays;
        uint256 amountCollected;
        address eventOwner;
        address[] allAddresses;
        address payable[] checkedInAddresses;
    }
    Event eventStruct;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require (msg.sender == owner, "Caller is not owner");
        _;
    }

    // @notice This is the function for creating for a new event, all the parameters have been defined above the 'Event' struct
    // @dev make sure to limit the amount of events to 32 bits, although it should never exceed this many events
    function createNewEvent (string memory _eventName, uint256 _maxNumber, uint256 _registerPrice, uint256 _registrationDays, address _eventOwner) public returns(uint) {
        require(totalEvents != eventIds, 'Expected an inctemented Id number');
        eventStruct.eventName = _eventName;
        eventStruct.maxNumber = _maxNumber;
        eventStruct.registerPrice = _registerPrice;
        eventStruct.registrationDays = _registrationDays;
        eventStruct.amountCollected = 0;
        eventStruct.eventOwner = _eventOwner;

        events[eventIds] = eventStruct;
        return(eventIds);

        totalEvents++;
        eventIds++;
        emit NewEventCreated (_eventName, _registerPrice, _registrationDays);
    }

    // @param `_eventId` is an event Id that will be used for lookup
    // @notice Function returns an event by its Id
    function getEvent(uint256 _eventId) public view returns(string memory) {
        return (events[_eventId].eventName);
    }

    // @param `_checkInAddress` is an address that is to be checked in
    // @param `_eventId` is an event Id that is to be used for reference within the function
    // @notice This function is for checking people in, and requires that they are have paid first
    // @dev returns true upon completion
    // @dev make sure is requires that they have paid first
    function checkIn (address payable _checkInAddress, uint256 _eventId) public onlyOwner returns(bool) {
        for (uint256 i=0; i <= events[_eventId].checkedInAddresses.length; i++) {
            require(events[_eventId].checkedInAddresses[i] != _checkInAddress);
        }
        events[_eventId].checkedInAddresses.push(_checkInAddress);
        return(true);

        emit CheckedIn(_checkInAddress, _eventId);
    }

    // @notice Allows for the event owner to check in multiple users at once, which allows for saving gas
    //         by avoiding multiple individual calls. However, the time might come for multiple individual calls
    //         so we keep the `checkIn` function in case.
    function batchCheckIn (address payable[] memory _checkInAddresses, uint256 _eventId) public onlyOwner {
        for (uint i=0; i <= _checkInAddresses.length; i++) {
            for (uint256 i=0; i <= events[_eventId].checkedInAddresses.length; i++) {
                require(events[_eventId].checkedInAddresses[i] != _checkInAddresses[i]);
            }
        }
        for (uint i=0; i <= _checkInAddresses.length; i++) {
            events[_eventId].checkedInAddresses.push(_checkInAddresses[i]);
        }

        emit BatchCheckedIn(_checkInAddresses, _eventId);
    }

    // @param `_amount` is the amount that is being sent with the message
    // @param `_eventId` is the event Id that will be used for reference inside the function
    // @notice This is the function for signing up for an event, and must pay at least the amount as defined by `registerPrice`
    function rsvp (uint256 _amount, uint56 _eventId) public payable {
        require(_amount > events[_eventId].registerPrice * 1000000000000000000 wei, 'Did not pay enough to RSVP');
        events[_eventId].allAddresses.push(msg.sender);
        events[_eventId].amountCollected += _amount;

        events[_eventId].amountCollected += _amount;

        emit SignUpCompleted(_amount, _eventId);
    }

    // @param `_eventId` is an event Id that will be used for lookup
    // @notice This is the function for paying out all the attendees of an event and can only be called by the owner
    function payout (uint256 _eventId) public payable onlyOwner {
        for(uint256 i=0; i < events[_eventId].checkedInAddresses.length; i++){
            events[_eventId].checkedInAddresses[i].transfer((events[_eventId].amountCollected) / events[_eventId].checkedInAddresses.length);
        }

        emit PayoutComplete (_eventId);
    }
}
