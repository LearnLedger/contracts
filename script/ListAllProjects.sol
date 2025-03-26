// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import "../src/ProjectLedgerMVP.sol";

/**
 * @title ListAllProjects
 * @notice Forge script to try to find existing projects using various approaches
 * 
 * Usage:
 *   forge script script/ListAllProjects.sol:ListAllProjects --rpc-url <RPC_URL> 
 */
contract ListAllProjects is Script {
    // Contract addresses from deployment
    address public constant PROJECT_LEDGER = 0xc3F785e76e0E07daa7FdE8c2f190bcb8f11a429F;
    address public constant COMPANY_WALLET = 0xDC17577cb8A3e647c49a8d4717D6819D28932bAf;
    address public constant LLEDU_TOKEN = 0x29668302bf1E11FDc0CC2E01aAEC1e10966F779e;
    
    // Contract instance
    ProjectLedgerMVP ledger;
    
    function setUp() public {
        // Initialize contract instance
        ledger = ProjectLedgerMVP(PROJECT_LEDGER);
    }
    
    function run() public view {
        console.log("PROJECT_LEDGER:", PROJECT_LEDGER);
        console.log("COMPANY_WALLET:", COMPANY_WALLET);
        console.log("LLEDU_TOKEN:", LLEDU_TOKEN);
        
        // Try some approaches to find projects
        console.log("\n1. Checking projects recently created in logs");
        console.log("These are a few project IDs we've seen recently:");
        
        // List of project IDs seen in logs
        bytes32[] memory recentProjectIds = new bytes32[](5);
        recentProjectIds[0] = 0x54746b410d6cd72bb4364c9207cd67c4644333d35a5837ddcbd455d4544dbb74;
        recentProjectIds[1] = 0x2094321b72aa3b8942b2ca850a665ff479445ef72fb4ac537f8236d4a2a456e2;
        recentProjectIds[2] = 0x42c4f8bb273cfaa5b485479059d92c912015d9633ff313f2d7c5519f33f7aa50;
        recentProjectIds[3] = 0x981767e0d5f6713d382ff5e2efdec703dcd847585e8eb2a1ced2654f7560d080;
        // Use explicit conversion to uint256 for the amount
        uint256 projectAmount = 1000 * 10**18;
        recentProjectIds[4] = keccak256(abi.encodePacked(COMPANY_WALLET, LLEDU_TOKEN, projectAmount));
        
        for (uint i = 0; i < recentProjectIds.length; i++) {
            bytes32 id = recentProjectIds[i];
            (bytes32 projId, address owner, address tokenAddr, uint256 reward, bool claimed) = ledger.projects(id);
            
            console.log("\nChecking project ID:", vm.toString(id));
            if (owner != address(0) || reward > 0) {
                console.log("VALID PROJECT FOUND!");
                console.log("  ID:", vm.toString(projId));
                console.log("  Owner:", owner);
                console.log("  Token:", tokenAddr);
                console.log("  Reward:", reward / 10**18, "LLEDU");
                console.log("  Claimed:", claimed);
            } else {
                console.log("No project found with this ID");
            }
        }
        
        // Try to find projects using an alternate approach
        console.log("\n2. Checking if projects can be accessed through a different method");
        console.log("Note: If your contract has a public method to get all projects, modify this script to use it");
        console.log("For now, this script relies on known project IDs");
        
        console.log("\nFor your convenience, here's the command to create a submission for a valid project:");
        console.log("./script/SubmitToProject.sh <project_id>");
        console.log("Replace <project_id> with one of the VALID PROJECT IDs found above");
    }
} 