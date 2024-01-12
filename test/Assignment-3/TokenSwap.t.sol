// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Test } from "forge-std/Test.sol";
import { console } from "forge-std/console.sol";
import { TokenSwap } from "../../src/Assignment-3/TokenSwap.sol";
import { MockERC20 } from "../../src/Assignment-3/MockERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TokenSwapTest is Test {
    TokenSwap tokenSwap;
    MockERC20 tokenA;
    MockERC20 tokenB;
    uint256 exchangeRate = 100;

    function setUp() public {
        tokenA = new MockERC20("Token A", "TKNA");
        tokenB = new MockERC20("Token B", "TKNB");
        tokenSwap = new TokenSwap(IERC20(address(tokenA)), IERC20(address(tokenB)), exchangeRate);

        tokenA.mint(address(this), 1000 ether);
        tokenB.mint(address(this), 1000 ether);

        tokenA.mint(address(tokenSwap), 1000 ether);
        tokenB.mint(address(tokenSwap), 1000 ether);

        tokenA.approve(address(tokenSwap), 1000 ether);
        tokenB.approve(address(tokenSwap), 1000 ether);
    }

    // test to verify the correct initialization of Token A address
    function testInitializationTokenA() public {
        assertEq(address(tokenSwap.tokenA()), address(tokenA), "Token A address does not match");
    }

    // test to verify the correct initialization of Token B address
    function testInitializationTokenB() public {
        assertEq(address(tokenSwap.tokenB()), address(tokenB), "Token B address does not match");
    }

    // test to verify that the exchange rate is set correctly
    function testInitializationExchangeRate() public {
        assertEq(tokenSwap.exchangeRate(), exchangeRate, "Exchange rate does not match");
    }

    // test to check swap from token A to token B
    function testSwapAforB() public {
        uint256 initialBalanceA = tokenA.balanceOf(address(this));
        uint256 initialBalanceB = tokenB.balanceOf(address(this));

        uint256 amountA = 10 ether;

        tokenSwap.swapAforB(amountA);

        uint256 finalBalanceA = initialBalanceA - amountA;
        uint256 finalBalanceB = initialBalanceB + (amountA * exchangeRate);

        assertEq(tokenA.balanceOf(address(this)), finalBalanceA, "Incorrect Token A balance after swap");
        assertEq(tokenB.balanceOf(address(this)), finalBalanceB, "Incorrect Token B balance after swap");
    }

    // test to check swap from token B to token A
    function testSwapBforA() public {
        uint256 initialBalanceA = tokenA.balanceOf(address(this));
        uint256 initialBalanceB = tokenB.balanceOf(address(this));

        uint256 amountB = 10 ether;

        tokenSwap.swapBforA(amountB);

        uint256 finalBalanceA = initialBalanceA + (amountB / exchangeRate);
        uint256 finalBalanceB = initialBalanceB - amountB;

        assertEq(tokenA.balanceOf(address(this)), finalBalanceA, "Incorrect Token A balance after swap");
        assertEq(tokenB.balanceOf(address(this)), finalBalanceB, "Incorrect Token B balance after swap");
    }

    // test swap with insufficient balance
    function testSwapWithInsufficientBalance() public {
        uint256 userBalanceA = tokenA.balanceOf(address(this));
        uint256 amountA = userBalanceA + 1 ether;

        try tokenSwap.swapAforB(amountA) {
            fail("swapAforB did not fail with insufficient balance");
        } catch Error(string memory reason) {
            assertEq(reason, "Insufficient Token A balance", "Failed for unexpected reason");
        }
    }

    // test swap without approval
    function testSwapWithoutApproval() public {
        tokenA.approve(address(tokenSwap), 0);

        uint256 amountA = 10 ether;

        try tokenSwap.swapAforB(amountA) {
            fail("swapAforB did not fail without approval");
        } catch Error(string memory reason) {
            assertEq(reason, "Insufficient allowance for Token A", "Failed for unexpected reason");
        }
    }

    // exchange rate swap test for token A to token B
    function testExchangeRateAdherenceSwapAforB() public {
        uint256 initialBalanceB = tokenB.balanceOf(address(this));
        uint256 amountA = 10 ether;
        uint256 expectedAmountB = initialBalanceB + (amountA * exchangeRate);

        tokenSwap.swapAforB(amountA);
        
        assertEq(tokenB.balanceOf(address(this)), expectedAmountB, "Exchange rate not adhered to in swapAforB");
    }

    // exchange rate swap test for token B to token A
    function testExchangeRateAdherenceSwapBforA() public {
        uint256 initialBalanceA = tokenA.balanceOf(address(this));
        uint256 amountB = 10 ether;
        uint256 expectedAmountA = initialBalanceA + (amountB / exchangeRate);

        tokenSwap.swapBforA(amountB);
        
        assertEq(tokenA.balanceOf(address(this)), expectedAmountA, "Exchange rate not adhered to in swapBforA");
    }

    // test fail due to low contract balance
    function testSwapFailureDueToContractBalance() public {
        uint256 contractBalanceB = tokenB.balanceOf(address(tokenSwap));
        uint256 transferAmount = contractBalanceB - 5 ether;

        vm.startPrank(address(tokenSwap));
        tokenB.approve(address(this), transferAmount);
        vm.stopPrank();

        tokenB.transferFrom(address(tokenSwap), address(this), transferAmount);

        uint256 amountA = 10 ether;

        try tokenSwap.swapAforB(amountA) {
            fail("swapAforB did not fail despite contract's insufficient Token B balance");
        } catch Error(string memory reason) {
            assertEq(reason, "Insufficient Token B balance in contract", "Failed for unexpected reason");
        }
    }

    // when contract balance is exactly equal to swap amount
    function testSwapWithExactTokenBalance() public {
        uint256 amountA = 10 ether;
        uint256 amountB = amountA * exchangeRate;

        uint256 currentBalanceB = tokenB.balanceOf(address(tokenSwap));
        if (currentBalanceB > amountB) {
            tokenB.transferFrom(address(tokenSwap), address(this), currentBalanceB - amountB);
        } else if (currentBalanceB < amountB) {
            tokenB.transferFrom(address(this), address(tokenSwap), amountB - currentBalanceB);
        }

        tokenSwap.swapAforB(amountA);

        uint256 postSwapBalanceB = tokenB.balanceOf(address(tokenSwap));
        assertEq(postSwapBalanceB, 0, "Contract should have zero Token B after swap");
    }

    // test swaps with very small amounts
    function testSwapWithSmallAmounts() public {
        uint256 smallAmountA = 1;
        uint256 expectedAmountB = smallAmountA * exchangeRate;

        tokenSwap.swapAforB(smallAmountA);

        assertTrue(tokenB.balanceOf(address(this)) >= expectedAmountB, "Swap failed with small amounts");
    }

    // test swaps with low token balance in contract
    function testSwapWithLowContractBalance() public {
        uint256 contractBalanceB = tokenB.balanceOf(address(tokenSwap));
        vm.startPrank(address(tokenSwap));
        tokenB.approve(address(this), contractBalanceB);
        vm.stopPrank();

        tokenB.transferFrom(address(tokenSwap), address(this), contractBalanceB - 1 ether);

        uint256 amountA = 10 ether;
        uint256 expectedAmountB = amountA * exchangeRate;

        try tokenSwap.swapAforB(amountA) {
            uint256 newBalanceB = tokenB.balanceOf(address(this));
            assertTrue(newBalanceB >= expectedAmountB, "Swap failed with low contract token balance");
        } catch Error(string memory reason) {
            assertEq(reason, "Insufficient Token B balance in contract", "Swap should fail due to low contract balance");
        }
    }
}
