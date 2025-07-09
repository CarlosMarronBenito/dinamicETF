// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

error OnlyVault();
error VaultAlreadySet();
error InvalidVault();
error EmptyURI();
error TokenDoesNotExist();

contract CompetitionNFT is ERC721, Ownable {
    uint256 private _tokenIdCounter;
    address public vault;
    string private baseTokenURI;

    mapping(uint256 => uint256) public investedAmount;

    event Minted(address indexed to, uint256 tokenId, uint256 amount);
    event Burned(uint256 tokenId);
    event VaultAssigned(address vault);
    event UriUpdated(uint256 tokenId);

    constructor(string memory name, string memory symbol, address initialOwner)
        ERC721(name, symbol)
    {
        transferOwnership(initialOwner);
    }

    modifier onlyVaultMod() {
        if (msg.sender != vault) revert OnlyVault();
        _;
    }

    function setBaseTokenURI(string memory uri) external onlyOwner {
        if (bytes(uri).length == 0) revert EmptyURI();
        baseTokenURI = uri;
    }

    function mint(address to, uint256 amount) external onlyVaultMod returns (uint256) {
        if (bytes(baseTokenURI).length == 0) revert EmptyURI();

        uint256 tokenId = ++_tokenIdCounter;
        _mint(to, tokenId);
        investedAmount[tokenId] = amount;

        emit Minted(to, tokenId, amount);
        return tokenId;
    }

    function burn(uint256 tokenId) external onlyVaultMod {
        _burn(tokenId);
        delete investedAmount[tokenId];
        emit Burned(tokenId);
    }

    function setVault(address _vault) external onlyOwner {
        if (vault != address(0)) revert VaultAlreadySet();
        if (_vault == address(0)) revert InvalidVault();
        vault = _vault;
        emit VaultAssigned(_vault);
    }

    function updateTokenURI(uint256 tokenId, string memory newUri) external onlyVaultMod {
        if (!_exists(tokenId)) revert TokenDoesNotExist();
        if (bytes(newUri).length == 0) revert EmptyURI();
        baseTokenURI = newUri;
        emit UriUpdated(tokenId);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) revert TokenDoesNotExist();
        return baseTokenURI;
    }
}
