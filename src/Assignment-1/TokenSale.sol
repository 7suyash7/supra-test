// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract TokenSale is ReentrancyGuard{

    // defining variables
    IERC20 public token;
    address public owner;

    uint256 public presaleCap;
    uint256 public publicSaleCap;
    uint256 public minimumContribution;
    uint256 public maximumContribution;

    uint256 public presaleRaisedAmount;
    uint256 public publicSaleRaisedAmount;

    uint256 public presaleStartTime;
    uint256 public presaleEndTime;
    uint256 public publicSaleStartTime;
    uint256 public publicSaleEndTime;

    uint256 public tokenRatePerEther;

    bool public presaleActive;
    bool public publicSaleActive;
    bool public refundEnabled;

    mapping(address => uint256) public contributions;

    // defining the constructor
    constructor(
        IERC20 _token,
        uint256 _presaleCap,
        uint256 _publicSaleCap,
        uint256 _minimumContribution,
        uint256 _maximumContribution,
        uint256 _presaleStartTime,
        uint256 _presaleEndTime,
        uint256 _publicSaleStartTime,
        uint256 _publicSaleEndTime,
        uint256 _tokenRatePerEther
    ) {
        token = _token;
        owner = msg.sender;

        presaleCap = _presaleCap;
        publicSaleCap = _publicSaleCap;
        minimumContribution = _minimumContribution;
        maximumContribution = _maximumContribution;
        presaleStartTime = _presaleStartTime;
        presaleEndTime = _presaleEndTime;
        publicSaleStartTime = _publicSaleStartTime;
        publicSaleEndTime = _publicSaleEndTime;
        tokenRatePerEther = _tokenRatePerEther;

        presaleActive = false;
        publicSaleActive = false;
        refundEnabled = false;
    }

    // defining required modifiers according to the requirements
    modifier onlyOwner() {
        require(msg.sender == owner, "Not the Owner");
        _;
    }

    modifier onlyDuringPreSale {
        require(presaleActive, "Presale is not Active currently");
        require(block.timestamp >= presaleStartTime && block.timestamp <= presaleEndTime, "Outside Presale Period");
        _;
    }

    modifier onlyDuringPublicSale {
        require(publicSaleActive, "Public Sale is not Actice currently");
        require(block.timestamp >= publicSaleStartTime && block.timestamp <= publicSaleEndTime, "Outside Public Sale Period");
        _;
    }

    modifier validContribution {
        require(msg.value >= minimumContribution && msg.value <= maximumContribution, "Contribution out of Bounds");
        _;
    }

    modifier withinPreSaleCap {
        require(presaleRaisedAmount + msg.value <= presaleCap, "PreSale Cap Exceeded!");
        _;
    }

    modifier withinPublicSaleCap {
        require(publicSaleRaisedAmount + msg.value <= publicSaleCap, "Public Sale Cap Exceeded!");
        _;
    }

    modifier refundIsEnabled() {
        require(refundEnabled, "Refunds are not enabled");
        _;
    }
    
    // necessary events
    event PresaleContribution(address indexed contributor, uint256 etherAmount, uint256 tokenAmount);
    event PublicSaleContribution(address indexed contributor, uint256 etherAmount, uint256 tokenAmount);
    event RefundsEnabled();
    event RefundsDisabled();
    event TokensDistributed(address indexed to, uint256 amount);
    event RefundClaimed(address indexed claimant, uint256 amount);
    event PresaleActivated();
    event PresaleDeactivated();
    event PublicSaleActivated();
    event PublicSaleDeactivated();

    // activate presale
    function activatePresale() public onlyOwner {
        presaleActive = true;
        emit PresaleActivated();
    }

    // deactivate presale
    function deactivatePresale() public onlyOwner {
        presaleActive = false;
        emit PresaleDeactivated();
    }

    // activate public sale
    function activatePublicSale() public onlyOwner {
        publicSaleActive = true;
        emit PublicSaleActivated();
    }

    // deactivate public sale
    function deactivatePublicSale() public onlyOwner {
        publicSaleActive = false;
        emit PublicSaleDeactivated();
    }

    // handling contributions during presale phase
    function contributeToPresale() public payable onlyDuringPreSale validContribution withinPreSaleCap {
        uint256 tokenAmount = msg.value * tokenRatePerEther;
        require(token.balanceOf(address(this)) >= tokenAmount, "Not Enough tokens left in the Contract");

        token.transfer(msg.sender, tokenAmount);
        presaleRaisedAmount += msg.value;
        contributions[msg.sender] += msg.value;

        emit PresaleContribution(msg.sender, msg.value, tokenAmount);
    }

    // handling contributions during public sale phase
    function contributeToPublicSale() public payable onlyDuringPublicSale validContribution withinPublicSaleCap {
        uint256 tokenAmount = msg.value * tokenRatePerEther;
        require(token.balanceOf(address(this)) >= tokenAmount, "Not enough Tokens left in the Contract");

        token.transfer(msg.sender, tokenAmount);
        publicSaleRaisedAmount += msg.value;
        contributions[msg.sender] += msg.value;

        emit PublicSaleContribution(msg.sender, msg.value, tokenAmount);
    }

    // allows owner to distribute tokens to a specified address
    function distributeTokens(address to, uint256 amount) public onlyOwner {
        require(token.balanceOf(address(this)) >= amount, "Insufficient token balance in the Contract");
        token.transfer(to, amount);
        emit TokensDistributed((to), amount);
    }

    // enable refunds
    function enableRefunds() public onlyOwner {
        require(!presaleActive && !publicSaleActive, "Sale is Active");
        require(presaleRaisedAmount < presaleCap || publicSaleRaisedAmount < publicSaleCap, "Minimum Cap Reached!");

        refundEnabled = true;
        emit RefundsEnabled();
    }

    // disable refunds
    function disableRefunds() public onlyOwner {
        require(refundEnabled, "Refunds are not Enabled");
        refundEnabled = false;
        emit RefundsDisabled();
    }

    // allow refunds to be claimed
    function claimRefund() public nonReentrant refundIsEnabled {
        uint256 contributedAmount = contributions[msg.sender];
        require(contributedAmount > 0, "No contributions found for Sender");

        contributions[msg.sender] = 0;
        (bool sent, ) = payable(msg.sender).call{value: contributedAmount}("");
        require(sent, "Failed to send Ether");
        emit RefundClaimed(msg.sender, contributedAmount);
    }
}
