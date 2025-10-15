// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/**
 * @title Lit3 Ledger
 * @author lokapal.eth
 * @notice This contract stores metadata entries for literary artifacts. Only the Curator is allowed to add, update, or deprecate entries.
 * @notice The full content is stored externally. This contract maintains the cryptographic and narrative record.
 */

contract Lit3Ledger {
    ////////////
    // Errors //
    ////////////
    error Lit3Ledger__NotCurator();
    error Lit3Ledger__NotZeroAddress();
    error Lit3Ledger__EntryDoesNotExist();
    error Lit3Ledger__StartIndexOutOfBounds();
    error Lit3Ledger__EntryAlreadyDeprecated();
    error Lit3Ledger__NotPendingCurator();


    ///////////
    // Types //
    ///////////
    struct Entry {
        string title;
        string source;
        string timestamp1;
        string timestamp2;
        string curatorNote;
        bool deprecated;
        uint256 versionIndex;
        address nftAddress;
        uint256 nftId;
        bytes32 contentHash;
    }


    /////////////////////
    // State Variables //
    /////////////////////
    Entry[] public entries;
    address public curator;
    address public pendingCurator;


    ////////////
    // Events //
    ////////////
    event EntryArchived(
        uint256 indexed entryIndex,
        string title,
        string source,
        string timestamp1,
        string timestamp2,
        string curatorNote,
        uint256 versionIndex,
        address nftAddress,
        uint256 nftId,
        bytes32 contentHash
    );

    event EntryDeprecated(
        uint256 indexed deprecatedIndex,
        uint256 indexed replacementIndex,
        string title,
        uint256 newVersionIndex
    );

    event CuratorTransferInitiated(
        address indexed currentCurator,
        address indexed pendingCurator
    );

    event CuratorTransferred(
        address indexed previousCurator,
        address indexed newCurator
    );

    event CuratorTransferCancelled(address indexed curator);


    ///////////////
    // Modifiers //
    ///////////////
    modifier onlyCurator() {
        if (msg.sender != curator) {
            revert Lit3Ledger__NotCurator();
        }
        _;
    }


    ///////////////
    // Functions //
    ///////////////
    constructor() {
        curator = msg.sender;
    }

    /**
     * @dev Archives a new entry to the Lit3 Ledger
     * @param _title Entry title
     * @param _source Source of the entry (location, transmission point, etc.)
     * @param _timestamp1 First timestamp (e.g., real-world reception)
     * @param _timestamp2 Second timestamp (e.g., source transmission time)
     * @param _curatorNote Observations or notes from the Curator
     * @param _nftAddress Address of associated NFT contract (0x0 if none)
     * @param _nftId Token ID of associated NFT (0 if none)
     * @param _contentHash SHA-256 hash of the canonical content (0x0 if not provided)
     */
    function archiveEntry(
        string memory _title,
        string memory _source,
        string memory _timestamp1,
        string memory _timestamp2,
        string memory _curatorNote,
        address _nftAddress,
        uint256 _nftId,
        bytes32 _contentHash
    ) public onlyCurator {
        entries.push(Entry(
            _title,
            _source,
            _timestamp1,
            _timestamp2,
            _curatorNote,
            false,              // deprecated
            1,                  // versionIndex starts at 1
            _nftAddress,
            _nftId,
            _contentHash
        ));

        emit EntryArchived(
            entries.length - 1,
            _title,
            _source,
            _timestamp1,
            _timestamp2,
            _curatorNote,
            1,
            _nftAddress,
            _nftId,
            _contentHash
        );
    }

    /**
     * @dev Archives an updated entry and deprecates the previous version
     * @param _title Entry title
     * @param _source Source of the entry
     * @param _timestamp1 First timestamp
     * @param _timestamp2 Second timestamp
     * @param _curatorNote Curator observations
     * @param _nftAddress Address of associated NFT contract (0x0 if none)
     * @param _nftId Token ID of associated NFT (0 if none)
     * @param _contentHash SHA-256 hash of canonical content (0x0 if not provided)
     * @param _deprecateIndex Index of the entry to deprecate and replace
     */
    function archiveUpdatedEntry(
        string memory _title,
        string memory _source,
        string memory _timestamp1,
        string memory _timestamp2,
        string memory _curatorNote,
        address _nftAddress,
        uint256 _nftId,
        bytes32 _contentHash,
        uint256 _deprecateIndex
    ) public onlyCurator {
        if (_deprecateIndex >= entries.length) {
            revert Lit3Ledger__EntryDoesNotExist();
        }

        if (entries[_deprecateIndex].deprecated) {
            revert Lit3Ledger__EntryAlreadyDeprecated();
        }

        // Read the old version index and increment it
        uint256 oldVersionIndex = entries[_deprecateIndex].versionIndex;
        uint256 newVersionIndex = oldVersionIndex + 1;

        // Deprecate the old entry
        entries[_deprecateIndex].deprecated = true;

        // Archive the new entry with incremented version
        entries.push(Entry(
            _title,
            _source,
            _timestamp1,
            _timestamp2,
            _curatorNote,
            false,              // new entry not deprecated
            newVersionIndex,    // incremented version
            _nftAddress,
            _nftId,
            _contentHash
        ));

        uint256 newIndex = entries.length - 1;

        emit EntryDeprecated(
            _deprecateIndex,
            newIndex,
            _title,
            newVersionIndex
        );

        emit EntryArchived(
            newIndex,
            _title,
            _source,
            _timestamp1,
            _timestamp2,
            _curatorNote,
            newVersionIndex,
            _nftAddress,
            _nftId,
            _contentHash
        );
    }


    /**
     * @dev Retrieves an entry by its index
     * @param index The index of the entry (0-based)
     */
    function getEntry(uint256 index) public view returns (Entry memory) {
        if (index >= entries.length) {
            revert Lit3Ledger__EntryDoesNotExist();
        }
        return entries[index];
    }

    /**
     * @dev Returns the total number of entries archived
     */
    function getTotalEntries() public view returns (uint256) {
        return entries.length;
    }

    /**
     * @dev Retrieves multiple entries at once (for pagination)
     * @param startIndex Starting index (0-based)
     * @param count Number of entries to retrieve
     */
    function getEntriesBatch(uint256 startIndex, uint256 count) 
        public 
        view 
        returns (Entry[] memory) 
    {
        if (startIndex >= entries.length) {
            revert Lit3Ledger__StartIndexOutOfBounds();
        }
        
        uint256 endIndex = startIndex + count;
        if (endIndex > entries.length) {
            endIndex = entries.length;
        }
        
        uint256 batchSize = endIndex - startIndex;
        Entry[] memory batch = new Entry[](batchSize);
        
        for (uint256 i = 0; i < batchSize; i++) {
            batch[i] = entries[startIndex + i];
        }
        
        return batch;
    }

    /**
     * @dev Gets the latest archived entries (most recent first)
     * @param count Number of latest entries to retrieve
     */
    function getLatestEntries(uint256 count) public view returns (Entry[] memory) {
        if (entries.length == 0) {
            return new Entry[](0);
        }
        
        uint256 actualCount = count > entries.length ? entries.length : count;
        Entry[] memory latestEntries = new Entry[](actualCount);
        
        for (uint256 i = 0; i < actualCount; i++) {
            latestEntries[i] = entries[entries.length - 1 - i];
        }
        
        return latestEntries;
    }

    /**
     * @dev Initiate curator role transfer to a new address
     * @param newCurator Address of the new curator
     */
    // Step 1: Current curator initiates the transfer
    function initiateCuratorTransfer(address newCurator) public onlyCurator {
        if (newCurator == address(0)) {
            revert Lit3Ledger__NotZeroAddress();
        }
        pendingCurator = newCurator;
        emit CuratorTransferInitiated(curator, newCurator);
    }

    // Step 2: New curator accepts the transfer
    function acceptCuratorTransfer() public {
        if (msg.sender != pendingCurator) {
            revert Lit3Ledger__NotPendingCurator();
        }
        address previousCurator = curator;
        curator = msg.sender;
        pendingCurator = address(0);
        emit CuratorTransferred(previousCurator, curator);
    }

    // Step 3 (if needed): Reset the pending curator address to 0
    function cancelCuratorTransfer() public onlyCurator {
        pendingCurator = address(0);
        emit CuratorTransferCancelled(curator);
    }
}