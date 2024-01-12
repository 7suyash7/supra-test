// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import { TokenSwap } from "../../src/Assignment-3/TokenSwap.sol";
import { console } from "forge-std/console.sol";
import { MockERC20 } from "../../src/Assignment-3/MockERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TokenSwapScript is Script {
    TokenSwap tokenSwap;
    MockERC20 tokenA;
    MockERC20 tokenB;
    uint256 exchangeRate = 100;
    
    function setUp() public {
        tokenA = new MockERC20("Token A", "TKNA");
        tokenB = new MockERC20("Token B", "TKNB");

        // deploy TokenSwap contract
        tokenSwap = new TokenSwap(IERC20(address(tokenA)), IERC20(address(tokenB)), exchangeRate);

        // mint tokens for the script runner
        tokenA.mint(address(this), 1000 ether);
        tokenB.mint(address(this), 1000 ether);
        console.log("Minted tokens to the script runner");

        // mint tokens to the TokenSwap contract
        tokenA.mint(address(tokenSwap), 50000 ether);
        tokenB.mint(address(tokenSwap), 50000 ether);
        console.log("Minted tokens to the TokenSwap contract");
    }

    function run() public {
        // approve TokenSwap contract to spend tokens on behalf of script runner
        tokenA.approve(address(tokenSwap), 1000 ether);
        tokenB.approve(address(tokenSwap), 1000 ether);
        console.log("Approved TokenSwap contract to spend tokens");

        // perform a swap from Token A to Token B
        uint256 swapAmountA = 10 ether;
        console.log("Swapping", swapAmountA, "Token A for Token B");
        tokenSwap.swapAforB(swapAmountA);

        // log balances after swap
        uint256 balanceAAfter = tokenA.balanceOf(address(this));
        uint256 balanceBAfter = tokenB.balanceOf(address(this));
        console.log("Balance of Token A after swap:", balanceAAfter);
        console.log("Balance of Token B after swap:", balanceBAfter);
    }
}
