// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @title KYCVerification
 * @dev Smart contract for managing KYC verification processes
 */
contract KYCVerification {
    address public owner;

    enum VerificationStatus { Unverified, Pending, Verified, Rejected }

    struct Customer {
        address customerAddress;
        string customerName;
        string customerDataHash;
        VerificationStatus status;
        uint256 verificationTimestamp;
        string rejectionReason;
    }

    mapping(address => Customer) public customers;
    mapping(address => bool) public verifiers;

    address[] private customerAddresses;

    uint256 public customerCount;
    uint256 public verifierCount;

    event CustomerRegistered(address indexed customerAddress, string customerName);
    event KYCVerified(address indexed customerAddress, address indexed verifier);
    event KYCRejected(address indexed customerAddress, address indexed verifier, string reason);
    event VerifierAdded(address indexed verifier);
    event VerifierRemoved(address indexed verifier);
    event KYCResubmitted(address indexed customerAddress, string newHash);
    event CustomerNameChanged(address indexed customerAddress, string newName);

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

        customerAddresses.push(msg.sender);
        customerCount++;
        emit CustomerRegistered(msg.sender, _customerName);
    }

    function verifyCustomer(address _customerAddress) public onlyVerifier {
        require(customers[_customerAddress].customerAddress != address(0), "Customer not registered");
        require(customers[_customerAddress].status == VerificationStatus.Pending, "Not in pending state");

        customers[_customerAddress].status = VerificationStatus.Verified;
        customers[_customerAddress].verificationTimestamp = block.timestamp;

        emit KYCVerified(_customerAddress, msg.sender);
    }

    function rejectCustomer(address _customerAddress, string memory _reason) public onlyVerifier {
        require(customers[_customerAddress].customerAddress != address(0), "Customer not registered");
        require(customers[_customerAddress].status == VerificationStatus.Pending, "Not in pending state");

        customers[_customerAddress].status = VerificationStatus.Rejected;
        customers[_customerAddress].rejectionReason = _reason;

        emit KYCRejected(_customerAddress, msg.sender, _reason);
    }

    function addVerifier(address _verifierAddress) public onlyOwner {
        require(!verifiers[_verifierAddress], "Already a verifier");

        verifiers[_verifierAddress] = true;
        verifierCount++;

        emit VerifierAdded(_verifierAddress);
    }

    function removeVerifier(address _verifierAddress) public onlyOwner {
        require(verifiers[_verifierAddress], "Not a verifier");
        require(_verifierAddress != owner, "Cannot remove owner");

        verifiers[_verifierAddress] = false;
        verifierCount--;

        emit VerifierRemoved(_verifierAddress);
    }

    function getCustomerStatus(address _customerAddress) public view returns (VerificationStatus) {
        require(customers[_customerAddress].customerAddress != address(0), "Customer not registered");
        return customers[_customerAddress].status;
    }

    // 🆕 Get full customer details
    function getCustomerDetails(address _customerAddress) public view returns (
        string memory name,
        string memory dataHash,
        VerificationStatus status,
        uint256 timestamp,
        string memory reason
    ) {
        Customer memory c = customers[_customerAddress];
        require(c.customerAddress != address(0), "Customer not registered");
        return (c.customerName, c.customerDataHash, c.status, c.verificationTimestamp, c.rejectionReason);
    }

    // 🆕 Allow resubmission of KYC data if rejected
    function resubmitKYC(string memory _newHash) public {
        require(customers[msg.sender].customerAddress != address(0), "Customer not registered");
        require(customers[msg.sender].status == VerificationStatus.Rejected, "KYC not rejected");

        customers[msg.sender].customerDataHash = _newHash;
        customers[msg.sender].status = VerificationStatus.Pending;
        customers[msg.sender].rejectionReason = "";

        emit KYCResubmitted(msg.sender, _newHash);
    }

    // 🆕 Change customer name (before approval)
    function changeCustomerName(string memory _newName) public {
        require(customers[msg.sender].customerAddress != address(0), "Customer not registered");
        require(customers[msg.sender].status == VerificationStatus.Pending, "Can only change during pending");

        customers[msg.sender].customerName = _newName;
        emit CustomerNameChanged(msg.sender, _newName);
    }

    // 🆕 Get all customer addresses
    function getAllCustomerAddresses() public view returns (address[] memory) {
        return customerAddresses;
    }

    // 🆕 Check if address is a verifier
    function isVerifier(address _addr) public view returns (bool) {
        return verifiers[_addr];
    }
}
