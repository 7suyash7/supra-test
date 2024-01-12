// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract TokenSwap is ReentrancyGuard {
    // define variables
    IERC20 public tokenA;
    IERC20 public tokenB;
    uint256 public exchangeRate;

    // define constructor
    constructor(IERC20 _tokenA, IERC20 _tokenB, uint256 _exchangeRate) {
        tokenA = _tokenA;
        tokenB = _tokenB;
        exchangeRate = _exchangeRate;
    }

    // events
    event Swap(address indexed user, address tokenIn, address tokenOut, uint256 amountIn, uint256 amountOut);

    // swap token A for token B
    function swapAforB(uint256 amountA) external nonReentrant {
        uint256 amountB = amountA * exchangeRate;
        require(tokenA.balanceOf(msg.sender) >= amountA, "Insufficient Token A balance");
        require(tokenA.allowance(msg.sender, address(this)) >= amountA, "Insufficient allowance for Token A");
        require(tokenB.balanceOf(address(this)) >= amountB, "Insufficient Token B balance in contract");

        _safeTransferFrom(tokenA, msg.sender, address(this), amountA);
        _safeTransfer(tokenB, msg.sender, amountB);

        emit Swap(msg.sender, address(tokenA), address(tokenB), amountA, amountB);
    }

    // swap token B for token A
    function swapBforA(uint256 amountB) external nonReentrant {
        uint256 amountA = amountB / exchangeRate;
        require(tokenB.balanceOf(msg.sender) >= amountB, "Insufficient Token B balance");
        require(tokenB.allowance(msg.sender, address(this)) >= amountB, "Insufficient allowance for Token B");
        require(tokenA.balanceOf(address(this)) >= amountA, "Insufficient Token A balance in contract");

        _safeTransferFrom(tokenB, msg.sender, address(this), amountB);
        _safeTransfer(tokenA, msg.sender, amountA);

        emit Swap(msg.sender, address(tokenB), address(tokenA), amountB, amountA);
    }

    // safe transfer functions
    function _safeTransferFrom(IERC20 token, address from, address to, uint256 amount) private {
        bool sent = token.transferFrom(from, to, amount);
        require(sent, "Token transfer failed");
    }

    function _safeTransfer(IERC20 token, address to, uint256 amount) private {
        bool sent = token.transfer(to, amount);
        require(sent, "Token transfer failed");
    }
}
