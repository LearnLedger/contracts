// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import "../src/ProjectLedgerMVP.sol";
import "../src/LLEDUERC20.sol";

/**
 * @title RealTestnetWorkflow
 * @notice Forge script to execute a complete workflow on a real testnet:
 *         1) Transfer LLEDU tokens from executor to company wallet
 *         2) Create a project using the company wallet
 *         3) Submit work as the freelancer
 *         4) Approve the submission from the company wallet
 * 
 * Usage:
 *   forge script script/RealTestnetWorkflow.s.sol --rpc-url <RPC_URL> --broadcast --skip-simulation
 *   Or use the partial workflow script to run individual steps:
 *   ./script/RunPartialWorkflow.sh [1|2|3|4|5] [projectId] [submissionId]
 */
contract RealTestnetWorkflow is Script {
    // Wallet addresses and contract addresses from deployment
    address public constant EXECUTOR = 0xB92749d0769EB9fb1B45f2dE0CD51c97aa220f93;
    address public constant COMPANY_WALLET = 0xDC17577cb8A3e647c49a8d4717D6819D28932bAf;
    address public constant FREELANCER_WALLET = 0xB75682F7bBa3caB29972452DA8737AebFf684e39;
    address public constant LLEDU_TOKEN = 0x29668302bf1E11FDc0CC2E01aAEC1e10966F779e;
    address public constant PROJECT_LEDGER = 0xc3F785e76e0E07daa7FdE8c2f190bcb8f11a429F;
    
    // Contract instances
    LLEDUERC20 token;
    ProjectLedgerMVP ledger;
    
    // Project amount is 1000 LLEDU with 18 decimals
    uint256 public constant PROJECT_AMOUNT = 1000 * 10**18;

    function setUp() public {
        // Initialize contract instances
        token = LLEDUERC20(LLEDU_TOKEN);
        ledger = ProjectLedgerMVP(PROJECT_LEDGER);
        
        // Print the addresses to confirm
        console.log("EXECUTOR:", EXECUTOR);
        console.log("COMPANY_WALLET:", COMPANY_WALLET);
        console.log("FREELANCER_WALLET:", FREELANCER_WALLET);
        console.log("LLEDU_TOKEN:", LLEDU_TOKEN);
        console.log("PROJECT_LEDGER:", PROJECT_LEDGER);
        console.log("Project Amount:", PROJECT_AMOUNT / 10**18, "LLEDU");
    }

    // Run all steps in one go
    function run() public {
        setup();
        printCurrentBalances();
        console.log("Running full workflow...");
        console.log("Note: Some steps may revert if previous steps were already completed");
        executeExecutorOperations();
        bytes32 projectId = executeCompanyOperations();
        bytes32 submissionId = executeFreelancerOperations(projectId);
        executeCompanyApproval(submissionId);
        printFinalBalances();
    }
    
    // Run a specific step by number, with optional projectId and submissionId parameters
    function runStep(uint256 step, bytes32 projectId, bytes32 submissionId) public {
        setup();
        printCurrentBalances();
        
        bytes32 newProjectId;
        bytes32 newSubmissionId;
        
        if (step == 1 || step == 0) {
            console.log("Running executor operations...");
            executeExecutorOperations();
        }
        
        if (step == 2 || step == 0) {
            console.log("Running company operations...");
            newProjectId = executeCompanyOperations();
        }
        
        if (step == 3 || step == 0) {
            console.log("Running freelancer operations...");
            if (projectId == bytes32(0)) {
                console.log("ERROR: Project ID required for freelancer operations");
                console.log("Pass project ID as second parameter: --sig 'runStep(uint256,bytes32,bytes32)' 3 0xYOUR_PROJECT_ID 0x0");
                return;
            }
            newSubmissionId = executeFreelancerOperations(projectId);
        }
        
        if (step == 4 || step == 0) {
            console.log("Running company approval...");
            // For step 4, the submissionId could be in either second or third parameter
            bytes32 submissionIdToUse = submissionId;
            if (submissionIdToUse == bytes32(0) && projectId != bytes32(0)) {
                submissionIdToUse = projectId; // Use the second parameter as submission ID
                console.log("Using second parameter as submission ID");
            }
            
            if (submissionIdToUse == bytes32(0)) {
                console.log("ERROR: Submission ID required for approval");
                console.log("Pass submission ID as second parameter: --sig 'runStep(uint256,bytes32,bytes32)' 4 0xYOUR_SUBMISSION_ID 0x0");
                return;
            }
            executeCompanyApproval(submissionIdToUse);
        }
        
        if (step == 5 || step == 0) {
            console.log("Printing final balances...");
            printFinalBalances();
        }

        if (step == 6) {
            console.log("Listing most recently created projects...");
            listProjects();
        }
    }
    
    function setup() private {
        setUp();
    }
    
    function printCurrentBalances() private view {
        console.log("Current token balances (in LLEDU):");
        console.log("Executor:", token.balanceOf(EXECUTOR) / 10**18);
        console.log("Company Wallet:", token.balanceOf(COMPANY_WALLET) / 10**18);
        console.log("Freelancer Wallet:", token.balanceOf(FREELANCER_WALLET) / 10**18);
        console.log("ProjectLedger Contract:", token.balanceOf(address(ledger)) / 10**18);
        console.log("----------------------------------------");
    }
    
    function executeExecutorOperations() private {
        // Load executor private key
        uint256 executorPrivateKey = vm.envUint("EXECUTOR_PRIVATE_KEY");
        
        // Check initial token balance of executor
        uint256 executorInitialBalance = token.balanceOf(EXECUTOR);
        console.log("Executor initial LLEDU balance:", executorInitialBalance / 10**18);
        
        // Transfer half of the tokens to COMPANY_WALLET (skip if they already have tokens)
        uint256 companyBalance = token.balanceOf(COMPANY_WALLET);
        
        vm.startBroadcast(executorPrivateKey);
        
        // Make sure the token is whitelisted
        if (!isTokenWhitelisted()) {
            ledger.setTokenAllowed(LLEDU_TOKEN, true);
            console.log("Token successfully whitelisted");
        } else {
            console.log("Token already whitelisted");
        }
        
        // Only transfer tokens if company has less than our project amount
        if (companyBalance < PROJECT_AMOUNT * 2) {
            uint256 transferAmount = executorInitialBalance / 2;
            if (transferAmount > 0) {
                token.transfer(COMPANY_WALLET, transferAmount);
                console.log("Transferred %s LLEDU tokens to company wallet", transferAmount / 10**18);
            }
        } else {
            console.log("Company wallet already has sufficient tokens");
        }
        
        // Register the company if needed
        if (!isCompany(COMPANY_WALLET)) {
            ledger.registerAsCompanyFor(COMPANY_WALLET);
            console.log("Company wallet registered");
        } else {
            console.log("Company wallet already registered");
        }
        
        // Register the freelancer if needed
        if (!isFreelancer(FREELANCER_WALLET)) {
            ledger.registerAsFreelancerFor(FREELANCER_WALLET);
            console.log("Freelancer wallet registered");
        } else {
            console.log("Freelancer wallet already registered");
        }
        
        vm.stopBroadcast();
        
        // Display balances after transfer
        console.log("Executor LLEDU balance after transfer:", token.balanceOf(EXECUTOR) / 10**18);
        console.log("Company wallet LLEDU balance:", token.balanceOf(COMPANY_WALLET) / 10**18);
    }
    
    function executeCompanyOperations() private returns (bytes32) {
        // Load company private key
        uint256 companyPrivateKey = vm.envUint("COMPANY_PRIVATE_KEY");
        
        vm.startBroadcast(companyPrivateKey);
        
        // Approve tokens for the project (allows re-approval if needed)
        token.approve(address(ledger), PROJECT_AMOUNT);
        console.log("Company approved %s LLEDU tokens to ProjectLedger", PROJECT_AMOUNT / 10**18);
        
        // Create a project
        bytes32 projectId = ledger.createProject(LLEDU_TOKEN, PROJECT_AMOUNT);
        
        vm.stopBroadcast();
        
        // Display the project ID clearly
        console.log("************************************************");
        console.log("PROJECT CREATED WITH ID:");
        console.log(vm.toString(projectId));
        console.log("SAVE THIS ID FOR STEP 3");
        console.log("************************************************");
        
        // Display balances after project creation
        console.log("Company wallet LLEDU balance after project creation:", token.balanceOf(COMPANY_WALLET) / 10**18);
        console.log("ProjectLedger contract LLEDU balance:", token.balanceOf(address(ledger)) / 10**18);
        
        return projectId;
    }
    
    function executeFreelancerOperations(bytes32 projectId) private returns (bytes32) {
        // Load freelancer private key
        uint256 freelancerPrivateKey = vm.envUint("FREELANCER_PRIVATE_KEY");
        
        console.log("Checking project with ID:", vm.toString(projectId));
        
        // Direct check with lower-level call to see raw data
        (bytes32 id, address owner, address tokenAddr, uint256 reward, bool claimed) = ledger.projects(projectId);
        console.log("Raw project data:");
        console.log("  ID:", vm.toString(id));
        console.log("  Owner:", owner);
        console.log("  Token:", tokenAddr);
        console.log("  Reward:", reward);
        console.log("  Claimed:", claimed);
        
        // More forgiving verification - if we can get any valid data, proceed
        if (owner != address(0) || reward > 0) {
            console.log("Project appears to be valid");
        } else {
            console.log("WARNING: Project does not exist or could not be found");
            console.log("Project ID:", vm.toString(projectId));
            return bytes32(0);
        }
        
        console.log("Creating submission for project:", vm.toString(projectId));
        console.log("Project owner:", owner);
        
        vm.startBroadcast(freelancerPrivateKey);
        
        // Create a submission
        bytes32 submissionId = ledger.createSubmission(projectId);
        
        vm.stopBroadcast();
        
        // Display the submission ID clearly
        console.log("************************************************");
        console.log("SUBMISSION CREATED WITH ID:");
        console.log(vm.toString(submissionId));
        console.log("SAVE THIS ID FOR STEP 4");
        console.log("************************************************");
        
        return submissionId;
    }
    
    function executeCompanyApproval(bytes32 submissionId) private {
        // Load company private key
        uint256 companyPrivateKey = vm.envUint("COMPANY_PRIVATE_KEY");
        
        // Ensure the submission exists before trying to approve
        Submission memory submission = getSubmissionDetails(submissionId);
        if (submission.freelancer == address(0)) {
            console.log("WARNING: Submission does not exist or could not be found");
            console.log("Submission ID:", vm.toString(submissionId));
            return;
        }
        
        if (submission.approved || submission.paid) {
            console.log("Submission already approved or paid");
            console.log("Submission approved:", submission.approved);
            console.log("Submission paid:", submission.paid);
            return;
        }
        
        console.log("Approving submission:", vm.toString(submissionId));
        console.log("Submission freelancer:", submission.freelancer);
        
        vm.startBroadcast(companyPrivateKey);
        
        // Check balance before approval
        console.log("Freelancer wallet LLEDU balance before approval:", token.balanceOf(FREELANCER_WALLET) / 10**18);
        
        // Approve the submission
        ledger.approveSubmission(submissionId);
        console.log("Submission approved");
        
        vm.stopBroadcast();
        
        // Final balances
        console.log("Freelancer wallet LLEDU balance after approval:", token.balanceOf(FREELANCER_WALLET) / 10**18);
        console.log("ProjectLedger contract LLEDU balance after approval:", token.balanceOf(address(ledger)) / 10**18);
    }
    
    function printFinalBalances() private view {
        console.log("----------------------------------------");
        console.log("Final Token Balances Summary (in LLEDU):");
        console.log("Executor:", token.balanceOf(EXECUTOR) / 10**18);
        console.log("Company Wallet:", token.balanceOf(COMPANY_WALLET) / 10**18);
        console.log("Freelancer Wallet:", token.balanceOf(FREELANCER_WALLET) / 10**18);
        console.log("ProjectLedger Contract:", token.balanceOf(address(ledger)) / 10**18);
    }
    
    // Helper functions
    function isTokenWhitelisted() internal view returns (bool) {
        return ledger.tokenList(LLEDU_TOKEN);
    }
    
    function isCompany(address wallet) internal view returns (bool) {
        return ledger.isCompany(wallet);
    }
    
    function isFreelancer(address wallet) internal view returns (bool) {
        return ledger.isFreelancer(wallet);
    }
    
    // Struct definitions to match contract storage
    struct Project {
        bytes32 projectId;
        address projectOwner;
        address token;
        uint256 totalReward;
        bool rewardClaimed;
    }
    
    struct Submission {
        bytes32 submissionId;
        bytes32 projectId;
        address freelancer;
        bool approved;
        bool paid;
    }
    
    function getProjectDetails(bytes32 _projectId) internal view returns (Project memory) {
        (bytes32 id, address owner, address tokenAddr, uint256 reward, bool claimed) = ledger.projects(_projectId);
        return Project(id, owner, tokenAddr, reward, claimed);
    }
    
    function getSubmissionDetails(bytes32 _submissionId) internal view returns (Submission memory) {
        (bytes32 id, bytes32 projId, address freelancer, bool approved, bool paid) = ledger.submissions(_submissionId);
        return Submission(id, projId, freelancer, approved, paid);
    }

    // Helper function to list recently created projects
    function listProjects() public view {
        console.log("Trying to identify recent projects created by company wallet");
        console.log("Company Wallet:", COMPANY_WALLET);
        
        // We'll try some recent project IDs
        // First, try the project ID format used in events
        bytes32 derivedId = keccak256(abi.encodePacked(COMPANY_WALLET, LLEDU_TOKEN, PROJECT_AMOUNT));
        console.log("Derived project ID (using keccak256):", vm.toString(derivedId));
        
        (bytes32 id, address owner, address tokenAddr, uint256 reward, bool claimed) = ledger.projects(derivedId);
        console.log("Project data for derived ID:");
        console.log("  ID:", vm.toString(id));
        console.log("  Owner:", owner);
        console.log("  Token:", tokenAddr);
        console.log("  Reward:", reward);
        console.log("  Claimed:", claimed);
        
        // Also print any available project events
        console.log("\nNote: You can find project IDs in the event logs from Step 2.");
        console.log("Check the transaction receipt for the ProjectCreated event which contains the real project ID.");
    }
} 