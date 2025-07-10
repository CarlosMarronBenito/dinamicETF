// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "./CompetitionVault.sol";
import "./CompetitionNFT.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
contract CompetitionFactory is Ownable {
    struct CompetitionInfo {
        bool exists;
        address vault;
        address nft;
        address creator;
        bool depositsOpen;
        bool redeemsOpen;
        string baseURI;
    }

    mapping(bytes32 => CompetitionInfo) public competitions;
    mapping(address => bool) public validVaults;
    string[] public competitionNames;
    mapping(bytes32 => mapping(address => bool)) isExists;


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
        bytes32 hash = keccak256(abi.encodePacked(name));
        uint256 len = initialTokens.length;
        CompetitionInfo storage competition = competitions[hash];

        require(!competition.exists, "Competition exists");
        require(len > 0, "No initial tokens");
        require(wchz != address(0), "Invalid WCHZ");
        require(router != address(0), "Invalid router");

        mapping(address => bool) storage exists = isExists[hash];
        for (uint i; i < len;) {
            address token = initialTokens[i];
            require(token != address(0), "Token cannot be zero address");
            require(!exists[token], "Duplicate token");
            exists[token] = true;
            unchecked {
                i++;
            }
        }
        /* save gas... 
        for (uint i = 0; i < len; i++) {
            address token = initialTokens[i];
            require(token != address(0), "Zero token");
            //
            for (uint j = i + 1; j < len; j++) {
                require(token != initialTokens[j], "Duplicate token");
            }
        }*/

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
        nft.transferOwnership(msg.sender);//is required? CompetitionNFT.sol Line :28  [CompetitionFactory.sol Check Line : 61 address(this) can be msg.sender]
        vault.transferOwnership(msg.sender);
        emit VaultLinkedToNFT(address(nft), address(vault));

            competition.exists = true;
            competition.vault= address(vault);
            competition.nft= address(nft);
            competition.creator= msg.sender;
            competition.depositsOpen= true;
            competition.redeemsOpen= false;
            competition.baseURI= baseURI;


        validVaults[address(vault)] = true;
        competitionNames.push(name);

        emit CompetitionCreated(name, address(vault), address(nft));
    }

    function getCompetitionEx(string memory name) external view returns (CompetitionInfo memory competition){
        bytes32 hash = keccak256(abi.encodePacked(name));
        return competitions[hash];
    }

    function getCompetition(string memory name) external view returns (address vault, address nft) {
        bytes32 hash = keccak256(abi.encodePacked(name));
        CompetitionInfo memory comp = competitions[hash];
        require(comp.exists, "Competition not found");
        return (comp.vault, comp.nft);
    }


    function areDepositsOpen(string memory name) external view returns (bool) {
        bytes32 hash = keccak256(abi.encodePacked(name));
        return competitions[hash].depositsOpen;
    }

    function areRedeemsOpen(string memory name) external view returns (bool) {
        bytes32 hash = keccak256(abi.encodePacked(name));
        return competitions[hash].redeemsOpen;
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
        bytes32 hash = keccak256(abi.encodePacked(name));
        require(competitions[hash].vault != address(0), "Don't exist");
        competitions[hash].depositsOpen = status;
        emit DepositsStatusChanged(name, status);
    }

    function setRedeemsOpen(string memory name, bool status) external onlyOwner {
        bytes32 hash = keccak256(abi.encodePacked(name));
        require(competitions[hash].vault != address(0), "Don't exist");
        competitions[hash].redeemsOpen = status;
        emit RedeemsStatusChanged(name, status);
    }

    function getBaseURI(string memory name) external view returns (string memory) {
        bytes32 hash = keccak256(abi.encodePacked(name));
        return competitions[hash].baseURI;
    }
}
