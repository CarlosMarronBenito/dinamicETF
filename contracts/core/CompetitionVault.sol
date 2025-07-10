// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IBatchCHZBuyer {
    function swapEqualCHZToMultipleTokens(address[] calldata tokensOut, uint256 minOutPerToken) external payable;
}

interface IVaultNFT {
    function mint(address to, uint256 amount) external returns (uint256);
    function burn(uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external view returns (address);
}

interface IFactory {
    function getFeeReceiveerAddress() external view returns(address);
    function isValidVault(address vault) external view returns (bool);
}

interface IVault {
    function depositFromPreviousVault(address user, uint256 amount, uint256 invested) external;
}

interface IWCHZ {
    function deposit() external payable;
    function withdraw(uint256 amount) external;
    function balanceOf(address account) external view returns (uint256);
}

contract CompetitionVault is Ownable, ReentrancyGuard {
    address public nftAddress;
    IBatchCHZBuyer public batchBuyer;
    address public immutable WCHZ;
    address public immutable adminRouter;
    address public factory;

    bool public competitionEnded = false;
    bool public depositsOpen = true;
    bool public redeemsOpen = false;

    address[] public tokensToBuy;

    uint256 public totalInvested;
    mapping(uint256 => uint256) public investedPerNFT;
    mapping(address => bool) public admins;
    mapping(uint256 => bool) public hasRedeemed;

    modifier onlyAdmin() {
        require(admins[msg.sender] || msg.sender == owner(), "Not admin");
        _;
    }

    event Deposited(address indexed user, uint256 amount, uint256 tokenId);
    event Redeemed(address indexed user, uint256 payout, uint256 tokenId);
    event CompetitionEnded();
    event DepositStatusChanged(bool status);
    event RedeemStatusChanged(bool status);
    event EmergencyWithdraw(address to, uint256 amount);
    event EmergencyERC20Withdraw(address indexed token, address indexed to, uint256 amount);
    event TokensUpdated(address[] newTokens);
    event AdminUpdated(address indexed admin, bool isAdmin);
    event AdminSwapExecuted(address tokenIn, address tokenOut, uint256 amountIn, uint256 minOut);

    constructor(
        address _batchBuyer,
        address _nft,
        address[] memory _initialTokens,
        address _wchz,
        address _adminRouter,
        address _factory
    ) Ownable() {
        require(_batchBuyer != address(0), "Invalid");
        require(_wchz != address(0), "Invalid");
        require(_factory != address(0), "Invalid");
        require(_adminRouter != address(0), "Invalid");

        nftAddress = _nft;
        batchBuyer = IBatchCHZBuyer(_batchBuyer);
        WCHZ = _wchz;
        adminRouter = _adminRouter;
        factory = _factory;
        tokensToBuy = _initialTokens;

        admins[_factory] = true;
    }

    receive() external payable {}

    function setAdmin(address admin, bool value) external onlyOwner {
        admins[admin] = value;
        emit AdminUpdated(admin, value);
    }

    function isAdmin(address addr) external view returns (bool) {
        return admins[addr] || addr == owner();
    }

    function setNFT(address _nft) external onlyOwner {
        require(nftAddress == address(0), "NFTset");
        require(_nft != address(0), "Invalid");
        nftAddress = _nft;
    }

    function endCompetition() external onlyAdmin {
        competitionEnded = true;
        emit CompetitionEnded();
    }

    function setDepositsOpen(bool status) external onlyAdmin {
        depositsOpen = status;
        emit DepositStatusChanged(status);
    }

    function setRedeemsOpen(bool status) external onlyAdmin {
        redeemsOpen = status;
        emit RedeemStatusChanged(status);
    }

    function areDepositsOpen() external view returns (bool) {
        return depositsOpen && !competitionEnded;
    }

    function areRedeemsOpen() external view returns (bool) {
        return redeemsOpen && competitionEnded;
    }

    function updateTokensToBuy(address[] calldata newTokens) external onlyAdmin {
        require(newTokens.length > 0, "Empty token list");
        tokensToBuy = newTokens;
        emit TokensUpdated(newTokens);
    }

    function depositAndBuy() external payable nonReentrant {
        uint256 tokenLength = tokensToBuy.length;
        require(!competitionEnded, "Competition ended");
        require(depositsOpen, "Deposits closed");
        require(tokenLength > 0, "No tokens");
        require(msg.value > 0, "No");

        IVaultNFT nft = IVaultNFT(nftAddress);
        uint256 tokenId = nft.mint(msg.sender, msg.value);

        investedPerNFT[tokenId] = msg.value;
        totalInvested += msg.value;

        address[] memory filteredTokens = new address[](tokenLength);
        uint256 count = 0;
        for (uint256 i; i < tokenLength;) {
            if (tokensToBuy[i] != WCHZ) {
                filteredTokens[count] = tokensToBuy[i];
                count++;
            }
            unchecked{
                i++;
            }
        }

        if (count > 0) {
            address[] memory finalTokens = new address[](count);
            for (uint256 i = 0; i < count;) {
                finalTokens[i] = filteredTokens[i];
                unchecked{
                    i++;
                }
            }
            batchBuyer.swapEqualCHZToMultipleTokens{value: msg.value}(finalTokens, 0);
        }

        emit Deposited(msg.sender, msg.value, tokenId);
    }

    function redeem(uint256 tokenId) external nonReentrant {
        require(competitionEnded, "Competition not ended");
        require(redeemsOpen, "Closed");

        IVaultNFT nft = IVaultNFT(nftAddress);
        require(nft.ownerOf(tokenId) == msg.sender, "Not token owner");
        require(!hasRedeemed[tokenId], "Redeemed");

        uint256 invested = investedPerNFT[tokenId];
        require(invested > 0, "0 invested");
        require(totalInvested > 0, "No remaining");

        hasRedeemed[tokenId] = true;
        nft.burn(tokenId);

        uint256 wchzBalance = IERC20(WCHZ).balanceOf(address(this));
        if (wchzBalance > 0) {
            IWCHZ(WCHZ).withdraw(wchzBalance);
        }

        uint256 vaultBalance = address(this).balance;
        uint256 userShare = (vaultBalance * invested) / totalInvested;
        totalInvested -= invested;

        uint256 profit = userShare > invested ? userShare - invested : 0;
        uint256 fee = (profit * 20) / 100;
        uint256 payout = userShare - fee;
        payable(msg.sender).transfer(payout);

        if(fee > 0){
            address feeReceiver = IFactory(factory).getFeeReceiveerAddress();
            payable(feeReceiver).transfer(fee);
        }
        emit Redeemed(msg.sender, userShare, tokenId);
    }


    function emergencyWithdraw(address to) external onlyAdmin nonReentrant{
        uint256 amount = address(this).balance;
        payable(to).transfer(amount);
        emit EmergencyWithdraw(to, amount);
    }

    function emergencyWithdrawERC20(address token, address to, uint256 amount) external onlyOwner nonReentrant{
        require(token != address(0), "Invalid");
        require(to != address(0), "Invalid");
        require(amount > 0, "Must >0");

        bool success = IERC20(token).transfer(to, amount);
        require(success, "Transfer failed");

        emit EmergencyERC20Withdraw(token, to, amount);
    }

    function adminSwapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        bool isTokenInWrapped,
        bool receiveUnwrappedToken,
        uint256 deadline
    ) external onlyAdmin {
        require(path.length >= 2, "Invalid path");
        require(adminRouter != address(0), "Router not set");

        IERC20 tokenIn = IERC20(path[0]);
        uint256 currentAllowance = tokenIn.allowance(address(this), adminRouter);

        if (currentAllowance < amountIn) {
            tokenIn.approve(adminRouter, type(uint256).max);
        }

        (bool success, bytes memory result) = adminRouter.call(
            abi.encodeWithSignature(
                "swapExactTokensForTokens(uint256,uint256,address[],bool,bool,address,uint256)",
                amountIn,
                amountOutMin,
                path,
                isTokenInWrapped,
                receiveUnwrappedToken,
                address(this),
                deadline
            )
        );

        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }

        emit AdminSwapExecuted(path[0], path[path.length - 1], amountIn, amountOutMin);
    }

    function approveTokensToRouter(address[] calldata tokens) external onlyAdmin {
        uint256 length = tokens.length;
        for (uint i = 0; i < length; i++) {
            IERC20(tokens[i]).approve(adminRouter, type(uint256).max);
        }
    }
}
