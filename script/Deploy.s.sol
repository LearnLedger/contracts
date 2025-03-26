// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "lib/forge-std/src/Script.sol";
import "../src/ProjectLedgerMVP.sol";
import "../src/LLEDUERC20.sol";

/**
 * @title Deploy
 * @notice Foundry script to deploy
 *         1) A new ERC20 token (MyERC20) with the caller as owner
 *         2) A new ProjectLedgerMVP, with the caller as `executor`
 * 
 * Usage:
 *   1) Set your PRIVATE_KEY env var: 
 *      export PRIVATE_KEY=0xYOURPRIVATEKEY
 *   2) Run: forge script script/Deploy.s.sol --rpc-url <RPC_URL> --broadcast
 * 
 * You'll see logs of deployed addresses in your console output.
 */
contract Deploy is Script {
    function run() external {
        // Load deployer's private key from env
        uint256 deployerKey = vm.envUint("EXECUTOR_PRIVATE_KEY");

        // Start broadcasting
        vm.startBroadcast(deployerKey);

        // 1) Deploy MyERC20
        LLEDUERC20 myToken = new LLEDUERC20(
            "Learn Ledger Token", 
            "LLEDU", 
            1_000_000 * 10**18,  // initial supply
            msg.sender          // owner
        );
        console2.log("LLEDU ERC20 deployed at:", address(myToken));

        // 2) Deploy ProjectLedgerMVP
        ProjectLedgerMVP ledger = new ProjectLedgerMVP(msg.sender);
        console2.log("ProjectLedgerMVP deployed at:", address(ledger));

        // Optionally, you might whitelist `myToken` in the ledger:
        ledger.setTokenAllowed(address(myToken), true);

        // Stop broadcasting
        vm.stopBroadcast();
    }
}
