// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import "../src/ProjectLedgerMVP.sol";
import "../src/LLEDUERC20.sol";

/**
 * @title ApproveSubmission
 * @notice Forge script to approve a submission by its ID
 * 
 * Usage:
 *   forge script script/ApproveSubmission.sol:ApproveSubmission --sig "run(bytes32)" <SUBMISSION_ID> --rpc-url <RPC_URL> --broadcast --skip-simulation
 *   forge script script/ApproveSubmission.sol:ApproveSubmission --sig "checkSubmission(bytes32)" <SUBMISSION_ID> --rpc-url <RPC_URL>
 */
contract ApproveSubmission is Script {
    // Contract addresses from deployment
    address public constant PROJECT_LEDGER = 0xc3F785e76e0E07daa7FdE8c2f190bcb8f11a429F;
    address public constant COMPANY_WALLET = 0xDC17577cb8A3e647c49a8d4717D6819D28932bAf;
    address public constant FREELANCER_WALLET = 0xB75682F7bBa3caB29972452DA8737AebFf684e39;
    address public constant LLEDU_TOKEN = 0x29668302bf1E11FDc0CC2E01aAEC1e10966F779e;
    
    // Contract instances
    ProjectLedgerMVP ledger;
    LLEDUERC20 token;
    
    // Submission struct
    struct Submission {
        bytes32 id;
        bytes32 projectId;
        address freelancer;
        bool approved;
        bool paid;
    }
    
    function setUp() public {
        // Initialize contract instances
        ledger = ProjectLedgerMVP(PROJECT_LEDGER);
        token = LLEDUERC20(LLEDU_TOKEN);
        
        console.log("PROJECT_LEDGER:", PROJECT_LEDGER);
        console.log("COMPANY_WALLET:", COMPANY_WALLET);
        console.log("FREELANCER_WALLET:", FREELANCER_WALLET);
    }
    
    // Check submission details without attempting to approve
    function checkSubmission(bytes32 submissionId) public view {
        console.log("Checking submission with ID:");
        console.log(vm.toString(submissionId));
        
        // Get submission details
        (bytes32 id, bytes32 projectId, address freelancer, bool approved, bool paid) = ledger.submissions(submissionId);
        
        console.log("Submission details:");
        console.log("  ID:", vm.toString(id));
        console.log("  Project ID:", vm.toString(projectId));
        console.log("  Freelancer:", freelancer);
        console.log("  Approved:", approved);
        console.log("  Paid:", paid);
        
        // Get project details
        (bytes32 projId, address owner, address tokenAddr, uint256 reward, bool claimed) = ledger.projects(projectId);
        
        console.log("Associated project details:");
        console.log("  ID:", vm.toString(projId));
        console.log("  Owner:", owner);
        console.log("  Token:", tokenAddr);
        console.log("  Reward:", reward / 10**18, "LLEDU");
        console.log("  Claimed:", claimed);
        
        console.log("Authorization check:");
        console.log("  Company wallet:", COMPANY_WALLET);
        console.log("  Project owner:", owner);
        console.log("  Can approve:", owner == COMPANY_WALLET);
        
        // Balances
        console.log("Current balances:");
        console.log("  Freelancer wallet LLEDU balance:", token.balanceOf(freelancer) / 10**18);
        console.log("  ProjectLedger contract LLEDU balance:", token.balanceOf(address(ledger)) / 10**18);
    }
    
    function run(bytes32 submissionId) public {
        uint256 companyPrivateKey = vm.envUint("COMPANY_PRIVATE_KEY");
        
        console.log("Attempting to approve submission with ID:");
        console.log(vm.toString(submissionId));
        
        // Check submission details first
        (bytes32 id, bytes32 projectId, address freelancer, bool approved, bool paid) = ledger.submissions(submissionId);
        
        console.log("Submission details:");
        console.log("  Project ID:", vm.toString(projectId));
        console.log("  Freelancer:", freelancer);
        console.log("  Approved:", approved);
        console.log("  Paid:", paid);
        
        // Get project details
        (bytes32 projId, address owner, address tokenAddr, uint256 reward, bool claimed) = ledger.projects(projectId);
        
        console.log("Project owner:", owner);
        console.log("Company wallet:", COMPANY_WALLET);
        
        // Check if company wallet is the owner
        if (owner != COMPANY_WALLET) {
            console.log("ERROR: Company wallet is not the owner of this project!");
            console.log("Project owner:", owner);
            console.log("Company wallet:", COMPANY_WALLET);
            return;
        }
        
        // Check balances before approval
        console.log("Balances before approval:");
        console.log("Freelancer wallet LLEDU balance:", token.balanceOf(freelancer) / 10**18);
        console.log("ProjectLedger contract LLEDU balance:", token.balanceOf(address(ledger)) / 10**18);
        
        vm.startBroadcast(companyPrivateKey);
        
        // Approve the submission
        ledger.approveSubmission(submissionId);
        
        vm.stopBroadcast();
        
        // Display completion message
        console.log("************************************************");
        console.log("SUBMISSION APPROVED SUCCESSFULLY!");
        console.log("************************************************");
        
        // Check balances after approval
        console.log("Balances after approval:");
        console.log("Freelancer wallet LLEDU balance:", token.balanceOf(freelancer) / 10**18);
        console.log("ProjectLedger contract LLEDU balance:", token.balanceOf(address(ledger)) / 10**18);
    }
} 