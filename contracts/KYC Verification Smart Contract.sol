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
        string verifierRemark;
    }

    mapping(address => Customer) public customers;
    mapping(address => bool) public verifiers;
    address[] private customerAddresses;

    uint256 public customerCount;
    uint256 public verifierCount;

    event CustomerRegistered(address indexed customerAddress, string customerName);
    event KYCVerified(address indexed customerAddress, address indexed verifier, string remark);
    event KYCRejected(address indexed customerAddress, address indexed verifier, string reason);
    event VerifierAdded(address indexed verifier);
    event VerifierRemoved(address indexed verifier);
    event KYCResubmitted(address indexed customerAddress, string newHash);
    event CustomerNameChanged(address indexed customerAddress, string newName);
    event CustomerDeleted(address indexed customerAddress);
    event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);
    event CustomerManuallyVerified(address indexed customerAddress, string remark);

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

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid owner");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function registerCustomer(string memory _customerName, string memory _customerDataHash) public {
        require(customers[msg.sender].customerAddress == address(0), "Customer already registered");

        customers[msg.sender] = Customer({
            customerAddress: msg.sender,
            customerName: _customerName,
            customerDataHash: _customerDataHash,
            status: VerificationStatus.Pending,
            verificationTimestamp: 0,
            rejectionReason: "",
            verifierRemark: ""
        });

        customerAddresses.push(msg.sender);
        customerCount++;

        emit CustomerRegistered(msg.sender, _customerName);
    }

    function verifyCustomer(address _customerAddress, string memory _remark) public onlyVerifier {
        require(customers[_customerAddress].customerAddress != address(0), "Customer not registered");
        require(customers[_customerAddress].status == VerificationStatus.Pending, "Not in pending state");

        customers[_customerAddress].status = VerificationStatus.Verified;
        customers[_customerAddress].verificationTimestamp = block.timestamp;
        customers[_customerAddress].verifierRemark = _remark;

        emit KYCVerified(_customerAddress, msg.sender, _remark);
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

    function getCustomerDetails(address _customerAddress) public view returns (
        string memory name,
        string memory dataHash,
        VerificationStatus status,
        uint256 timestamp,
        string memory reason,
        string memory remark
    ) {
        Customer memory c = customers[_customerAddress];
        require(c.customerAddress != address(0), "Customer not registered");
        return (c.customerName, c.customerDataHash, c.status, c.verificationTimestamp, c.rejectionReason, c.verifierRemark);
    }

    function resubmitKYC(string memory _newHash) public {
        require(customers[msg.sender].customerAddress != address(0), "Customer not registered");
        require(customers[msg.sender].status == VerificationStatus.Rejected, "KYC not rejected");

        customers[msg.sender].customerDataHash = _newHash;
        customers[msg.sender].status = VerificationStatus.Pending;
        customers[msg.sender].rejectionReason = "";
        customers[msg.sender].verifierRemark = "";

        emit KYCResubmitted(msg.sender, _newHash);
    }

    function changeCustomerName(string memory _newName) public {
        require(customers[msg.sender].customerAddress != address(0), "Customer not registered");
        require(customers[msg.sender].status == VerificationStatus.Pending, "Can only change during pending");

        customers[msg.sender].customerName = _newName;

        emit CustomerNameChanged(msg.sender, _newName);
    }

    function getAllCustomerAddresses() public view returns (address[] memory) {
        return customerAddresses;
    }

    function isVerifier(address _addr) public view returns (bool) {
        return verifiers[_addr];
    }

    function deleteCustomer() public {
        require(customers[msg.sender].customerAddress != address(0), "Customer not registered");

        delete customers[msg.sender];
        customerCount--;

        emit CustomerDeleted(msg.sender);
    }

    function getCustomersByStatus(VerificationStatus statusFilter) public view returns (address[] memory) {
        address[] memory temp = new address[](customerCount);
        uint count = 0;

        for (uint i = 0; i < customerAddresses.length; i++) {
            if (customers[customerAddresses[i]].status == statusFilter) {
                temp[count] = customerAddresses[i];
                count++;
            }
        }

        address[] memory filtered = new address[](count);
        for (uint j = 0; j < count; j++) {
            filtered[j] = temp[j];
        }

        return filtered;
    }

    // ? Manually verify customer (owner override)
    function ownerVerifyCustomer(address _customerAddress, string memory _remark) external onlyOwner {
        require(customers[_customerAddress].customerAddress != address(0), "Customer not registered");
        customers[_customerAddress].status = VerificationStatus.Verified;
        customers[_customerAddress].verificationTimestamp = block.timestamp;
        customers[_customerAddress].verifierRemark = _remark;

        emit CustomerManuallyVerified(_customerAddress, _remark);
    }

    // ? Get summary count of all customer statuses
    function getStatusCounts() public view returns (
        uint256 unverified,
        uint256 pending,
        uint256 verified,
        uint256 rejected
    ) {
        uint256 a; uint256 b; uint256 c; uint256 d;
        for (uint i = 0; i < customerAddresses.length; i++) {
            VerificationStatus s = customers[customerAddresses[i]].status;
            if (s == VerificationStatus.Unverified) a++;
            else if (s == VerificationStatus.Pending) b++;
            else if (s == VerificationStatus.Verified) c++;
            else if (s == VerificationStatus.Rejected) d++;
        }
        return (a, b, c, d);
    }

    // ? Check if an address is a registered customer
    function isCustomerRegistered(address _addr) public view returns (bool) {
        return customers[_addr].customerAddress != address(0);
    }
}
// START
Updated on 2025-10-21
// END
