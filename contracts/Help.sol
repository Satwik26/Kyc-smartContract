// SPDX-License-Identifier: GPL-3.0
pragma experimental ABIEncoderV2;
pragma solidity >=0.4.25 <0.9.0;
library Help{
    function getIndexes(uint256 pageNumber, address[] memory users_)internal pure returns (
            uint256 pages,
            uint256 pageLength_,
            uint256 startIndex_,
            uint256 endIndex_
        ){
        uint256 reminder_ = users_.length % 25;
        pages = users_.length / 25;
        if (reminder_ > 0) pages++;
        pageLength_ = 25;
        startIndex_ = 25 * (pageNumber - 1);
        endIndex_ = 25 * pageNumber;

        if (pageNumber > pages) {
            pageLength_ = 0;
            endIndex_ = 0;
        } else if (pageNumber == pages && reminder_ > 0) {
            pageLength_ = reminder_;
            endIndex_ = users_.length;
        }
    }
    function compareStrings(string memory a, string memory b)internal pure returns (bool){
        return (keccak256(abi.encodePacked((a))) ==keccak256(abi.encodePacked((b))));
    }
    function append(address a, address b)internal pure returns (string memory){
        return string(abi.encodePacked(a, b));
    }
}