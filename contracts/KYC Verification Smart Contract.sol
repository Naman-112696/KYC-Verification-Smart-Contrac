? Manually verify customer (owner override)
    function ownerVerifyCustomer(address _customerAddress, string memory _remark) external onlyOwner {
        require(customers[_customerAddress].customerAddress != address(0), "Customer not registered");
        customers[_customerAddress].status = VerificationStatus.Verified;
        customers[_customerAddress].verificationTimestamp = block.timestamp;
        customers[_customerAddress].verifierRemark = _remark;

        emit CustomerManuallyVerified(_customerAddress, _remark);
    }

    ? Check if an address is a registered customer
    function isCustomerRegistered(address _addr) public view returns (bool) {
        return customers[_addr].customerAddress != address(0);
    }
}
END
// 
update
// 
