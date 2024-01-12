// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {TokenSale} from  "../../src/Assignment-1/TokenSale.sol";
import {MockERC20} from "../../src/Assignment-1/MockERC20.sol";

contract TokenSaleTest is Test {
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

        token = new MockERC20("TestToken", "TT");

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
    }

    // Presale Tests

    // test to activate presale
    function testActivatePresale() public {
        assertFalse(tokenSale.presaleActive());

        tokenSale.activatePresale();

        assertTrue(tokenSale.presaleActive());
    }

    // test to deactivate presale
    function testDeactivatePresale() public {
        tokenSale.activatePresale();
        assertTrue(tokenSale.presaleActive());

        tokenSale.deactivatePresale();

        assertFalse(tokenSale.presaleActive());
    }

    // test successful presale contribution
    function testSuccessfulPresaleContribution() public {
        uint256 initialTokenBalance = token.balanceOf(address(this));
        vm.warp(presaleStartTime);
        tokenSale.activatePresale();

        uint256 contributionAmount = 1 ether;
        vm.deal(address(this), contributionAmount);
        tokenSale.contributeToPresale{value: contributionAmount}();

        uint256 expectedTokenAmount = initialTokenBalance + (contributionAmount * tokenRatePerEther);
        assertEq(token.balanceOf(address(this)), expectedTokenAmount);
        assertEq(tokenSale.presaleRaisedAmount(), contributionAmount);
    }

    // test presale contribution below minimum
    function testFailPresaleContributionBelowMinimum() public {
        vm.warp(presaleStartTime);
        tokenSale.activatePresale();

        uint256 lowContribution = minimumContribution / 2;
        vm.deal(address(this), lowContribution);
        vm.expectRevert(bytes("Not Enough tokens left in the Contract"));
        tokenSale.contributeToPresale{value: lowContribution}();
    }

    // test presale contribution above maximum
    function testFailPresaleContributionAboveMaximum() public {
        vm.warp(presaleStartTime);
        tokenSale.activatePresale();

        uint256 highContribution = maximumContribution * 2;
        vm.deal(address(this), highContribution);
        tokenSale.contributeToPresale{value: highContribution}();
    }

    // test presale cap exceeded
    function testFailPresaleCapExceeded() public {
        vm.warp(presaleStartTime);
        tokenSale.activatePresale();

        uint256 contribution = presaleCap + 1 ether;
        vm.deal(address(this), contribution);
        vm.expectRevert(bytes("PreSale Cap Exceeded!"));
        tokenSale.contributeToPresale{value: contribution}();
    }

    // test trying to contribute after presale ends
    function testFailContributeAfterPresaleEnds() public {
        tokenSale.activatePresale();
        vm.warp(presaleEndTime + 100);

        uint256 contribution = 1 ether;
        vm.deal(address(this), contribution);
        tokenSale.contributeToPresale{value: contribution}();
    }

    // simulating multiple contributions in presale
    function testMultipleContributionsInPresale() public {
        uint256 initialTokenBalance = token.balanceOf(address(this));
        vm.warp(presaleStartTime);
        tokenSale.activatePresale();

        uint256 firstContribution = 1 ether;
        uint256 secondContribution = 2 ether;
        vm.deal(address(this), firstContribution + secondContribution);

        tokenSale.contributeToPresale{value: firstContribution}();
        tokenSale.contributeToPresale{value: secondContribution}();

        uint256 totalContribution = firstContribution + secondContribution;
        uint256 expectedTokenAmount = initialTokenBalance + (totalContribution * tokenRatePerEther);
        assertEq(token.balanceOf(address(this)), expectedTokenAmount);
        assertEq(tokenSale.presaleRaisedAmount(), totalContribution);
    }

    // Public Sale Testsf

    // test to activate public sale
    function testActivatePublicSale() public {
        assertFalse(tokenSale.publicSaleActive());

        vm.warp(publicSaleStartTime);

        tokenSale.activatePublicSale();

        assertTrue(tokenSale.publicSaleActive());
    }

    // test successful public sale contribution
    function testSuccessfulPublicSaleContribution() public {
        uint256 initialTokenBalance = token.balanceOf(address(this));
        vm.warp(publicSaleStartTime);
        tokenSale.activatePublicSale();

        uint256 contributionAmount = 2 ether;
        vm.deal(address(this), contributionAmount);
        tokenSale.contributeToPublicSale{value: contributionAmount}();

        uint256 expectedTokenAmount = initialTokenBalance + (contributionAmount * tokenRatePerEther);
        assertEq(token.balanceOf(address(this)), expectedTokenAmount);
        assertEq(tokenSale.publicSaleRaisedAmount(), contributionAmount);
    }

    // test public sale cap exceeded
    function testFailPublicSaleCapExceeded() public {
        vm.warp(publicSaleStartTime);
        tokenSale.activatePublicSale();

        uint256 contribution = publicSaleCap + 1 ether;
        vm.deal(address(this), contribution);
        tokenSale.contributeToPublicSale{value: contribution}();
    }

    // test public sale contribution below minimum
    function testFailPublicSaleContributionBelowMinimum() public {
        vm.warp(publicSaleStartTime);
        tokenSale.activatePublicSale();

        uint256 lowContribution = minimumContribution / 2;
        vm.deal(address(this), lowContribution);
        tokenSale.contributeToPublicSale{value: lowContribution}();
    }

    // test public sale contribution above maximum
    function testFailPublicSaleContributionAboveMaximum() public {
        vm.warp(publicSaleStartTime);
        tokenSale.activatePublicSale();

        uint256 highContribution = maximumContribution * 2;
        vm.deal(address(this), highContribution);
        tokenSale.contributeToPublicSale{value: highContribution}();
    }

    // test token distribution on public sale contribution
    function testTokenDistributionOnPublicSale() public {
        uint256 initialTokenBalance = token.balanceOf(address(this));
        vm.warp(publicSaleStartTime);
        tokenSale.activatePublicSale();

        uint256 contributionAmount = 3 ether;
        vm.deal(address(this), contributionAmount);
        tokenSale.contributeToPublicSale{value: contributionAmount}();

        uint256 expectedTokenAmount = initialTokenBalance + (contributionAmount * tokenRatePerEther);
        assertEq(token.balanceOf(address(this)), expectedTokenAmount);
    }

    // test to deactivate public sale
    function testDeactivatePublicSale() public {
        vm.warp(publicSaleStartTime);
        tokenSale.activatePublicSale();
        assertTrue(tokenSale.publicSaleActive());

        tokenSale.deactivatePublicSale();
        assertFalse(tokenSale.publicSaleActive());
    }

    // Token Distribution Tests

    // owner token distribution test
    function testTokenDistributionByOwner() public {
        uint256 distributeAmount = 500 * 10 ** 18;
        address recipient = address(1);

        uint256 initialRecipientBalance = token.balanceOf(recipient);

        tokenSale.distributeTokens(recipient, distributeAmount);

        uint256 finalRecipientBalance = token.balanceOf(recipient);
        assertEq(finalRecipientBalance, initialRecipientBalance + distributeAmount);
    }

    // non-owner token distribution test
    function testFailTokenDistributionByNonOwner() public {
        uint256 distributeAmount = 500 * 10 ** 18;
        address recipient = address(1);
        address nonOwner = address(2);

        vm.prank(nonOwner);
        tokenSale.distributeTokens(recipient, distributeAmount);
    }

    // Refund Tests

    // check if owner can successfully enable refunds
    function testEnableRefundsByOwner() public {
        assertFalse(tokenSale.refundEnabled());

        tokenSale.enableRefunds();

        assertTrue(tokenSale.refundEnabled());
    }

    // check if contributors can claim refunds after they are enabled
    function testClaimRefundAfterEnabled() public {
        vm.warp(presaleStartTime);
        tokenSale.activatePresale();
        uint256 contributionAmount = 1 ether;
        vm.deal(address(this), contributionAmount);
        tokenSale.contributeToPresale{value: contributionAmount}();

        tokenSale.deactivatePresale();
        tokenSale.enableRefunds();

        uint256 initialBalance = address(this).balance;
        tokenSale.claimRefund();

        uint256 finalBalance = address(this).balance;
        assertEq(finalBalance, initialBalance + contributionAmount);
    }

    // check that addresses that didn't contribute cannot claim refunds
    function testFailClaimRefundWhenNotEligible() public {
        tokenSale.enableRefunds();

        address nonContributor = address(2);
        vm.prank(nonContributor);
        tokenSale.claimRefund();
    }

    // check if owner can disable refunds
    function testDisableRefundsByOwner() public {
        tokenSale.enableRefunds();
        assertTrue(tokenSale.refundEnabled());

        tokenSale.disableRefunds();

        assertFalse(tokenSale.refundEnabled());
    }

    // check that refunds cannot be claimed after being disabled
    function testFailClaimRefundAfterDisabled() public {
        vm.warp(presaleStartTime);
        tokenSale.activatePresale();
        tokenSale.contributeToPresale{value: 1 ether}();
        tokenSale.enableRefunds();

        tokenSale.disableRefunds();

        tokenSale.claimRefund();
    }
}
