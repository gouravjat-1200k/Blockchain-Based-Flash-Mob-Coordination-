// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Blockchain-Based Flash Mob Coordination
 * @dev Smart contract for organizing and coordinating flash mob events on blockchain
 */
contract Project {
    
    struct FlashMob {
        uint256 id;
        address organizer;
        string eventName;
        string location;
        uint256 eventTime;
        uint256 revealTime;
        uint256 participantCount;
        bool isActive;
        bool isRevealed;
        mapping(address => bool) participants;
        mapping(address => bool) hasConfirmed;
    }
    
    uint256 public flashMobCounter;
    mapping(uint256 => FlashMob) public flashMobs;
    mapping(address => uint256[]) public organizerEvents;
    mapping(address => uint256[]) public participantEvents;
    
    event FlashMobCreated(
        uint256 indexed id,
        address indexed organizer,
        string eventName,
        uint256 revealTime,
        uint256 eventTime
    );
    
    event ParticipantJoined(
        uint256 indexed flashMobId,
        address indexed participant
    );
    
    event LocationRevealed(
        uint256 indexed flashMobId,
        string location,
        uint256 eventTime
    );
    
    event ParticipantConfirmed(
        uint256 indexed flashMobId,
        address indexed participant
    );
    
    modifier onlyOrganizer(uint256 _flashMobId) {
        require(
            flashMobs[_flashMobId].organizer == msg.sender,
            "Only organizer can call this function"
        );
        _;
    }
    
    modifier flashMobExists(uint256 _flashMobId) {
        require(
            _flashMobId < flashMobCounter,
            "Flash mob does not exist"
        );
        _;
    }
    
    /**
     * @dev Create a new flash mob event
     * @param _eventName Name of the flash mob event
     * @param _revealTime Timestamp when location will be revealed
     * @param _eventTime Timestamp when the flash mob will occur
     */
    function createFlashMob(
        string memory _eventName,
        uint256 _revealTime,
        uint256 _eventTime
    ) public returns (uint256) {
        require(_revealTime > block.timestamp, "Reveal time must be in the future");
        require(_eventTime > _revealTime, "Event time must be after reveal time");
        require(bytes(_eventName).length > 0, "Event name cannot be empty");
        
        uint256 newFlashMobId = flashMobCounter;
        FlashMob storage newFlashMob = flashMobs[newFlashMobId];
        
        newFlashMob.id = newFlashMobId;
        newFlashMob.organizer = msg.sender;
        newFlashMob.eventName = _eventName;
        newFlashMob.revealTime = _revealTime;
        newFlashMob.eventTime = _eventTime;
        newFlashMob.isActive = true;
        newFlashMob.isRevealed = false;
        newFlashMob.participantCount = 0;
        
        organizerEvents[msg.sender].push(newFlashMobId);
        flashMobCounter++;
        
        emit FlashMobCreated(
            newFlashMobId,
            msg.sender,
            _eventName,
            _revealTime,
            _eventTime
        );
        
        return newFlashMobId;
    }
    
    /**
     * @dev Join a flash mob event as a participant
     * @param _flashMobId ID of the flash mob to join
     */
    function joinFlashMob(uint256 _flashMobId) 
        public 
        flashMobExists(_flashMobId) 
    {
        FlashMob storage flashMob = flashMobs[_flashMobId];
        
        require(flashMob.isActive, "Flash mob is not active");
        require(!flashMob.participants[msg.sender], "Already joined this flash mob");
        require(block.timestamp < flashMob.eventTime, "Flash mob event has already occurred");
        
        flashMob.participants[msg.sender] = true;
        flashMob.participantCount++;
        participantEvents[msg.sender].push(_flashMobId);
        
        emit ParticipantJoined(_flashMobId, msg.sender);
    }
    
    /**
     * @dev Reveal the location of the flash mob (only organizer can call)
     * @param _flashMobId ID of the flash mob
     * @param _location Location details for the flash mob
     */
    function revealLocation(uint256 _flashMobId, string memory _location)
        public
        flashMobExists(_flashMobId)
        onlyOrganizer(_flashMobId)
    {
        FlashMob storage flashMob = flashMobs[_flashMobId];
        
        require(flashMob.isActive, "Flash mob is not active");
        require(!flashMob.isRevealed, "Location already revealed");
        require(block.timestamp >= flashMob.revealTime, "Not time to reveal yet");
        require(bytes(_location).length > 0, "Location cannot be empty");
        
        flashMob.location = _location;
        flashMob.isRevealed = true;
        
        emit LocationRevealed(_flashMobId, _location, flashMob.eventTime);
    }
    
    /**
     * @dev Confirm participation after location is revealed
     * @param _flashMobId ID of the flash mob
     */
    function confirmParticipation(uint256 _flashMobId)
        public
        flashMobExists(_flashMobId)
    {
        FlashMob storage flashMob = flashMobs[_flashMobId];
        
        require(flashMob.participants[msg.sender], "Not a participant");
        require(flashMob.isRevealed, "Location not revealed yet");
        require(!flashMob.hasConfirmed[msg.sender], "Already confirmed");
        require(block.timestamp < flashMob.eventTime, "Event has already occurred");
        
        flashMob.hasConfirmed[msg.sender] = true;
        
        emit ParticipantConfirmed(_flashMobId, msg.sender);
    }
    
    /**
     * @dev Get flash mob details
     * @param _flashMobId ID of the flash mob
     */
    function getFlashMobDetails(uint256 _flashMobId)
        public
        view
        flashMobExists(_flashMobId)
        returns (
            address organizer,
            string memory eventName,
            string memory location,
            uint256 revealTime,
            uint256 eventTime,
            uint256 participantCount,
            bool isActive,
            bool isRevealed
        )
    {
        FlashMob storage flashMob = flashMobs[_flashMobId];
        return (
            flashMob.organizer,
            flashMob.eventName,
            flashMob.location,
            flashMob.revealTime,
            flashMob.eventTime,
            flashMob.participantCount,
            flashMob.isActive,
            flashMob.isRevealed
        );
    }
    
    /**
     * @dev Check if an address is a participant
     * @param _flashMobId ID of the flash mob
     * @param _participant Address to check
     */
    function isParticipant(uint256 _flashMobId, address _participant)
        public
        view
        flashMobExists(_flashMobId)
        returns (bool)
    {
        return flashMobs[_flashMobId].participants[_participant];
    }
    
    /**
     * @dev Check if a participant has confirmed
     * @param _flashMobId ID of the flash mob
     * @param _participant Address to check
     */
    function hasConfirmedParticipation(uint256 _flashMobId, address _participant)
        public
        view
        flashMobExists(_flashMobId)
        returns (bool)
    {
        return flashMobs[_flashMobId].hasConfirmed[_participant];
    }
    
    /**
     * @dev Get events organized by an address
     * @param _organizer Address of the organizer
     */
    function getOrganizerEvents(address _organizer)
        public
        view
        returns (uint256[] memory)
    {
        return organizerEvents[_organizer];
    }
    
    /**
     * @dev Get events joined by a participant
     * @param _participant Address of the participant
     */
    function getParticipantEvents(address _participant)
        public
        view
        returns (uint256[] memory)
    {
        return participantEvents[_participant];
    }
}
