// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

contract CompetitionNFT is ERC721URIStorage, Ownable {
    uint256 private _tokenIdCounter;
    address public vault;
    string public baseTokenURI;

    mapping(uint256 => uint256) public investedAmount;

    event NFTMinted(address indexed to, uint256 tokenId, uint256 amount, string uri);
    event NFTBurned(uint256 tokenId);
    event VaultSet(address vault);
    event BaseURISet(string uri);
    event TokenURIUpdated(uint256 tokenId, string newUri);

    constructor(
        string memory name,
        string memory symbol,
        address initialOwner
    )
        ERC721(name, symbol)
        Ownable(initialOwner)
    {
        console.log("NFT created by:", initialOwner);
    }

    modifier onlyVault() {
        require(msg.sender == vault, "Only vault can call");
        _; 
    }

    function setBaseTokenURI(string memory uri) external onlyOwner {
        require(bytes(uri).length > 0, "Empty URI");
        baseTokenURI = uri;
        emit BaseURISet(uri);
    }

    function mint(
        address to,
        uint256 amount
    ) external onlyVault returns (uint256) {
        require(bytes(baseTokenURI).length > 0, "Base URI not set");

        _tokenIdCounter++;
        uint256 tokenId = _tokenIdCounter;

        _mint(to, tokenId);
        _setTokenURI(tokenId, baseTokenURI);
        investedAmount[tokenId] = amount;

        emit NFTMinted(to, tokenId, amount, baseTokenURI);
        return tokenId;
    }

    function burn(uint256 tokenId) external onlyVault {
        _burn(tokenId);
        delete investedAmount[tokenId];
        emit NFTBurned(tokenId);
    }

    function setVault(address _vault) external onlyOwner {
        require(vault == address(0), "Vault already set");
        require(_vault != address(0), "Invalid vault");
        vault = _vault;
        emit VaultSet(_vault);
    }

    function updateTokenURI(uint256 tokenId, string memory newUri) external onlyVault {
        require(_ownerOf(tokenId) != address(0), "Token does not exist");
        require(bytes(newUri).length > 0, "Empty URI");
        _setTokenURI(tokenId, newUri);
        emit TokenURIUpdated(tokenId, newUri);
    }

    function getCurrentTokenId() external view returns (uint256) {
        return _tokenIdCounter;
    }

    function getVault() external view returns (address) {
        return vault;
    }

    function getInvestedAmount(uint256 tokenId) external view returns (uint256) {
        return investedAmount[tokenId];
    }
}