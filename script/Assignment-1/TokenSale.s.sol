// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {TokenSale} from "../../src/Assignment-1/TokenSale.sol";
import {MockERC20} from "../../src/Assignment-1/MockERC20.sol";
import "forge-std/console.sol";

contract TokenSaleScript is Script {
    TokenSale tokenSale;
    MockERC20 token;
    address owner;

    uint256 presaleCap = 100 ether;
    uint256 publicSaleCap = 200 ether;
    uint256 minimumContribution = 0.01 ether;
    uint256 maximumContribution = 10 ether;
    uint256 constant START_TIME = 100000;
    uint256 presaleStartTime = START_TIME;
    uint256 presaleEndTime = START_TIME + 1 days;
    uint256 publicSaleStartTime = START_TIME + 2 days;
    uint256 publicSaleEndTime = START_TIME + 3 days;
    uint256 tokenRatePerEther = 1000;

    receive() external payable {}

    function setUp() public {
        owner = address(this);

        console.log("Deploying MockERC20 and TokenSale contracts");
        token = new MockERC20("TestToken", "TT");

        vm.startPrank(owner);
        token.mint(address(this), 1000000 * 10 ** 18);
        tokenSale = new TokenSale(
            IERC20(address(token)),
            presaleCap,
            publicSaleCap,
            minimumContribution,
            maximumContribution,
            presaleStartTime,
            presaleEndTime,
            publicSaleStartTime,
            publicSaleEndTime,
            tokenRatePerEther
        );

        token.mint(address(tokenSale), 1000000 * 10 ** 18);
        vm.stopPrank();

        console.log("Setup complete");
    }

    function run() public {
        console.log("Starting script run");

        // Presale setup
        vm.warp(presaleStartTime);
        console.log("Blockchain time set to presale start time");

        vm.broadcast(owner);
        tokenSale.activatePresale();
        console.log("Presale activated");

        // User1 contributes to presale
        address user1 = vm.addr(1);
        vm.deal(user1, 1 ether);
        vm.broadcast(user1);
        tokenSale.contributeToPresale{value: 1 ether}();
        console.log("User1 contributed to presale");

        // Deactivate presale
        vm.warp(presaleEndTime + 1);
        vm.broadcast(owner);
        tokenSale.deactivatePresale();
        console.log("Presale deactivated");

        // Public sale setup
        vm.warp(publicSaleStartTime);
        console.log("Blockchain time set to public sale start time");

        vm.broadcast(owner);
        tokenSale.activatePublicSale();
        console.log("Public sale activated");

        // User2 contributes to public sale
        address user2 = vm.addr(2);
        vm.deal(user2, 2 ether);
        vm.broadcast(user2);
        tokenSale.contributeToPublicSale{value: 2 ether}();
        console.log("User2 contributed to public sale");

        // Deactivate public sale
        vm.warp(publicSaleEndTime + 1);
        vm.broadcast(owner);
        tokenSale.deactivatePublicSale();
        console.log("Public sale deactivated");

        // Token distribution and refund management
        vm.broadcast(owner);
        tokenSale.distributeTokens(vm.addr(3), 10000 * 10 ** 18);
        console.log("Tokens distributed to a specific address");

        vm.broadcast(owner);
        tokenSale.enableRefunds();
        console.log("Refunds enabled");

        vm.broadcast(user1);
        tokenSale.claimRefund();
        console.log("User1 claimed a refund");

        vm.broadcast(owner);
        tokenSale.disableRefunds();
        console.log("Refunds disabled");

        console.log("Script run complete");
    }
}
