// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "./CompetitionVault.sol";
import "./CompetitionNFT.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CompetitionFactory is Ownable {
    struct CompetitionInfo {
        address vault;
        address nft;
        address creator;
        bool depositsOpen;
        bool redeemsOpen;
        string baseURI;
    }

    mapping(string => CompetitionInfo) public competitions;
    mapping(address => bool) public validVaults;
    string[] public competitionNames;

    address public batchCHZBuyer;

    event CompetitionCreated(string indexed name, address vault, address nft);
    event NFTDeployed(address indexed nft, string name, string symbol);
    event VaultDeployed(address indexed vault, address nft);
    event VaultLinkedToNFT(address indexed nft, address vault);
    event DepositsStatusChanged(string indexed competition, bool status);
    event RedeemsStatusChanged(string indexed competition, bool status);

    constructor(address _batchCHZBuyer) Ownable() {
        require(_batchCHZBuyer != address(0), "Invalid");
        batchCHZBuyer = _batchCHZBuyer;
    }

    function createCompetition(
        string memory name,
        string memory nftName,
        string memory nftSymbol,
        address[] memory initialTokens,
        address wchz,
        address router,
        string memory baseURI
    ) external onlyOwner {
        require(competitions[name].vault == address(0), "Competition exists");
        require(initialTokens.length > 0, "No initial tokens");
        require(wchz != address(0), "Invalid WCHZ");
        require(router != address(0), "Invalid router");

        for (uint i = 0; i < initialTokens.length; i++) {
            require(initialTokens[i] != address(0), "Zero token");
            for (uint j = i + 1; j < initialTokens.length; j++) {
                require(initialTokens[i] != initialTokens[j], "Duplicate token");
            }
        }

        CompetitionNFT nft = new CompetitionNFT(nftName, nftSymbol, address(this));
        emit NFTDeployed(address(nft), nftName, nftSymbol);

        CompetitionVault vault = new CompetitionVault(
            batchCHZBuyer,
            address(nft),
            initialTokens,
            wchz,
            router,
            address(this) 
        );
        emit VaultDeployed(address(vault), address(nft));

        nft.setVault(address(vault));
        nft.transferOwnership(msg.sender);
        vault.transferOwnership(msg.sender);
        emit VaultLinkedToNFT(address(nft), address(vault));

        competitions[name] = CompetitionInfo({
            vault: address(vault),
            nft: address(nft),
            creator: msg.sender,
            depositsOpen: true,
            redeemsOpen: false,
            baseURI: baseURI
        });

        validVaults[address(vault)] = true;
        competitionNames.push(name);

        emit CompetitionCreated(name, address(vault), address(nft));
    }

    function getCompetition(string memory name) external view returns (address vault, address nft) {
        CompetitionInfo memory comp = competitions[name];
        require(comp.vault != address(0), "Competition not found");
        return (comp.vault, comp.nft);
    }

    function areDepositsOpen(string memory name) external view returns (bool) {
        return competitions[name].depositsOpen;
    }

    function areRedeemsOpen(string memory name) external view returns (bool) {
        return competitions[name].redeemsOpen;
    }

    function isAdmin(address user) external view returns (bool) {
        return user == owner();
    }

    function isValidVault(address vaultAddress) external view returns (bool) {
        return validVaults[vaultAddress];
    }

    function getAllCompetitionNames() external view returns (string[] memory) {
        return competitionNames;
    }

    function setDepositsOpen(string memory name, bool status) external onlyOwner {
        require(competitions[name].vault != address(0), "Don't exist");
        competitions[name].depositsOpen = status;
        emit DepositsStatusChanged(name, status);
    }

    function setRedeemsOpen(string memory name, bool status) external onlyOwner {
        require(competitions[name].vault != address(0), "Don't exist");
        competitions[name].redeemsOpen = status;
        emit RedeemsStatusChanged(name, status);
    }

    function getBaseURI(string memory name) external view returns (string memory) {
        return competitions[name].baseURI;
    }
}
