// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

interface IPepperPassport {
    function mintPassport(
        address farmer,
        string memory lotId,
        string memory variety,
        uint256 quantity,
        string memory harvestDate,
        string memory origin,
        bytes32 certificateHash,
        string memory metadataURI
    ) external returns (uint256);
    
    function addProcessingLog(
        uint256 tokenId,
        string memory stage,
        string memory description,
        string memory location
    ) external;
    
    function lotIdToTokenId(string memory lotId) external view returns (uint256);
    function ownerOf(uint256 tokenId) external view returns (address);
    function transferFrom(address from, address to, uint256 tokenId) external;
}

/**
 * @title PepperAuction
 * @dev Smart contract for live pepper auctions with escrow and compliance
 * @notice Part of SmartPepper blockchain traceability system with NFT passport integration
 */
contract PepperAuction is Ownable, ReentrancyGuard, Pausable {
    
    // Enums
    enum AuctionStatus { Created, Active, Ended, Settled, Cancelled }
    enum LotStatus { Available, InAuction, Sold, Shipped, Delivered }
    
    // Structs
    struct PepperLot {
        string lotId;
        address farmer;
        string variety;
        uint256 quantity; // in kg
        string quality;
        string harvestDate;
        bytes32 certificateHash; // IPFS hash of certificate
        LotStatus status;
        uint256 createdAt;
    }
    
    struct Auction {
        uint256 auctionId;
        string lotId;
        address farmer;
        uint256 startPrice;
        uint256 reservePrice;
        uint256 currentBid;
        address currentBidder;
        uint256 startTime;
        uint256 endTime;
        AuctionStatus status;
        bool compliancePassed;
        uint256 bidCount;
        uint256 escrowAmount;
    }
    
    struct Bid {
        address bidder;
        uint256 amount;
        uint256 timestamp;
    }
    
    // State variables
    IPepperPassport public passportContract;
    uint256 private auctionCounter;
    uint256 public platformFeePercent = 2; // 2% platform fee
    uint256 public minBidIncrement = 100; // Minimum bid increment in wei
    
    mapping(string => PepperLot) public lots;
    mapping(uint256 => Auction) public auctions;
    mapping(uint256 => Bid[]) public auctionBids;
    mapping(address => uint256) public escrowBalances;
    mapping(string => bool) public lotExists;
    
    // Events
    event LotCreated(
        string indexed lotId,
        address indexed farmer,
        string variety,
        uint256 quantity,
        bytes32 certificateHash
    );
    
    event AuctionCreated(
        uint256 indexed auctionId,
        string indexed lotId,
        address indexed farmer,
        uint256 startPrice,
        uint256 reservePrice,
        uint256 endTime
    );
    
    event BidPlaced(
        uint256 indexed auctionId,
        address indexed bidder,
        uint256 amount,
        uint256 timestamp
    );
    
    event AuctionEnded(
        uint256 indexed auctionId,
        address indexed winner,
        uint256 finalPrice
    );
    
    event AuctionSettled(
        uint256 indexed auctionId,
        address indexed farmer,
        address indexed buyer,
        uint256 amount,
        uint256 platformFee
    );
    
    event EscrowDeposited(
        address indexed buyer,
        uint256 amount
    );
    
    event EscrowReleased(
        address indexed buyer,
        uint256 amount
    );
    
    event ComplianceChecked(
        string indexed lotId,
        bool passed,
        uint256 timestamp
    );
    
    event PassportLinked(
        string indexed lotId,
        uint256 indexed tokenId,
        address indexed farmer
    );
    
    // Modifiers
    modifier onlyFarmer(string memory lotId) {
        require(lots[lotId].farmer == msg.sender, "Only farmer can perform this action");
        _;
    }
    
    modifier auctionExists(uint256 auctionId) {
        require(auctionId < auctionCounter, "Auction does not exist");
        _;
    }
    
    modifier auctionActive(uint256 auctionId) {
        require(auctions[auctionId].status == AuctionStatus.Active, "Auction not active");
        require(block.timestamp < auctions[auctionId].endTime, "Auction ended");
        _;
    }
    
    constructor() Ownable(msg.sender) {
        auctionCounter = 0;
    }
    
    /**
     * @notice Set the NFT Passport contract address
     * @param _passportContract Address of PepperPassport contract
     */
    function setPassportContract(address _passportContract) external onlyOwner {
        require(_passportContract != address(0), "Invalid passport contract");
        passportContract = IPepperPassport(_passportContract);
    }
    
    /**
     * @notice Create a new pepper lot with NFT passport
     * @param lotId Unique identifier for the lot
     * @param farmer Address of the farmer who owns the lot
     * @param variety Type of pepper (e.g., "Tellicherry", "Malabar")
     * @param quantity Quantity in kg
     * @param quality Quality grade (e.g., "Premium", "Grade A")
     * @param harvestDate Date of harvest
     * @param certificateHash IPFS hash of quality certificate
     * @param origin Origin location
     * @param metadataURI IPFS URI for NFT metadata
     */
    function createLot(
        string memory lotId,
        address farmer,
        string memory variety,
        uint256 quantity,
        string memory quality,
        string memory harvestDate,
        bytes32 certificateHash,
        string memory origin,
        string memory metadataURI
    ) external onlyOwner whenNotPaused {
        require(farmer != address(0), "Invalid farmer address");
        require(!lotExists[lotId], "Lot already exists");
        require(quantity > 0, "Quantity must be greater than 0");
        require(certificateHash != bytes32(0), "Certificate hash required");
        
        lots[lotId] = PepperLot({
            lotId: lotId,
            farmer: farmer,
            variety: variety,
            quantity: quantity,
            quality: quality,
            harvestDate: harvestDate,
            certificateHash: certificateHash,
            status: LotStatus.Available,
            createdAt: block.timestamp
        });
        
        lotExists[lotId] = true;
        
        // Mint NFT Passport if contract is set
        if (address(passportContract) != address(0)) {
            uint256 tokenId = passportContract.mintPassport(
                farmer,
                lotId,
                variety,
                quantity,
                harvestDate,
                origin,
                certificateHash,
                metadataURI
            );
            
            emit PassportLinked(lotId, tokenId, farmer);
        }
        
        emit LotCreated(lotId, farmer, variety, quantity, certificateHash);
    }
    
    /**
     * @notice Create an auction for a pepper lot
     * @param lotId The lot to auction
     * @param farmer Address of the farmer who owns the lot
     * @param startPrice Starting price in wei
     * @param reservePrice Minimum acceptable price
     * @param duration Auction duration in seconds
     */
    function createAuction(
        string memory lotId,
        address farmer,
        uint256 startPrice,
        uint256 reservePrice,
        uint256 duration
    ) external onlyOwner whenNotPaused returns (uint256) {
        require(lotExists[lotId], "Lot does not exist");
        require(lots[lotId].farmer == farmer, "Farmer address mismatch");
        require(lots[lotId].status == LotStatus.Available, "Lot not available");
        require(startPrice > 0, "Start price must be greater than 0");
        require(reservePrice >= startPrice, "Reserve price must be >= start price");
        require(duration >= 300, "Minimum auction duration is 5 minutes");
        require(duration <= 7 days, "Maximum auction duration is 7 days");
        
        uint256 auctionId = auctionCounter++;
        uint256 endTime = block.timestamp + duration;
        
        auctions[auctionId] = Auction({
            auctionId: auctionId,
            lotId: lotId,
            farmer: farmer,
            startPrice: startPrice,
            reservePrice: reservePrice,
            currentBid: 0,
            currentBidder: address(0),
            startTime: block.timestamp,
            endTime: endTime,
            status: AuctionStatus.Created,
            compliancePassed: false,
            bidCount: 0,
            escrowAmount: 0
        });
        
        lots[lotId].status = LotStatus.InAuction;
        
        // Add processing log to NFT passport
        if (address(passportContract) != address(0)) {
            uint256 tokenId = passportContract.lotIdToTokenId(lotId);
            if (tokenId != 0) {
                passportContract.addProcessingLog(
                    tokenId,
                    "Auction Created",
                    string(abi.encodePacked("Auction #", uintToString(auctionId), " created")),
                    ""
                );
            }
        }
        
        emit AuctionCreated(auctionId, lotId, farmer, startPrice, reservePrice, endTime);
        
        return auctionId;
    }
    
    /**
     * @notice Set compliance status for an auction
     * @dev Called by backend compliance engine
     * @param auctionId The auction ID
     * @param passed Whether compliance check passed
     */
    function setComplianceStatus(
        uint256 auctionId,
        bool passed
    ) external onlyOwner auctionExists(auctionId) {
        require(
            auctions[auctionId].status == AuctionStatus.Created,
            "Can only set compliance for created auctions"
        );
        
        auctions[auctionId].compliancePassed = passed;
        
        if (passed) {
            auctions[auctionId].status = AuctionStatus.Active;
            
            // Add processing log to NFT passport
            if (address(passportContract) != address(0)) {
                uint256 tokenId = passportContract.lotIdToTokenId(auctions[auctionId].lotId);
                if (tokenId != 0) {
                    passportContract.addProcessingLog(
                        tokenId,
                        "Compliance Passed",
                        "Lot passed compliance checks and auction activated",
                        ""
                    );
                }
            }
        }
        
        emit ComplianceChecked(auctions[auctionId].lotId, passed, block.timestamp);
    }
    
    /**
     * @notice Place a bid on an active auction
     * @param auctionId The auction to bid on
     */
    function placeBid(uint256 auctionId) 
        external 
        payable 
        auctionExists(auctionId) 
        auctionActive(auctionId) 
        nonReentrant 
        whenNotPaused 
    {
        Auction storage auction = auctions[auctionId];
        
        require(msg.sender != auction.farmer, "Farmer cannot bid on own auction");
        require(auction.compliancePassed, "Auction has not passed compliance");
        
        uint256 minBid = auction.currentBid == 0 
            ? auction.startPrice 
            : auction.currentBid + minBidIncrement;
        
        require(msg.value >= minBid, "Bid too low");
        
        // Refund previous bidder
        if (auction.currentBidder != address(0)) {
            escrowBalances[auction.currentBidder] += auction.currentBid;
        }
        
        // Update auction
        auction.currentBid = msg.value;
        auction.currentBidder = msg.sender;
        auction.bidCount++;
        
        // Store bid history
        auctionBids[auctionId].push(Bid({
            bidder: msg.sender,
            amount: msg.value,
            timestamp: block.timestamp
        }));
        
        emit BidPlaced(auctionId, msg.sender, msg.value, block.timestamp);
    }
    
    /**
     * @notice End an auction (can be called by anyone after endTime)
     * @param auctionId The auction to end
     */
    function endAuction(uint256 auctionId) 
        external 
        auctionExists(auctionId) 
        nonReentrant 
    {
        Auction storage auction = auctions[auctionId];
        
        require(auction.status == AuctionStatus.Active, "Auction not active");
        require(block.timestamp >= auction.endTime, "Auction not yet ended");
        
        auction.status = AuctionStatus.Ended;
        
        if (auction.currentBid >= auction.reservePrice && auction.currentBidder != address(0)) {
            // Successful auction - lock funds in escrow
            auction.escrowAmount = auction.currentBid;
            
            emit AuctionEnded(auctionId, auction.currentBidder, auction.currentBid);
        } else {
            // Failed auction - refund bidder if any
            if (auction.currentBidder != address(0)) {
                escrowBalances[auction.currentBidder] += auction.currentBid;
            }
            
            // Return lot to available
            lots[auction.lotId].status = LotStatus.Available;
            
            emit AuctionEnded(auctionId, address(0), 0);
        }
    }
    
    /**
     * @notice Deposit escrow for won auction (must be called by winner)
     * @param auctionId The auction to deposit escrow for
     */
    function depositEscrow(uint256 auctionId) 
        external 
        payable
        auctionExists(auctionId) 
        nonReentrant 
        whenNotPaused 
    {
        Auction storage auction = auctions[auctionId];
        
        require(auction.status == AuctionStatus.Ended, "Auction not ended");
        require(msg.sender == auction.currentBidder, "Only winner can deposit escrow");
        require(auction.escrowAmount == 0, "Escrow already deposited");
        require(auction.currentBid > 0, "No winning bid");
        require(msg.value == auction.currentBid, "Incorrect escrow amount");
        
        // Lock funds in contract
        auction.escrowAmount = msg.value;
        
        emit EscrowDeposited(msg.sender, msg.value);
    }
    
    /**
     * @notice Settle the auction and transfer funds
     * @param auctionId The auction to settle
     */
    function settleAuction(uint256 auctionId) 
        external 
        auctionExists(auctionId) 
        nonReentrant 
        whenNotPaused 
    {
        Auction storage auction = auctions[auctionId];
        
        require(auction.status == AuctionStatus.Ended, "Auction not ended");
        require(auction.currentBidder != address(0), "No winning bid");
        require(auction.escrowAmount > 0, "No escrow to settle");
        
        uint256 totalAmount = auction.escrowAmount;
        uint256 platformFee = (totalAmount * platformFeePercent) / 100;
        uint256 farmerAmount = totalAmount - platformFee;
        
        auction.status = AuctionStatus.Settled;
        auction.escrowAmount = 0;
        lots[auction.lotId].status = LotStatus.Sold;
        
        // Transfer NFT Passport to winner
        if (address(passportContract) != address(0)) {
            uint256 tokenId = passportContract.lotIdToTokenId(auction.lotId);
            if (tokenId != 0) {
                address currentOwner = passportContract.ownerOf(tokenId);
                if (currentOwner == auction.farmer) {
                    passportContract.transferFrom(auction.farmer, auction.currentBidder, tokenId);
                    
                    // Add settlement log to passport
                    passportContract.addProcessingLog(
                        tokenId,
                        "Auction Settled",
                        string(abi.encodePacked("Sold for ", uintToString(totalAmount), " wei")),
                        ""
                    );
                }
            }
        }
        
        // Transfer funds
        (bool farmerSuccess, ) = auction.farmer.call{value: farmerAmount}("");
        require(farmerSuccess, "Farmer payment failed");
        
        (bool feeSuccess, ) = owner().call{value: platformFee}("");
        require(feeSuccess, "Platform fee payment failed");
        
        emit AuctionSettled(
            auctionId,
            auction.farmer,
            auction.currentBidder,
            farmerAmount,
            platformFee
        );
    }
    
    /**
     * @notice Withdraw escrow balance (for outbid bidders)
     */
    function withdrawEscrow() external nonReentrant {
        uint256 amount = escrowBalances[msg.sender];
        require(amount > 0, "No escrow balance");
        
        escrowBalances[msg.sender] = 0;
        
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Withdrawal failed");
        
        emit EscrowReleased(msg.sender, amount);
    }
    
    /**
     * @notice Get all bids for an auction
     * @param auctionId The auction ID
     */
    function getAuctionBids(uint256 auctionId) 
        external 
        view 
        auctionExists(auctionId) 
        returns (Bid[] memory) 
    {
        return auctionBids[auctionId];
    }
    
    /**
     * @notice Get lot details
     * @param lotId The lot ID
     */
    function getLot(string memory lotId) 
        external 
        view 
        returns (PepperLot memory) 
    {
        require(lotExists[lotId], "Lot does not exist");
        return lots[lotId];
    }
    
    /**
     * @notice Update platform fee (owner only)
     * @param newFeePercent New fee percentage (0-10)
     */
    function updatePlatformFee(uint256 newFeePercent) external onlyOwner {
        require(newFeePercent <= 10, "Fee cannot exceed 10%");
        platformFeePercent = newFeePercent;
    }
    
    /**
     * @notice Update minimum bid increment (owner only)
     * @param newIncrement New minimum bid increment
     */
    function updateMinBidIncrement(uint256 newIncrement) external onlyOwner {
        require(newIncrement > 0, "Increment must be greater than 0");
        minBidIncrement = newIncrement;
    }
    
    /**
     * @notice Emergency pause
     */
    function pause() external onlyOwner {
        _pause();
    }
    
    /**
     * @notice Unpause
     */
    function unpause() external onlyOwner {
        _unpause();
    }
    
    /**
     * @notice Get total number of auctions
     */
    function getTotalAuctions() external view returns (uint256) {
        return auctionCounter;
    }
    
    /**
     * @notice Admin function to reset lot status to Available
     * @dev Used when an auction creation failed but changed lot status
     * @param lotId The lot ID to reset
     */
    function resetLotStatus(string memory lotId) external onlyOwner {
        require(lotExists[lotId], "Lot does not exist");
        lots[lotId].status = LotStatus.Available;
        emit LotStatusChanged(lotId, LotStatus.Available);
    }
    
    /**
     * @notice Event emitted when lot status is changed
     */
    event LotStatusChanged(string indexed lotId, LotStatus status);
    
    /**
     * @notice Helper function to convert uint to string
     */
    function uintToString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}
