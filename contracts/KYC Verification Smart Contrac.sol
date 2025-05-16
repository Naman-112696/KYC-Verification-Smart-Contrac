// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @title KYCVerification
 * @dev Smart contract for managing KYC verification processes
 */
contract KYCVerification {
    address public owner;
    
    // Possible verification status
    enum VerificationStatus { Unverified, Pending, Verified, Rejected }
    
    // Structure to hold customer KYC information
    struct Customer {
        address customerAddress;
        string customerName;
        string customerDataHash; // IPFS or other storage hash for KYC documents
        VerificationStatus status;
        uint256 verificationTimestamp;
        string rejectionReason;
    }
    
    // Mappings to store data
    mapping(address => Customer) public customers;
    mapping(address => bool) public verifiers;
    
    // Count of customers and verifiers
    uint256 public customerCount;
    uint256 public verifierCount;
    
    // Events
    event CustomerRegistered(address indexed customerAddress, string customerName);
    event KYCVerified(address indexed customerAddress, address indexed verifier);
    event KYCRejected(address indexed customerAddress, address indexed verifier, string reason);
    event VerifierAdded(address indexed verifier);
    event VerifierRemoved(address indexed verifier);
    
    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    modifier onlyVerifier() {
        require(verifiers[msg.sender] || msg.sender == owner, "Only verifiers can call this function");
        _;
    }
    
    constructor() {
        owner = msg.sender;
        verifiers[msg.sender] = true;
        verifierCount = 1;
    }
    
    /**
     * @dev Register a customer for KYC verification
     * @param _customerName Name of the customer
     * @param _customerDataHash IPFS or other storage hash containing KYC documents
     */
    function registerCustomer(string memory _customerName, string memory _customerDataHash) public {
        require(customers[msg.sender].customerAddress == address(0), "Customer already registered");
        
        customers[msg.sender] = Customer({
            customerAddress: msg.sender,
            customerName: _customerName,
            customerDataHash: _customerDataHash,
            status: VerificationStatus.Pending,
            verificationTimestamp: 0,
            rejectionReason: ""
        });
        
        customerCount++;
        emit CustomerRegistered(msg.sender, _customerName);
    }
    
    /**
     * @dev Verify a customer's KYC
     * @param _customerAddress Address of the customer to verify
     */
    function verifyCustomer(address _customerAddress) public onlyVerifier {
        require(customers[_customerAddress].customerAddress != address(0), "Customer not registered");
        require(customers[_customerAddress].status == VerificationStatus.Pending, "Customer not in pending state");
        
        customers[_customerAddress].status = VerificationStatus.Verified;
        customers[_customerAddress].verificationTimestamp = block.timestamp;
        
        emit KYCVerified(_customerAddress, msg.sender);
    }
    
    /**
     * @dev Reject a customer's KYC
     * @param _customerAddress Address of the customer to reject
     * @param _reason Reason for rejection
     */
    function rejectCustomer(address _customerAddress, string memory _reason) public onlyVerifier {
        require(customers[_customerAddress].customerAddress != address(0), "Customer not registered");
        require(customers[_customerAddress].status == VerificationStatus.Pending, "Customer not in pending state");
        
        customers[_customerAddress].status = VerificationStatus.Rejected;
        customers[_customerAddress].rejectionReason = _reason;
        
        emit KYCRejected(_customerAddress, msg.sender, _reason);
    }
    
    /**
     * @dev Add a new verifier
     * @param _verifierAddress Address of the new verifier
     */
    function addVerifier(address _verifierAddress) public onlyOwner {
        require(!verifiers[_verifierAddress], "Address is already a verifier");
        
        verifiers[_verifierAddress] = true;
        verifierCount++;
        
        emit VerifierAdded(_verifierAddress);
    }
    
    /**
     * @dev Remove a verifier
     * @param _verifierAddress Address of the verifier to remove
     */
    function removeVerifier(address _verifierAddress) public onlyOwner {
        require(verifiers[_verifierAddress], "Address is not a verifier");
        require(_verifierAddress != owner, "Cannot remove owner as verifier");
        
        verifiers[_verifierAddress] = false;
        verifierCount--;
        
        emit VerifierRemoved(_verifierAddress);
    }
    
    /**
     * @dev Get customer verification status
     * @param _customerAddress Address of the customer
     * @return Status of the customer verification process
     */
    function getCustomerStatus(address _customerAddress) public view returns (VerificationStatus) {
        require(customers[_customerAddress].customerAddress != address(0), "Customer not registered");
        return customers[_customerAddress].status;
    }
}
