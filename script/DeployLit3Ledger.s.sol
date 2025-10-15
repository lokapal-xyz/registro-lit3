// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Script, console } from "forge-std/Script.sol";
import { Lit3Ledger } from "../src/Lit3Ledger.sol";

contract DeployLit3Ledger is Script {
    error DeployLit3Ledger__NotCurator();
    
    function run() public returns (Lit3Ledger) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        
        Lit3Ledger lit3Ledger = new Lit3Ledger();
        
        vm.stopBroadcast();
        
        // Log deployment information
        console.log("=== LIT3 LEDGER DEPLOYMENT ===");
        console.log("Contract deployed to:", address(lit3Ledger));
        console.log("Deployed by (Curator):", msg.sender);
        console.log("Block number:", block.number);
        console.log("Chain ID:", block.chainid);
        console.log("Deployment timestamp:", block.timestamp);
        
        // Verify the curator is set correctly
        address curator = lit3Ledger.curator();
        if (curator != msg.sender) {
            revert DeployLit3Ledger__NotCurator();
        }
        
        console.log("=== DEPLOYMENT COMPLETE ===");
        
        return lit3Ledger;
    }
}