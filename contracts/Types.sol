// SPDX-License-Identifier: GPL-3.0
pragma experimental ABIEncoderV2;
pragma solidity >=0.4.25 <0.9.0;
library Types {
    enum Role {Admin, Bank, Customer }

    enum BankStatus {Active, Inactive }

    enum KycStatus {Pending, KYCVerified, KYCFailed }

    enum DataHashStatus {Pending, Approved, Rejected }

    struct User {
        string name;
        string email;
        address id_;
        Role role;
        BankStatus status;
    }

    struct Customer {
        string name;
        string email;
        uint256 mobileNumber;
        address id_;
        address kycVerifiedBy; 
        string dataHash; 
        uint256 dataUpdatedOn;
    }
    struct Banks{
        string name;
        string email;
        address id_;
        string ifscCode;
        uint16 kycCount; 
        BankStatus status; 
    }

    struct KycRequest {
        string id_; 
        address userId_;
        string customerName;
        address bankId_;
        string bankName;
        string dataHash;
        uint256 updatedOn;
        KycStatus status;
        DataHashStatus dataRequest; 
        string additionalNotes; 
    }
}