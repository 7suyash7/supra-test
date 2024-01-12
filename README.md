# Build using Forge
`forge build`

# Running Tests

## Assignment - 1:
`forge test --match-path test/Assignment-1/TokenSale.t.sol`

## Assignment - 2:
`forge test --match-path test/Assignment-2/DecentralizedVoting.t.sol`

## Assignment - 3:
`forge test --match-path test/Assignment-3/TokenSwap.t.sol`

## Assignment -4:
`forge test --match-path test/Assignment-4/MultiSigWallet.t.sol`

# Running Scripts

#### These scripts are written to demonstrate the basic functionality of each smart contract.

## Assignment - 1:
`forge script script/Assignment-1/TokenSale.s.sol`

## Assignment - 2:
`forge script script/Assignment-2/DecentralizedVoting.s.sol`

## Assignment - 3:
`forge script script/Assignment-3/TokenSwap.s.sol`

## Assignment -4:
`forge script script/Assignment-4/MultiSigWallet.s.sol`

# Running the test suite for all assignments

#### A total of 76 test cases have been written for the four Smart Contracts.
`forge test`

# Assignment - 1: Token Sale Smart Contract

## Design Choices:
1. **Modular**: The contract is structured into distinct sections for presale and public sale, each with dedicated functions and modifiers. This enhances readability, maintainability, and testing.
2. **Use of Modifiers for Function Guarding**: Several modifiers are used to perform common checks, to enforce function preconditions such as ownership, sale period validation, and contribution limits. Makes the code cleaner too.
3. **Immediate Token Distribution**: Tokens are distributed immediately upon receiving contributions during both presale and public sale phases. This choice aligns with common practice in token sales.
4. **Flexible Control over Sales Phases**: The owner can manually activate or deactivate the Presale and Public Sale.
5. **Refund Mechanism**: A refund mechanism is included to protect contributors in case the minimum cap is not reached. Crucial for building trust and credibility in the Token Sale phase.
6. **Separate Contribution Tracking**: Contributions are tracked separately for Presale and Public Sale, as well as individually per address.

## Security Considerations
1. **Reentrancy Protection**
2. **Ownership Restriction**
3. **Checks-Effects-Interactions Pattern**
4. **Limiting Contributions**
5. **Caps on Total Contributions**
6. **Validating Sale Periods**
7. **Ensuring Sufficient Token Balance**

# Assignment - 2: Decentralized Voting System

## Design Choices:
1. **Data Structures**:
   - **Voters**: A mapping from an address to a `Voter` struct is used to store voter information efficiently. This structure allows for quick lookups, additions, and updates for each voter, optimizing the process of verifying voter registration and voting status.
   - **Candidates**: An Array of `Candidate` structs are used to store candidate information. This choice supports dynamic addition of candidates and straightforward retrieval of all candidates details, which is useful for displaying results and managing candidate information.
2. **Function Modifiers**: The `onlyOwner` modifier is used for functions that should be restricted to the contract creator, such as adding candidates.
3. **Event Logging**
4. **Simplicity and Focus**: The smart contract is designed to be straightforward and focused solely on the core functionalities of voter registration, candidate management, and voting. This reduces complexity, making the contract easier to understand and maintain.

## Security Considerations
1. **Reentrancy Attacks Protection**
2. **Access Control**
3. **Input Validation**
4. **Data Integrity**

# Assignment - 3: Token Swap Smart Contract

## Design Choices:
1. **Fixed Exchange Rate**: The exchange rate is set in the constructor and remains constant.
2. **Decoupling Token Swaps**: Separate functions for swapping Token A for Token B and vice versa to enhance clarity and ease of use.
3. **Events for Swaps**

## Security Considerations
1. **Reentrancy Protection**
2. **Balance and Allowance Checks**
3. **Safe Transfer Methods**

# Assignment - 4: Multi Signature Wallet

## Design Choices:
1. **Dynamic Owner Management**: Implemented functions to add and remove owners to provide flexibility in managing access control over time.
2. **Separate Approval and Execution**: Separated the approval and execution of transactions to ensure that no single owner has unilateral control over funds.
3. **Mapping for Approvals**: Using a mapping to track approvals for each transaction is efficient in terms of gas usage as well as data management.
4. **Threshold for Approvals**: The requirement for a minimum number of approvals adds a layer of security, as it necessitates consensus among owners.
5. **Use of Structs for Transactions**: Structs provide a clear and efficient way to handle transaction data within the contract.

## Security Considerations:
1. **Checks-Effects-Interactions Pattern**
2. **Ownership Checks**
3. **Input Validation**
4. **Event Logging**
5. **Handling of Ether**
