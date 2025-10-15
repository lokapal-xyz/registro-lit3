// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Script, console } from "forge-std/Script.sol";
import { Lit3Ledger } from "../src/Lit3Ledger.sol";

/**
 * @title Lit3Ledger Interaction Script
 * @author lokapal.eth
 * @notice Script for interacting with deployed Lit3Ledger contracts
 * @dev Use environment variables to specify the action and parameters
 */
contract InteractWithLit3 is Script {
    ////////////
    // Errors //
    ////////////
    error InteractWithLit3__InvalidAction();
    error InteractWithLit3__MissingParameter();
    error InteractWithLit3__ContractNotFound();
    error InteractWithLit3__InvalidIndex();

    ///////////////
    // Constants //
    ///////////////
    string constant ACTION_ARCHIVE = "archive";
    string constant ACTION_ARCHIVE_UPDATED = "archive-updated";
    string constant ACTION_GET_ENTRY = "get-entry";
    string constant ACTION_GET_TOTAL = "get-total";
    string constant ACTION_GET_LATEST = "get-latest";
    string constant ACTION_GET_BATCH = "get-batch";
    string constant ACTION_STATUS = "status";

    function run() public {
        // Get the action to perform
        string memory action = vm.envString("ACTION");
        
        // Load contract address from deployment file or environment
        address contractAddress = _getContractAddress();
        Lit3Ledger lit3 = Lit3Ledger(contractAddress);

        // Route to appropriate action
        if (_compareStrings(action, ACTION_ARCHIVE)) {
            _archiveEntry(lit3);
        } else if (_compareStrings(action, ACTION_ARCHIVE_UPDATED)) {
            _archiveUpdatedEntry(lit3);
        } else if (_compareStrings(action, ACTION_GET_ENTRY)) {
            _getEntry(lit3);
        } else if (_compareStrings(action, ACTION_GET_TOTAL)) {
            _getTotalEntries(lit3);
        } else if (_compareStrings(action, ACTION_GET_LATEST)) {
            _getLatestEntries(lit3);
        } else if (_compareStrings(action, ACTION_GET_BATCH)) {
            _getEntriesBatch(lit3);
        } else if (_compareStrings(action, ACTION_STATUS)) {
            _getStatus(lit3);
        } else {
            revert InteractWithLit3__InvalidAction();
        }
    }

    /**
     * @dev Archives a new entry (requires curator permissions)
     */
    function _archiveEntry(Lit3Ledger lit3) internal {
        string memory title = vm.envString("TITLE");
        string memory source = vm.envString("SOURCE");
        string memory timestamp1 = vm.envString("TIMESTAMP1");
        string memory timestamp2 = vm.envString("TIMESTAMP2");
        string memory curatorNote = vm.envString("CURATOR_NOTE");
        address nftAddress = vm.envAddress("NFT_ADDRESS");
        uint256 nftId = vm.envUint("NFT_ID");
        bytes32 contentHash = vm.envBytes32("CONTENT_HASH");

        console.log("=== ARCHIVING ENTRY ===");
        console.log("Title:", title);
        console.log("Source:", source);
        console.log("Timestamp 1:", timestamp1);
        console.log("Timestamp 2:", timestamp2);
        console.log("Curator Note:", curatorNote);
        console.log("NFT Address:", nftAddress);
        console.log("NFT ID:", nftId);
        console.logBytes32(contentHash);

        vm.startBroadcast();
        lit3.archiveEntry(title, source, timestamp1, timestamp2, curatorNote, nftAddress, nftId, contentHash);
        vm.stopBroadcast();

        console.log("Entry archived successfully!");
        console.log("Total entries now:", lit3.getTotalEntries());
    }

    /**
     * @dev Archives an updated entry and deprecates the previous version
     */
    function _archiveUpdatedEntry(Lit3Ledger lit3) internal {
        string memory title = vm.envString("TITLE");
        string memory source = vm.envString("SOURCE");
        string memory timestamp1 = vm.envString("TIMESTAMP1");
        string memory timestamp2 = vm.envString("TIMESTAMP2");
        string memory curatorNote = vm.envString("CURATOR_NOTE");
        address nftAddress = vm.envAddress("NFT_ADDRESS");
        uint256 nftId = vm.envUint("NFT_ID");
        bytes32 contentHash = vm.envBytes32("CONTENT_HASH");
        uint256 deprecateIndex = vm.envUint("DEPRECATE_INDEX");

        console.log("=== ARCHIVING UPDATED ENTRY ===");
        console.log("Title:", title);
        console.log("Deprecating index:", deprecateIndex);

        vm.startBroadcast();
        lit3.archiveUpdatedEntry(title, source, timestamp1, timestamp2, curatorNote, nftAddress, nftId, contentHash, deprecateIndex);
        vm.stopBroadcast();

        console.log("Updated entry archived and previous version deprecated!");
        console.log("Total entries now:", lit3.getTotalEntries());
    }

    /**
     * @dev Retrieves a specific entry by index
     */
    function _getEntry(Lit3Ledger lit3) internal view {
        uint256 index = vm.envUint("ENTRY_INDEX");
        
        console.log("=== RETRIEVING ENTRY ===");

        Lit3Ledger.Entry memory entry = lit3.getEntry(index);
        _displayEntry(entry, index);
    }

    /**
     * @dev Gets the total number of archived entries
     */
    function _getTotalEntries(Lit3Ledger lit3) internal view {
        uint256 total = lit3.getTotalEntries();
        console.log("=== TOTAL ENTRIES ===");
        console.log("Total archived entries:", total);
    }

    /**
     * @dev Retrieves the latest entries
     */
    function _getLatestEntries(Lit3Ledger lit3) internal view {
        uint256 count = vm.envOr("COUNT", uint256(5));
        
        console.log("=== LATEST ENTRIES ===");
        console.log("Requesting count:", count);

        Lit3Ledger.Entry[] memory entries = lit3.getLatestEntries(count);
        console.log("Retrieved:", entries.length, "entries");
        
        for (uint256 i = 0; i < entries.length; i++) {
            console.log("Entry", i + 1, "of", entries.length);
            _displayEntryBasic(entries[i]);
        }
    }

    /**
     * @dev Retrieves a batch of entries
     */
    function _getEntriesBatch(Lit3Ledger lit3) internal view {
        uint256 startIndex = vm.envUint("START_INDEX");
        uint256 count = vm.envUint("COUNT");
        
        console.log("=== ENTRY BATCH ===");
        console.log("Start Index:", startIndex);
        console.log("Count:", count);

        Lit3Ledger.Entry[] memory entries = lit3.getEntriesBatch(startIndex, count);
        console.log("Retrieved:", entries.length, "entries");
        
        for (uint256 i = 0; i < entries.length; i++) {
            console.log("\n--- Entry at index", startIndex + i, "---");
            _displayEntryBasic(entries[i]);
        }
    }

    /**
     * @dev Gets contract status and information
     */
    function _getStatus(Lit3Ledger lit3) internal view {
        console.log("=== LIT3 LEDGER STATUS ===");
        console.log("Contract Address:", address(lit3));
        console.log("Curator:", lit3.curator());
        console.log("Total Entries:", lit3.getTotalEntries());
        console.log("Current Block:", block.number);
        console.log("Chain ID:", block.chainid);
        
        // Display network name
        if (block.chainid == 8453) {
            console.log("Network: Base Mainnet");
        } else if (block.chainid == 84532) {
            console.log("Network: Base Sepolia");
        } else {
            console.log("Network: Unknown");
        }
    }

    /**
     * @dev Displays complete entry information
     */
    function _displayEntry(Lit3Ledger.Entry memory entry, uint256 index) internal pure {
        console.log("Index:", index);
        console.log("Title:", entry.title);
        console.log("Source:", entry.source);
        console.log("Timestamp 1:", entry.timestamp1);
        console.log("Timestamp 2:", entry.timestamp2);
        console.log("Curator Note:", entry.curatorNote);
        console.log("Deprecated:", entry.deprecated);
        console.log("Version Index:", entry.versionIndex);
        console.log("NFT Address:", entry.nftAddress);
        console.log("NFT ID:", entry.nftId);
        console.logBytes32(entry.contentHash);
    }

    /**
     * @dev Displays basic entry information (for batch operations)
     */
    function _displayEntryBasic(Lit3Ledger.Entry memory entry) internal pure {
        console.log("Title:", entry.title);
        console.log("Source:", entry.source);
        console.log("Version:", entry.versionIndex);
        console.log("Deprecated:", entry.deprecated);
    }

    /**
     * @dev Gets contract address from deployment files or environment
     */
    function _getContractAddress() internal view returns (address) {
        // Try to get from environment variable first
        try vm.envAddress("CONTRACT_ADDRESS") returns (address addr) {
            if (addr != address(0)) {
                return addr;
            }
        } catch {}

        // Try to load from deployment file based on chain ID
        string memory networkName;
        if (block.chainid == 8453) {
            networkName = "base";
        } else if (block.chainid == 84532) {
            networkName = "base-sepolia";
        } else {
            networkName = vm.toString(block.chainid);
        }

        string memory filePath = string.concat("deployments/", networkName, ".json");
        
        try vm.readFile(filePath) returns (string memory file) {
            return vm.parseJsonAddress(file, ".contractAddress");
        } catch {
            revert InteractWithLit3__ContractNotFound();
        }
    }

    /**
     * @dev Utility function to compare strings
     */
    function _compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }
}