// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "../src/ProjectLedgerMVP.sol";
import "../src/LLEDUERC20.sol";

contract ProjectLedgerTestnetTest is Test {
    // Contract addresses (from deployment)
    address constant LLEDU_TOKEN = 0xbFf8fFA1e000Bfd712E0A97583E169aa307544e4;
    address constant PROJECT_LEDGER = 0xc3F785e76e0E07daa7FdE8c2f190bcb8f11a429F;
    
    // Wallet addresses
    address constant EXECUTOR = 0xB92749d0769EB9fb1B45f2dE0CD51c97aa220f93;
    address constant TARGET_WALLET = 0xDC17577cb8A3e647c49a8d4717D6819D28932bAf;
    address constant FREELANCER_WALLET = 0xB75682F7bBa3caB29972452DA8737AebFf684e39;
    string constant RPC_URL = "https://rpc.open-campus-codex.gelato.digital";
    // Chain ID for testnet
    uint256 constant CHAIN_ID = 656476; // Porcini testnet
    
    // Contract instances
    LLEDUERC20 token;
    ProjectLedgerMVP ledger;
    
    // Test variables
    bytes32 projectId;
    bytes32 submissionId;
    uint256 projectAmount = 100 * 10**18; // 100 tokens with 18 decimals
    
    function setUp() public {
        // Connect to the testnet
        vm.createSelectFork(RPC_URL, CHAIN_ID);
        
        // Connect to the deployed contracts
        token = LLEDUERC20(LLEDU_TOKEN);
        ledger = ProjectLedgerMVP(PROJECT_LEDGER);
        
        // Set up the executor's private key for signing transactions
        uint256 executorPrivateKey = vm.envUint("EXECUTOR_PRIVATE_KEY");
        vm.startPrank(EXECUTOR, EXECUTOR);
        
        // Make sure the token is whitelisted
        ledger.setTokenAllowed(LLEDU_TOKEN, true);
        
        vm.stopPrank();
    }
    
    function testRealProjectWorkflow() public {
        // Check initial token balance of executor
        uint256 executorInitialBalance = token.balanceOf(EXECUTOR);
        console.log("Executor initial LLEDU balance:", executorInitialBalance / 10**18);
        
        // Transfer half of the tokens to TARGET_WALLET
        uint256 transferAmount = executorInitialBalance / 2;
        vm.startPrank(EXECUTOR);
        token.transfer(TARGET_WALLET, transferAmount);
        
        // Check both balances after transfer
        console.log("Executor LLEDU balance after transfer:", token.balanceOf(EXECUTOR) / 10**18);
        console.log("Target wallet LLEDU balance:", token.balanceOf(TARGET_WALLET) / 10**18);
        
        // Register TARGET_WALLET as a company
        ledger.registerAsCompanyFor(TARGET_WALLET);
        
        // Register FREELANCER_WALLET as a freelancer
        ledger.registerAsFreelancerFor(FREELANCER_WALLET);
        vm.stopPrank();
        
        // Approve tokens from TARGET_WALLET to ProjectLedger contract
        vm.startPrank(TARGET_WALLET);
        token.approve(address(ledger), projectAmount);
        
        // Create a project using TARGET_WALLET
        projectId = ledger.createProject(LLEDU_TOKEN, projectAmount);
        console.log("Project created with ID (bytes32):", vm.toString(projectId));
        
        // Check balances after project creation
        console.log("Target wallet LLEDU balance after project creation:", token.balanceOf(TARGET_WALLET) / 10**18);
        console.log("ProjectLedger contract LLEDU balance:", token.balanceOf(address(ledger)) / 10**18);
        vm.stopPrank();
        
        // Make a submission on behalf of FREELANCER_WALLET
        vm.startPrank(EXECUTOR);
        submissionId = ledger.createSubmissionFor(FREELANCER_WALLET, projectId);
        console.log("Submission created with ID (bytes32):", vm.toString(submissionId));
        
        // Check balances before approval
        console.log("Freelancer wallet LLEDU balance before approval:", token.balanceOf(FREELANCER_WALLET) / 10**18);
        
        // Approve the submission on behalf of TARGET_WALLET
        ledger.approveSubmissionFor(TARGET_WALLET, submissionId);
        console.log("Submission approved");
        
        // Check final balances after approval
        console.log("Freelancer wallet LLEDU balance after approval:", token.balanceOf(FREELANCER_WALLET) / 10**18);
        console.log("ProjectLedger contract LLEDU balance after approval:", token.balanceOf(address(ledger)) / 10**18);
        vm.stopPrank();
        
        // Final summary
        console.log("----------------------------------------");
        console.log("Final Token Balances Summary (in LLEDU):");
        console.log("Executor:", token.balanceOf(EXECUTOR) / 10**18);
        console.log("Target Wallet:", token.balanceOf(TARGET_WALLET) / 10**18);
        console.log("Freelancer Wallet:", token.balanceOf(FREELANCER_WALLET) / 10**18);
        console.log("ProjectLedger Contract:", token.balanceOf(address(ledger)) / 10**18);
    }
} 