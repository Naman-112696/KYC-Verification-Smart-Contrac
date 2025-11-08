Mapping to track KYC status for addresses
    mapping(address => bool) private _kycVerified;

    // Events
    event KYCAdded(address indexed user, address indexed addedBy);
    event KYCRemoved(address indexed user, address indexed removedBy);

    /**
     * @dev Constructor assigns deployer as DEFAULT_ADMIN_ROLE and KYC_ADMIN_ROLE
     */
    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(KYC_ADMIN_ROLE, msg.sender);
    }

    /**
     * @dev Adds KYC verified status for a user address
     * @param user Address to verify
     */
    function addKYC(address user) external onlyRole(KYC_ADMIN_ROLE) {
        require(user != address(0), "Invalid address");
        require(!_kycVerified[user], "User already KYC verified");

        _kycVerified[user] = true;
        emit KYCAdded(user, msg.sender);
    }

    /**
     * @dev Removes KYC verified status for a user address
     * @param user Address to revoke
     */
    function removeKYC(address user) external onlyRole(KYC_ADMIN_ROLE) {
        require(user != address(0), "Invalid address");
        require(_kycVerified[user], "User not KYC verified");

        _kycVerified[user] = false;
        emit KYCRemoved(user, msg.sender);
    }

    /**
     * @dev Returns whether an address is KYC verified
     * @param user Address to query
     * @return bool True if KYC verified, false otherwise
     */
    function isKYCVerified(address user) external view returns (bool) {
        return _kycVerified[user];
    }

    /**
     * @dev Grants KYC admin role to an address
     * @param account Address to grant role
     */
    function grantKYCAdmin(address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(KYC_ADMIN_ROLE, account);
    }

    /**
     * @dev Revokes KYC admin role from an address
     * @param account Address to revoke role
     */
    function revokeKYCAdmin(address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(KYC_ADMIN_ROLE, account);
    }
}
// 
End
// 
