// SPDX-License-Identifier: GPL-3.0
pragma experimental ABIEncoderV2;
pragma solidity >=0.4.25 <0.9.0;
import "./Types.sol";
import "./Help.sol";
contract Customers {
    address[] internal customerList;
    mapping(address => Types.Customer) internal customers;
    event CustomerAdded(address id_, string name, string email);
    event CustomerDataUpdated(address id_, string name, string email);
    event DataHashUpdated(address id_, string customerName, string dataHash);

    modifier isValidCustomer(address id_) {
        require(id_ != address(0), "Id is Empty");
        require(customers[id_].id_ != address(0), "User Id Empty");
        require(
            !Help.compareStrings(customers[id_].email, ""),
            "User Email Empty"
        );
        _;
    }
    function customerExists(address id_) internal view returns (bool exists_) {
        require(id_ != address(0), "Id is empty");
        if (customers[id_].id_ != address(0) && !Help.compareStrings(customers[id_].email, "")) {
            exists_ = true;
        }
    }
    function getcustomerdetails(address id_)
        internal
        view
        returns (Types.Customer memory)
    {
        return customers[id_];
    }
    function updateprofile(
        string memory name_,
        string memory email_,
        uint256 mobile_
    ) internal {
        customers[msg.sender].name = name_;
        customers[msg.sender].email = email_;
        customers[msg.sender].mobileNumber = mobile_;
        emit CustomerDataUpdated(msg.sender, name_, email_);
    }
    function addcustomer(Types.Customer memory customer_) internal {
        customers[customer_.id_] = customer_;
        customerList.push(customer_.id_);
        emit CustomerAdded(customer_.id_, customer_.name, customer_.email);
    }
    function updatekycdoneby(address id_) internal {
        require(id_ != address(0), "Customer Id Empty");
        customers[id_].kycVerifiedBy = msg.sender;
    }
    function updatedatahash(string memory hash_, uint256 currentTime_)
        internal
    {
        customers[msg.sender].dataHash = hash_;
        customers[msg.sender].dataUpdatedOn = currentTime_;
        emit DataHashUpdated(msg.sender, customers[msg.sender].name, hash_);
    }
    function searchcustomers(address id_, address[] memory customers_)
        internal
        view
        returns (bool, Types.Customer memory){
        bool found_;
        Types.Customer memory customer_;
        for (uint256 i = 0; i < customers_.length; i++) {
            if (customers_[i] == id_) {
                found_ = true;
                customer_ = customers[id_];
                break;
            }
        }
        return (found_, customer_);
    }
}