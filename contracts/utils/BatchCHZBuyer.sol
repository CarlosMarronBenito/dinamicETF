// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IWCHZ {
    function deposit() external payable;
    function approve(address spender, uint amount) external returns (bool);
}

interface IUniswapV2Router {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        bool isTokenInWrapped,
        bool receiveUnwrappedToken,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

contract BatchCHZBuyerNative {
    address public immutable router;
    address public immutable WCHZ;

    constructor(address _router, address _wchz) {
        router = _router;
        WCHZ = _wchz;
    }

    function swapEqualCHZToMultipleTokens(
        address[] calldata tokensOut,
        uint256 minOutPerToken
    ) external payable {
        require(tokensOut.length > 0, "No tokens provided");

        uint256 share = msg.value / tokensOut.length;

        // Wrap todo el CHZ de una vez
        IWCHZ(WCHZ).deposit{value: msg.value}();
        IWCHZ(WCHZ).approve(router, msg.value);

        for (uint i = 0; i < tokensOut.length; i++) {
            address[] memory path = new address[](2);
            path[0] = WCHZ;
            path[1] = tokensOut[i];

            IUniswapV2Router(router).swapExactTokensForTokens(
                share,
                minOutPerToken,
                path,
                true,   // isTokenInWrapped: estamos usando WCHZ como input
                false,  // receiveUnwrappedToken: queremos el token wrap
                msg.sender,
                block.timestamp + 300
            );
        }
    }

    receive() external payable {}
}
