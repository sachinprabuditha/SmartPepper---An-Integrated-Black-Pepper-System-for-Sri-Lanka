// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title PepperPassport
 * @dev NFT-based digital passport for pepper lot traceability
 * @notice Each NFT represents a unique pepper lot with complete supply chain history
 */
contract PepperPassport is ERC721URIStorage, Ownable, ReentrancyGuard {
    
    // Structs
    struct PassportData {
        string lotId;
        address farmer;
        uint256 createdAt;
        string origin;
        string variety;
        uint256 quantity; // in kg
        string harvestDate;
        bytes32 certificateHash;
        bool isActive;
        // Compliance tracking
        bool complianceApproved;
        address complianceCheckedBy;
        uint256 complianceCheckedAt;
    }
    
    struct ProcessingLog {
        string stage; // e.g., "Harvest", "Drying", "Grading", "Packaging", "Auction", "Shipment"
        string description;
        uint256 timestamp;
        address recordedBy;
        string location;
    }
    
    struct Certification {
        string certType; // e.g., "Organic", "Fumigation", "Export", "Quality"
        string certId;
        string issuedBy;
        uint256 issuedDate;
        uint256 expiryDate;
        bytes32 documentHash; // IPFS hash
        bool isValid;
    }
    
    // State variables
    uint256 private _tokenIdCounter;
    
    // Mappings
    mapping(uint256 => PassportData) public passports;
    mapping(uint256 => ProcessingLog[]) public processingLogs;
    mapping(uint256 => Certification[]) public certifications;
    mapping(string => uint256) public lotIdToTokenId;
    mapping(uint256 => bool) public passportExists;
    
    // Events
    event PassportMinted(
        uint256 indexed tokenId,
        string indexed lotId,
        address indexed farmer,
        string metadataURI
    );
    
    event ProcessingLogAdded(
        uint256 indexed tokenId,
        string stage,
        uint256 timestamp
    );
    
    event CertificationAdded(
        uint256 indexed tokenId,
        string certType,
        string certId,
        uint256 expiryDate
    );
    
    event ComplianceStatusUpdated(
        string indexed lotId,
        uint256 indexed tokenId,
        bool approved,
        address indexed checkedBy,
        uint256 timestamp
    );
    
    event PassportTransferred(
        uint256 indexed tokenId,
        address indexed from,
        address indexed to,
        uint256 timestamp
    );
    
    event CertificationRevoked(
        uint256 indexed tokenId,
        string certType,
        uint256 timestamp
    );
    
    // Constructor
    constructor() ERC721("Pepper Passport", "PEPPER") Ownable(msg.sender) {
        _tokenIdCounter = 0;
    }
    
    /**
     * @notice Mint a new NFT passport for a pepper lot
     * @param farmer The farmer's address
     * @param lotId The unique lot identifier
     * @param variety Pepper variety
     * @param quantity Quantity in kg
     * @param harvestDate Harvest date
     * @param origin Origin location
     * @param certificateHash IPFS hash of certificate
     * @param metadataURI IPFS URI for metadata JSON
     */
    function mintPassport(
        address farmer,
        string memory lotId,
        string memory variety,
        uint256 quantity,
        string memory harvestDate,
        string memory origin,
        bytes32 certificateHash,
        string memory metadataURI
    ) external onlyOwner returns (uint256) {
        require(farmer != address(0), "Invalid farmer address");
        require(bytes(lotId).length > 0, "Lot ID required");
        require(lotIdToTokenId[lotId] == 0, "Lot already has passport");
        
        _tokenIdCounter++;
        uint256 tokenId = _tokenIdCounter;
        
        _safeMint(farmer, tokenId);
        _setTokenURI(tokenId, metadataURI);
        
        passports[tokenId] = PassportData({
            lotId: lotId,
            farmer: farmer,
            createdAt: block.timestamp,
            origin: origin,
            variety: variety,
            quantity: quantity,
            harvestDate: harvestDate,
            certificateHash: certificateHash,
            isActive: true,
            complianceApproved: false,
            complianceCheckedBy: address(0),
            complianceCheckedAt: 0
        });
        
        lotIdToTokenId[lotId] = tokenId;
        passportExists[tokenId] = true;
        
        // Add initial processing log
        processingLogs[tokenId].push(ProcessingLog({
            stage: "Created",
            description: "Pepper lot registered on blockchain",
            timestamp: block.timestamp,
            recordedBy: msg.sender,
            location: origin
        }));
        
        emit PassportMinted(tokenId, lotId, farmer, metadataURI);
        
        return tokenId;
    }
    
    /**
     * @notice Add a processing log entry to the passport
     * @param tokenId The passport token ID
     * @param stage Processing stage
     * @param description Description of the process
     * @param location Location where process occurred
     */
    function addProcessingLog(
        uint256 tokenId,
        string memory stage,
        string memory description,
        string memory location
    ) external onlyOwner {
        require(passportExists[tokenId], "Passport does not exist");
        require(passports[tokenId].isActive, "Passport is inactive");
        
        processingLogs[tokenId].push(ProcessingLog({
            stage: stage,
            description: description,
            timestamp: block.timestamp,
            recordedBy: msg.sender,
            location: location
        }));
        
        emit ProcessingLogAdded(tokenId, stage, block.timestamp);
    }
    
    /**
     * @notice Add a certification to the passport
     * @param tokenId The passport token ID
     * @param certType Type of certification
     * @param certId Certificate ID
     * @param issuedBy Issuing authority
     * @param issuedDate Issue date
     * @param expiryDate Expiry date
     * @param documentHash IPFS hash of certificate document
     */
    function addCertification(
        uint256 tokenId,
        string memory certType,
        string memory certId,
        string memory issuedBy,
        uint256 issuedDate,
        uint256 expiryDate,
        bytes32 documentHash
    ) external onlyOwner {
        require(passportExists[tokenId], "Passport does not exist");
        require(expiryDate > issuedDate, "Invalid expiry date");
        
        certifications[tokenId].push(Certification({
            certType: certType,
            certId: certId,
            issuedBy: issuedBy,
            issuedDate: issuedDate,
            expiryDate: expiryDate,
            documentHash: documentHash,
            isValid: true
        }));
        
        emit CertificationAdded(tokenId, certType, certId, expiryDate);
    }
    
    /**
     * @notice Revoke a certification
     * @param tokenId The passport token ID
     * @param certIndex Index of certification to revoke
     */
    function revokeCertification(
        uint256 tokenId,
        uint256 certIndex
    ) external onlyOwner {
        require(passportExists[tokenId], "Passport does not exist");
        require(certIndex < certifications[tokenId].length, "Invalid cert index");
        
        certifications[tokenId][certIndex].isValid = false;
        
        emit CertificationRevoked(
            tokenId,
            certifications[tokenId][certIndex].certType,
            block.timestamp
        );
    }
    
    /**
     * @notice Get all processing logs for a passport
     * @param tokenId The passport token ID
     */
    function getProcessingLogs(uint256 tokenId) 
        external 
        view 
        returns (ProcessingLog[] memory) 
    {
        require(passportExists[tokenId], "Passport does not exist");
        return processingLogs[tokenId];
    }
    
    /**
     * @notice Get all certifications for a passport
     * @param tokenId The passport token ID
     */
    function getCertifications(uint256 tokenId) 
        external 
        view 
        returns (Certification[] memory) 
    {
        require(passportExists[tokenId], "Passport does not exist");
        return certifications[tokenId];
    }
    
    /**
     * @notice Get passport data by lot ID
     * @param lotId The lot identifier
     */
    function getPassportByLotId(string memory lotId) 
        external 
        view 
        returns (
            uint256 tokenId,
            PassportData memory passport,
            ProcessingLog[] memory logs,
            Certification[] memory certs
        ) 
    {
        tokenId = lotIdToTokenId[lotId];
        require(tokenId != 0, "No passport for this lot");
        
        passport = passports[tokenId];
        logs = processingLogs[tokenId];
        certs = certifications[tokenId];
    }
    
    /**
     * @notice Get complete passport information
     * @param tokenId The passport token ID
     */
    function getPassportInfo(uint256 tokenId) 
        external 
        view 
        returns (
            PassportData memory passport,
            ProcessingLog[] memory logs,
            Certification[] memory certs,
            string memory metadataURI
        ) 
    {
        require(passportExists[tokenId], "Passport does not exist");
        
        passport = passports[tokenId];
        logs = processingLogs[tokenId];
        certs = certifications[tokenId];
        metadataURI = tokenURI(tokenId);
    }

    /**
     * Update compliance status for a lot
     * @param lotId The lot ID
     * @param approved Whether the lot is approved or rejected
     */
    function updateComplianceStatus(
        string memory lotId,
        bool approved
    ) external onlyOwner {
        uint256 tokenId = lotIdToTokenId[lotId];
        require(tokenId != 0, "Lot ID not found");
        require(passportExists[tokenId], "Passport does not exist");
        
        passports[tokenId].complianceApproved = approved;
        passports[tokenId].complianceCheckedBy = msg.sender;
        passports[tokenId].complianceCheckedAt = block.timestamp;
        
        // Add to processing log
        processingLogs[tokenId].push(ProcessingLog({
            stage: approved ? "Compliance Approved" : "Compliance Rejected",
            description: approved 
                ? "Lot approved by admin for auction" 
                : "Lot rejected by admin",
            timestamp: block.timestamp,
            recordedBy: msg.sender,
            location: ""
        }));
        
        emit ComplianceStatusUpdated(
            lotId,
            tokenId,
            approved,
            msg.sender,
            block.timestamp
        );
    }
    
    /**
     * @notice Check if a lot has been compliance approved
     * @param lotId The lot ID
     */
    function isComplianceApproved(string memory lotId) 
        external 
        view 
        returns (bool) 
    {
        uint256 tokenId = lotIdToTokenId[lotId];
        if (tokenId == 0 || !passportExists[tokenId]) {
            return false;
        }
        return passports[tokenId].complianceApproved;
    }
    
    /**
     * @notice Get compliance status details for a lot
     * @param lotId The lot ID
     */
    function getComplianceStatus(string memory lotId)
        external
        view
        returns (
            bool approved,
            address checkedBy,
            uint256 checkedAt
        )
    {
        uint256 tokenId = lotIdToTokenId[lotId];
        require(tokenId != 0, "Lot ID not found");
        require(passportExists[tokenId], "Passport does not exist");
        
        PassportData memory passport = passports[tokenId];
        return (
            passport.complianceApproved,
            passport.complianceCheckedBy,
            passport.complianceCheckedAt
        );
    }
    
    /**
     * @notice 
    
    /**
     * @notice Transfer passport ownership (override to add event)
     */
    function _update(
        address to,
        uint256 tokenId,
        address auth
    ) internal override returns (address) {
        address from = _ownerOf(tokenId);
        
        if (from != address(0) && to != address(0) && from != to) {
            emit PassportTransferred(tokenId, from, to, block.timestamp);
            
            // Add transfer to processing log
            processingLogs[tokenId].push(ProcessingLog({
                stage: "Transferred",
                description: "Ownership transferred",
                timestamp: block.timestamp,
                recordedBy: auth,
                location: ""
            }));
        }
        
        return super._update(to, tokenId, auth);
    }
    
    /**
     * @notice Check if a certification is valid (exists and not expired)
     * @param tokenId The passport token ID
     * @param certIndex Index of certification
     */
    function isCertificationValid(uint256 tokenId, uint256 certIndex) 
        external 
        view 
        returns (bool) 
    {
        require(passportExists[tokenId], "Passport does not exist");
        require(certIndex < certifications[tokenId].length, "Invalid cert index");
        
        Certification memory cert = certifications[tokenId][certIndex];
        return cert.isValid && block.timestamp <= cert.expiryDate;
    }
    
    /**
     * @notice Get total number of passports minted
     */
    function totalSupply() external view returns (uint256) {
        return _tokenIdCounter;
    }
}
