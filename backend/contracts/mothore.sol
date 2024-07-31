// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";

contract Mothore is ERC721A {

    address public owner;
    address[] public addressOfReserved;
    uint16 public countReserved = 0;
    uint256 public constant MAX_TOTAL_SUPPLY = 105;
    uint256 public constant MAX_RESERVED_SUPPLY = 10;
    uint256 public constant MAX_INDIVIDUAL_SUPPLY = 100;
    uint256 public constant MAX_CORPORATE_SUPPLY = 5;
    uint256 public constant INDIVIDUAL_COST = 1 ether;
    uint256 public constant CORPORATE_COST = 2 ether;

    enum NftType {Individual, Corporate}

    mapping(address => NftType) public nftTypeOfOwner;

    constructor() ERC721A("Mothore Foundry", "MTF") {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "You are not the owner");
        _;
    }

    function mint(address to) external payable {
        require(totalSupply() < MAX_TOTAL_SUPPLY, "Exceeds maximum supply");
        require(!addressOwnsNFT(to), "One token per address");

        if (countReserved < MAX_RESERVED_SUPPLY && isAddressInList(to)) {
            require(!addressOwnsNFT(to), "One token per address");
            _mint(to, 1);
            countReserved++;
        } else {
            require(msg.value >= INDIVIDUAL_COST, "Insufficient funds");
            require(_individualSupply() < MAX_INDIVIDUAL_SUPPLY, "Exceeds individual supply");

            _mint(to, 1);
            nftTypeOfOwner[to] = NftType.Individual;
        }
    }

    function mintCorporate(address to) external payable {
        require(totalSupply() < MAX_TOTAL_SUPPLY, "Exceeds maximum supply");
        require(!addressOwnsNFT(to), "One token per address");
        require(msg.value >= CORPORATE_COST, "Insufficient funds");
        require(_corporateSupply() < MAX_CORPORATE_SUPPLY, "Exceeds corporate supply");

        _mint(to, 1);
        nftTypeOfOwner[to] = NftType.Corporate;
    }

    function isAddressInList(address _address) public view returns (bool) {
        for (uint256 i = 0; i < addressOfReserved.length; i++) {
            if (addressOfReserved[i] == _address) {
                return true;
            }
        }
        return false;
    }

    function addressOwnsNFT(address user) public view returns (bool) {
        return balanceOf(user) > 0;
    }

    function _individualSupply() internal view returns (uint256) {
        return totalSupply() - _corporateSupply();
    }

    function _corporateSupply() internal view returns (uint256) {
        uint256 supply = 0;
        for (uint256 i = 0; i < totalSupply(); i++) {
            if (nftTypeOfOwner[ownerOf(i)] == NftType.Corporate) {
                supply++;
            }
        }
        return supply;
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://ethereum-blockchain-developer.com/2022-06-nft-truffle-hardhat-foundry/nftdata/";
    }

    function addReservedAddress(address user) public onlyOwner {
        require(countReserved < MAX_RESERVED_SUPPLY, "Reserved addresses full");
        require(!isAddressInList(user), "Address already reserved");
        addressOfReserved.push(user);
    }
}
