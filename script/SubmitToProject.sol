// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import "../src/ProjectLedgerMVP.sol";
import "../src/LLEDUERC20.sol";

/**
 * @title SubmitToProject
 * @notice Forge script to submit to a project by its ID
 * 
 * Usage:
 *   forge script script/SubmitToProject.sol:SubmitToProject --sig "run(bytes32)" <PROJECT_ID> --rpc-url <RPC_URL> --broadcast --skip-simulation
 */
contract SubmitToProject is Script {
    // Contract addresses from deployment
    address public constant PROJECT_LEDGER = 0xc3F785e76e0E07daa7FdE8c2f190bcb8f11a429F;
    address public constant FREELANCER_WALLET = 0xB75682F7bBa3caB29972452DA8737AebFf684e39;
    
    // Contract instance
    ProjectLedgerMVP ledger;
    
    function setUp() public {
        // Initialize contract instance
        ledger = ProjectLedgerMVP(PROJECT_LEDGER);
        
        console.log("PROJECT_LEDGER:", PROJECT_LEDGER);
        console.log("FREELANCER_WALLET:", FREELANCER_WALLET);
    }
    
    function run(bytes32 projectId) public {
        uint256 freelancerPrivateKey = vm.envUint("FREELANCER_PRIVATE_KEY");
        
        console.log("Attempting to submit to project with ID:");
        console.log(vm.toString(projectId));
        
        // Create submission as freelancer
        vm.startBroadcast(freelancerPrivateKey);
        
        // Create a submission
        bytes32 submissionId = ledger.createSubmission(projectId);
        
        vm.stopBroadcast();
        
        // Display the submission ID clearly
        console.log("************************************************");
        console.log("SUBMISSION CREATED WITH ID:");
        console.log(vm.toString(submissionId));
        console.log("SAVE THIS ID FOR APPROVAL");
        console.log("************************************************");
    }
} 