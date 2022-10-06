// SPDX-License-Identifier: GPL-3.0
pragma experimental ABIEncoderV2;
pragma solidity >=0.4.25 <0.9.0;
import "./Customers.sol";
import "./Banks.sol";
contract KYC is Customers, Banks {
    address admin;
    address[] internal userList;
    mapping(address => Types.User) internal users;
    mapping(string => Types.KycRequest) internal kycRequests;
    mapping(address => address[]) internal bankCustomers; 
    mapping(address => address[]) internal customerbanks; 
    constructor(string memory name_, string memory email_) {
        admin = msg.sender;
        Types.User memory usr_ = Types.User({
            name: name_,
            email: email_,
            id_: admin,
            role: Types.Role.Admin,
            status: Types.BankStatus.Active
        });
        users[admin] = usr_;
        userList.push(admin);
    }
    modifier isAdmin() {
        require(msg.sender == admin, "Only admin is allowed");
        _;
    }
    function kycRequestExists(string memory reqId_)internal view returns (bool){
        require(!Help.compareStrings(reqId_, ""), "Request Id empty");
        return Help.compareStrings(kycRequests[reqId_].id_, reqId_);
    }
    function getKYCRequests(uint256 pageNumber, bool isForBank)internal view returns (uint256 totalPages, Types.KycRequest[] memory){
        require(pageNumber > 0, "PN should be > zero");
        (
            uint256 pages,
            uint256 pageLength_,
            uint256 startIndex_,
            uint256 endIndex_
        ) = Help.getIndexes(
                pageNumber,
                isForBank
                    ? bankCustomers[msg.sender]
                    : customerbanks[msg.sender]
            );
        Types.KycRequest[] memory list_ = new Types.KycRequest[](pageLength_);
        for (uint256 i = startIndex_; i < endIndex_; i++)
            list_[i] = isForBank
                ? kycRequests[
                    Help.append(msg.sender, bankCustomers[msg.sender][i])
                ]
                : kycRequests[
                    Help.append(customerbanks[msg.sender][i], msg.sender)
                ];
        return (pages, list_);
    }
    event KycRequestAdded(string reqId, string bankName, string customerName);
    event KycReRequested(string reqId, string bankName, string customerName);
    event KycStatusChanged(
        string reqId,
        address customerId,
        address bankId,
        Types.KycStatus status
    );
    event DataHashPermissionChanged(
        string reqId,
        address customerId,
        address bankId,
        Types.DataHashStatus status
    );
    function getAllBanks(uint256 pageNumber)public view isAdmin returns (uint256 totalPages, Types.Banks[] memory){
        return getallbanks(pageNumber);
    }
    function addBank(Types.Banks memory bank_) public isAdmin {
        addbank(bank_);
        users[bank_.id_] = Types.User({
            name: bank_.name,
            email: bank_.email,
            id_: bank_.id_,
            role: Types.Role.Bank,
            status: Types.BankStatus.Active
        });
        userList.push(bank_.id_);
    }
    function updateBankDetails(address id_,string memory email_,string memory name_) public isAdmin {
        updatebank(id_, email_, name_);
        users[id_].name = name_;
        users[id_].email = email_;
    }
    function activateDeactivateBank(address id_, bool makeActive_)public isAdmin{
        users[id_].status = activatedeactivatebank(id_, makeActive_);
    }
    function getCustomersOfBank(uint256 pageNumber)public view isValidBank(msg.sender)returns (uint256 totalPages, Types.KycRequest[] memory){
        return getKYCRequests(pageNumber, true);
    }
    function addKycRequest(Types.Customer memory customer_,uint256 currentTime_,string memory notes_) public isValidBank(msg.sender) {
        string memory reqId_ = Help.append(msg.sender, customer_.id_);
        require(!kycRequestExists(reqId_), "User had kyc req.");
        kycRequests[reqId_] = Types.KycRequest({
            id_: reqId_,
            userId_: customer_.id_,
            customerName: customer_.name,
            bankId_: msg.sender,
            bankName: getsinglebank(msg.sender).name,
            dataHash: customer_.dataHash,
            updatedOn: currentTime_,
            status: Types.KycStatus.Pending,
            dataRequest: Types.DataHashStatus.Pending,
            additionalNotes: notes_
        });
        bankCustomers[msg.sender].push(customer_.id_);
        customerbanks[customer_.id_].push(msg.sender);
        emit KycRequestAdded(
            reqId_,
            kycRequests[reqId_].bankName,
            customer_.name
        );
        if (!customerExists(customer_.id_)) {
            addcustomer(customer_);
            users[customer_.id_] = Types.User({
                name: customer_.name,
                email: customer_.email,
                id_: customer_.id_,
                role: Types.Role.Customer,
                status: Types.BankStatus.Active
            });
            userList.push(customer_.id_);
        }
    }
    function reRequestForKycRequest(address id_, string memory notes_)public isValidBank(msg.sender){
        string memory reqId_ = Help.append(msg.sender, id_);
        require(kycRequestExists(reqId_), "KYC req not found");
        require(customerExists(id_), "User not found");
        kycRequests[reqId_].dataRequest = Types.DataHashStatus.Pending;
        kycRequests[reqId_].additionalNotes = notes_;
        emit KycReRequested(
            reqId_,
            kycRequests[reqId_].bankName,
            kycRequests[reqId_].customerName
        );
    }
    function updateKycVerification(address userId_,bool verified_,string memory note_) public isValidBank(msg.sender) {
        string memory reqId_ = Help.append(msg.sender, userId_);
        require(kycRequestExists(reqId_), "User doesn't have KYC req");
        Types.KycStatus status_ = Types.KycStatus.Pending;
        if (verified_) {
            status_ = Types.KycStatus.KYCVerified;
            updatekyccount(msg.sender);
            updatekycdoneby(userId_);
        } else {
            status_ = Types.KycStatus.KYCFailed;
        }
        kycRequests[reqId_].status = status_;
        kycRequests[reqId_].additionalNotes = note_;
        emit KycStatusChanged(reqId_, userId_, msg.sender, status_);
    }
    function searchCustomers(address id_)public view isValidCustomer(id_)isValidBank(msg.sender)returns (bool,Types.Customer memory,Types.KycRequest memory){
        bool found_;
        Types.Customer memory customer_;
        Types.KycRequest memory request_;
        (found_, customer_) = searchcustomers(id_, bankCustomers[msg.sender]);
        if (found_) request_ = kycRequests[Help.append(msg.sender, id_)];
        return (found_, customer_, request_);
    }
    function getBankRequests(uint256 pageNumber)public view isValidCustomer(msg.sender)returns (uint256 totalPages, Types.KycRequest[] memory){
        return getKYCRequests(pageNumber, false);
    }
    function actionOnKycRequest(address bankId_,bool approve_,string memory note_) public isValidCustomer(msg.sender) isValidBank(bankId_) {
        string memory reqId_ = Help.append(bankId_, msg.sender);
        require(kycRequestExists(reqId_), "User doesn't have KYC req");
        Types.DataHashStatus status_ = Types.DataHashStatus.Pending;
        if (approve_) {
            status_ = Types.DataHashStatus.Approved;
        } else {
            status_ = Types.DataHashStatus.Rejected;
        }
        kycRequests[reqId_].dataRequest = status_;
        kycRequests[reqId_].additionalNotes = note_;
        emit DataHashPermissionChanged(reqId_, msg.sender, bankId_, status_);
    }
    function updateProfile(string memory name_,string memory email_,uint256 mobile_) public isValidCustomer(msg.sender) {
        updateprofile(name_, email_, mobile_);
        users[msg.sender].name = name_;
        users[msg.sender].email = email_;
    }
    function updateDatahash(string memory hash_, uint256 currentTime_)public isValidCustomer(msg.sender){
        updatedatahash(hash_, currentTime_);
        address[] memory banksList_ = customerbanks[msg.sender];
        for (uint256 i = 0; i < banksList_.length; i++) {
            string memory reqId_ = Help.append(banksList_[i], msg.sender);
            if (kycRequestExists(reqId_)) {
                kycRequests[reqId_].dataHash = hash_;
                kycRequests[reqId_].updatedOn = currentTime_;
                kycRequests[reqId_].status = Types.KycStatus.Pending;
                kycRequests[reqId_].additionalNotes = "Updated all my docs";
            }
        }
    }
    function removerDatahashPermission(address bankId_, string memory notes_)public isValidCustomer(msg.sender){
        string memory reqId_ = Help.append(bankId_, msg.sender);
        require(kycRequestExists(reqId_), "Permission not found");
        kycRequests[reqId_].dataRequest = Types.DataHashStatus.Rejected;
        kycRequests[reqId_].additionalNotes = notes_;
        emit DataHashPermissionChanged(
            reqId_,
            msg.sender,
            bankId_,
            Types.DataHashStatus.Rejected
        );
    }
    function searchBanks(address bankId_)public view isValidCustomer(msg.sender)isValidBank(bankId_)returns (bool,Types.Banks memory,Types.KycRequest memory){
        bool found_;
        Types.Banks memory bank_;
        Types.KycRequest memory request_;
        address[] memory banks_ = customerbanks[msg.sender];
        for (uint256 i = 0; i < banks_.length; i++) {
            if (banks_[i] == bankId_) {
                found_ = true;
                bank_ = getsinglebank(bankId_);
                request_ = kycRequests[Help.append(bankId_, msg.sender)];
                break;
            }
        }
        return (found_, bank_, request_);
    }
    function whoAmI() public view returns (Types.User memory) {
        require(msg.sender != address(0), "Sender Id Empty");
        require(users[msg.sender].id_ != address(0), "User Id Empty");
        return users[msg.sender];
    }
    function getCustomerDetails(address id_)public view isValidCustomer(id_) returns (Types.Customer memory){
        return getcustomerdetails(id_);
    }
    function getBankDetails(address id_)public view isValidBank(id_)returns (Types.Banks memory){
        return getsinglebank(id_);
    }
}