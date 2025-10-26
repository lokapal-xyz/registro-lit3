// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Test } from "forge-std/Test.sol";
import { Lit3Ledger } from "../src/Lit3Ledger.sol";

contract Lit3LedgerTest is Test {
    Lit3Ledger public lit3Ledger;
    address public curator;
    address public unauthorized;

    // Test entry data
    string constant TEST_TITLE = "Chapter One";
    string constant TEST_SOURCE = "Archive Node";
    string constant TEST_TIMESTAMP1 = "2025-10-11 14:30:00 UTC";
    string constant TEST_TIMESTAMP2 = "Lanka Transmission Time";
    string constant TEST_CURATOR_NOTE = "Initial entry of the narrative";
    bytes32 constant TEST_CONTENT_HASH = 0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef;
    string constant TEST_PERMAWEB_LINK = "ipfs://QmTest123456789";
    string constant TEST_LICENSE = "CC BY-SA 4.0";
    address constant TEST_NFT_ADDRESS = 0x0000000000000000000000000000000000000000;
    uint256 constant TEST_NFT_ID = 0;

    function setUp() public {
        curator = makeAddr("curator");
        unauthorized = makeAddr("unauthorized");
        
        vm.prank(curator);
        lit3Ledger = new Lit3Ledger();
    }

    /*//////////////////////////////////////////////////////////////
                            DEPLOYMENT TESTS
    //////////////////////////////////////////////////////////////*/

    function test_InitialState() public view {
        assertEq(lit3Ledger.curator(), curator);
        assertEq(lit3Ledger.pendingCurator(), address(0));
        assertEq(lit3Ledger.getTotalEntries(), 0);
    }

    /*//////////////////////////////////////////////////////////////
                          ENTRY ARCHIVING TESTS
    //////////////////////////////////////////////////////////////*/

    function test_ArchiveEntry_Success() public {
        vm.prank(curator);
        lit3Ledger.archiveEntry(
            TEST_TITLE,
            TEST_SOURCE,
            TEST_TIMESTAMP1,
            TEST_TIMESTAMP2,
            TEST_CURATOR_NOTE,
            TEST_NFT_ADDRESS,
            TEST_NFT_ID,
            TEST_CONTENT_HASH,
            TEST_PERMAWEB_LINK,
            TEST_LICENSE
        );

        assertEq(lit3Ledger.getTotalEntries(), 1);
        
        Lit3Ledger.Entry memory entry = lit3Ledger.getEntry(0);
        assertEq(entry.title, TEST_TITLE);
        assertEq(entry.source, TEST_SOURCE);
        assertEq(entry.timestamp1, TEST_TIMESTAMP1);
        assertEq(entry.timestamp2, TEST_TIMESTAMP2);
        assertEq(entry.curatorNote, TEST_CURATOR_NOTE);
        assertEq(entry.versionIndex, 1);
        assertEq(entry.deprecated, false);
        assertEq(entry.nftAddress, TEST_NFT_ADDRESS);
        assertEq(entry.nftId, TEST_NFT_ID);
        assertEq(entry.contentHash, TEST_CONTENT_HASH);
        assertEq(entry.permawebLink, TEST_PERMAWEB_LINK);
        assertEq(entry.license, TEST_LICENSE);
    }

    function test_ArchiveEntry_RevertWhen_NotCurator() public {
        vm.prank(unauthorized);
        vm.expectRevert(Lit3Ledger.Lit3Ledger__NotCurator.selector);
        
        lit3Ledger.archiveEntry(
            TEST_TITLE,
            TEST_SOURCE,
            TEST_TIMESTAMP1,
            TEST_TIMESTAMP2,
            TEST_CURATOR_NOTE,
            TEST_NFT_ADDRESS,
            TEST_NFT_ID,
            TEST_CONTENT_HASH,
            TEST_PERMAWEB_LINK,
            TEST_LICENSE
        );
    }

    function test_ArchiveEntry_EmitsEvent() public {
        vm.prank(curator);
        
        vm.expectEmit(true, false, false, true);
        emit Lit3Ledger.EntryArchived(
            0,
            TEST_TITLE,
            TEST_SOURCE,
            TEST_TIMESTAMP1,
            TEST_TIMESTAMP2,
            TEST_CURATOR_NOTE,
            1,
            TEST_NFT_ADDRESS,
            TEST_NFT_ID,
            TEST_CONTENT_HASH,
            TEST_PERMAWEB_LINK,
            TEST_LICENSE
        );
        
        lit3Ledger.archiveEntry(
            TEST_TITLE,
            TEST_SOURCE,
            TEST_TIMESTAMP1,
            TEST_TIMESTAMP2,
            TEST_CURATOR_NOTE,
            TEST_NFT_ADDRESS,
            TEST_NFT_ID,
            TEST_CONTENT_HASH,
            TEST_PERMAWEB_LINK,
            TEST_LICENSE
        );
    }

    /*//////////////////////////////////////////////////////////////
                     ARCHIVE UPDATED ENTRY TESTS
    //////////////////////////////////////////////////////////////*/

    function test_ArchiveUpdatedEntry_Success() public {
        // Archive initial entry
        vm.prank(curator);
        lit3Ledger.archiveEntry(
            TEST_TITLE,
            TEST_SOURCE,
            TEST_TIMESTAMP1,
            TEST_TIMESTAMP2,
            TEST_CURATOR_NOTE,
            TEST_NFT_ADDRESS,
            TEST_NFT_ID,
            TEST_CONTENT_HASH,
            TEST_PERMAWEB_LINK,
            TEST_LICENSE
        );

        // Archive updated entry
        string memory updatedNote = "Corrected entry with additional context";
        bytes32 updatedHash = 0xabcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890;
        string memory updatedLink = "ipfs://QmUpdated987654321";
        string memory updatedLicense = "CC BY-NC-SA 4.0";

        vm.prank(curator);
        lit3Ledger.archiveUpdatedEntry(
            TEST_TITLE,
            TEST_SOURCE,
            TEST_TIMESTAMP1,
            TEST_TIMESTAMP2,
            updatedNote,
            TEST_NFT_ADDRESS,
            TEST_NFT_ID,
            updatedHash,
            updatedLink,
            updatedLicense,
            0 // deprecateIndex
        );

        // Check total entries (should be 2 now)
        assertEq(lit3Ledger.getTotalEntries(), 2);

        // Check old entry is deprecated
        Lit3Ledger.Entry memory oldEntry = lit3Ledger.getEntry(0);
        assertEq(oldEntry.deprecated, true);
        assertEq(oldEntry.versionIndex, 1);

        // Check new entry has incremented version
        Lit3Ledger.Entry memory newEntry = lit3Ledger.getEntry(1);
        assertEq(newEntry.deprecated, false);
        assertEq(newEntry.versionIndex, 2);
        assertEq(newEntry.curatorNote, updatedNote);
        assertEq(newEntry.contentHash, updatedHash);
        assertEq(newEntry.permawebLink, updatedLink);
        assertEq(newEntry.license, updatedLicense);
    }

    function test_ArchiveUpdatedEntry_RevertWhen_InvalidIndex() public {
        vm.prank(curator);
        vm.expectRevert(Lit3Ledger.Lit3Ledger__EntryDoesNotExist.selector);
        
        lit3Ledger.archiveUpdatedEntry(
            TEST_TITLE,
            TEST_SOURCE,
            TEST_TIMESTAMP1,
            TEST_TIMESTAMP2,
            TEST_CURATOR_NOTE,
            TEST_NFT_ADDRESS,
            TEST_NFT_ID,
            TEST_CONTENT_HASH,
            TEST_PERMAWEB_LINK,
            TEST_LICENSE,
            999
        );
    }

    function test_ArchiveUpdatedEntry_RevertWhen_AlreadyDeprecated() public {
        // Archive two entries
        vm.startPrank(curator);
        lit3Ledger.archiveEntry(
            "Entry 1",
            TEST_SOURCE,
            TEST_TIMESTAMP1,
            TEST_TIMESTAMP2,
            "Note 1",
            TEST_NFT_ADDRESS,
            TEST_NFT_ID,
            TEST_CONTENT_HASH,
            TEST_PERMAWEB_LINK,
            TEST_LICENSE
        );
        
        lit3Ledger.archiveEntry(
            "Entry 2",
            TEST_SOURCE,
            TEST_TIMESTAMP1,
            TEST_TIMESTAMP2,
            "Note 2",
            TEST_NFT_ADDRESS,
            TEST_NFT_ID,
            TEST_CONTENT_HASH,
            TEST_PERMAWEB_LINK,
            TEST_LICENSE
        );

        // Deprecate entry 0
        lit3Ledger.archiveUpdatedEntry(
            "Entry 1 Updated",
            TEST_SOURCE,
            TEST_TIMESTAMP1,
            TEST_TIMESTAMP2,
            "Updated note 1",
            TEST_NFT_ADDRESS,
            TEST_NFT_ID,
            TEST_CONTENT_HASH,
            TEST_PERMAWEB_LINK,
            TEST_LICENSE,
            0
        );

        // Try to deprecate entry 0 again (should fail)
        vm.expectRevert(Lit3Ledger.Lit3Ledger__EntryAlreadyDeprecated.selector);
        lit3Ledger.archiveUpdatedEntry(
            "Entry 1 Updated Again",
            TEST_SOURCE,
            TEST_TIMESTAMP1,
            TEST_TIMESTAMP2,
            "Another update",
            TEST_NFT_ADDRESS,
            TEST_NFT_ID,
            TEST_CONTENT_HASH,
            TEST_PERMAWEB_LINK,
            TEST_LICENSE,
            0
        );
        vm.stopPrank();
    }

    function test_ArchiveUpdatedEntry_EmitsDeprecatedEvent() public {
        vm.prank(curator);
        lit3Ledger.archiveEntry(
            TEST_TITLE,
            TEST_SOURCE,
            TEST_TIMESTAMP1,
            TEST_TIMESTAMP2,
            TEST_CURATOR_NOTE,
            TEST_NFT_ADDRESS,
            TEST_NFT_ID,
            TEST_CONTENT_HASH,
            TEST_PERMAWEB_LINK,
            TEST_LICENSE
        );

        vm.prank(curator);
        vm.expectEmit(true, true, false, true);
        emit Lit3Ledger.EntryDeprecated(0, 1, TEST_TITLE, 2);
        
        lit3Ledger.archiveUpdatedEntry(
            TEST_TITLE,
            TEST_SOURCE,
            TEST_TIMESTAMP1,
            TEST_TIMESTAMP2,
            "Updated note",
            TEST_NFT_ADDRESS,
            TEST_NFT_ID,
            TEST_CONTENT_HASH,
            TEST_PERMAWEB_LINK,
            TEST_LICENSE,
            0
        );
    }

    /*//////////////////////////////////////////////////////////////
                            RETRIEVAL TESTS
    //////////////////////////////////////////////////////////////*/

    function test_GetEntry_RevertWhen_InvalidIndex() public {
        vm.expectRevert(Lit3Ledger.Lit3Ledger__EntryDoesNotExist.selector);
        lit3Ledger.getEntry(0);
    }

    function test_GetEntriesBatch_Success() public {
        _archiveTestEntries(3);

        Lit3Ledger.Entry[] memory batch = lit3Ledger.getEntriesBatch(0, 2);
        assertEq(batch.length, 2);
        assertEq(batch[0].title, "Entry 0");
        assertEq(batch[1].title, "Entry 1");
    }

    function test_GetEntriesBatch_RevertWhen_StartIndexOutOfBounds() public {
        vm.expectRevert(Lit3Ledger.Lit3Ledger__StartIndexOutOfBounds.selector);
        lit3Ledger.getEntriesBatch(0, 1);
    }

    function test_GetLatestEntries() public {
        _archiveTestEntries(5);

        Lit3Ledger.Entry[] memory latest = lit3Ledger.getLatestEntries(3);
        assertEq(latest.length, 3);
        // Should return most recent first
        assertEq(latest[0].title, "Entry 4");
        assertEq(latest[1].title, "Entry 3");
        assertEq(latest[2].title, "Entry 2");
    }

    function test_GetLatestEntries_EmptyLedger() public view {
        Lit3Ledger.Entry[] memory latest = lit3Ledger.getLatestEntries(5);
        assertEq(latest.length, 0);
    }

    /*//////////////////////////////////////////////////////////////
                    CURATOR TRANSFER TESTS (TWO-STEP)
    //////////////////////////////////////////////////////////////*/

    function test_InitiateCuratorTransfer_Success() public {
        address newCurator = makeAddr("newCurator");
        
        vm.prank(curator);
        vm.expectEmit(true, true, false, false);
        emit Lit3Ledger.CuratorTransferInitiated(curator, newCurator);
        
        lit3Ledger.initiateCuratorTransfer(newCurator);
        
        assertEq(lit3Ledger.pendingCurator(), newCurator);
        assertEq(lit3Ledger.curator(), curator); // Curator hasn't changed yet
    }

    function test_InitiateCuratorTransfer_RevertWhen_ZeroAddress() public {
        vm.prank(curator);
        vm.expectRevert(Lit3Ledger.Lit3Ledger__NotZeroAddress.selector);
        
        lit3Ledger.initiateCuratorTransfer(address(0));
    }

    function test_InitiateCuratorTransfer_RevertWhen_NotCurator() public {
        vm.prank(unauthorized);
        vm.expectRevert(Lit3Ledger.Lit3Ledger__NotCurator.selector);
        
        lit3Ledger.initiateCuratorTransfer(unauthorized);
    }

    function test_AcceptCuratorTransfer_Success() public {
        address newCurator = makeAddr("newCurator");
        
        // Step 1: Initiate transfer
        vm.prank(curator);
        lit3Ledger.initiateCuratorTransfer(newCurator);
        
        // Step 2: New curator accepts
        vm.prank(newCurator);
        vm.expectEmit(true, true, false, false);
        emit Lit3Ledger.CuratorTransferred(curator, newCurator);
        
        lit3Ledger.acceptCuratorTransfer();
        
        assertEq(lit3Ledger.curator(), newCurator);
        assertEq(lit3Ledger.pendingCurator(), address(0)); // Pending cleared
    }

    function test_AcceptCuratorTransfer_RevertWhen_NotPendingCurator() public {
        address newCurator = makeAddr("newCurator");
        
        vm.prank(curator);
        lit3Ledger.initiateCuratorTransfer(newCurator);
        
        // Try to accept from wrong address
        vm.prank(unauthorized);
        vm.expectRevert(Lit3Ledger.Lit3Ledger__NotPendingCurator.selector);
        
        lit3Ledger.acceptCuratorTransfer();
    }

    function test_CancelCuratorTransfer_Success() public {
        address newCurator = makeAddr("newCurator");
        
        // Step 1: Initiate transfer
        vm.prank(curator);
        lit3Ledger.initiateCuratorTransfer(newCurator);
        
        assertEq(lit3Ledger.pendingCurator(), newCurator);
        
        // Step 2: Current curator cancels
        vm.prank(curator);
        vm.expectEmit(true, false, false, false);
        emit Lit3Ledger.CuratorTransferCancelled(curator);
        
        lit3Ledger.cancelCuratorTransfer();
        
        assertEq(lit3Ledger.pendingCurator(), address(0));
        assertEq(lit3Ledger.curator(), curator); // Unchanged
    }

    function test_CancelCuratorTransfer_RevertWhen_NotCurator() public {
        address newCurator = makeAddr("newCurator");
        
        vm.prank(curator);
        lit3Ledger.initiateCuratorTransfer(newCurator);
        
        // Try to cancel from unauthorized address
        vm.prank(unauthorized);
        vm.expectRevert(Lit3Ledger.Lit3Ledger__NotCurator.selector);
        
        lit3Ledger.cancelCuratorTransfer();
    }

    function test_TwoStepTransferFlow() public {
        address newCurator = makeAddr("newCurator");
        
        // Step 1: Current curator initiates
        vm.prank(curator);
        lit3Ledger.initiateCuratorTransfer(newCurator);
        assertEq(lit3Ledger.pendingCurator(), newCurator);
        
        // Step 2: New curator accepts
        vm.prank(newCurator);
        lit3Ledger.acceptCuratorTransfer();
        assertEq(lit3Ledger.curator(), newCurator);
        assertEq(lit3Ledger.pendingCurator(), address(0));
        
        // Step 3: Verify only new curator can now archive entries
        vm.prank(newCurator);
        lit3Ledger.archiveEntry(
            "New Entry",
            TEST_SOURCE,
            TEST_TIMESTAMP1,
            TEST_TIMESTAMP2,
            "Archived by new curator",
            TEST_NFT_ADDRESS,
            TEST_NFT_ID,
            TEST_CONTENT_HASH,
            TEST_PERMAWEB_LINK,
            TEST_LICENSE
        );
        
        assertEq(lit3Ledger.getTotalEntries(), 1);
        
        // Step 4: Verify old curator can no longer archive
        vm.prank(curator);
        vm.expectRevert(Lit3Ledger.Lit3Ledger__NotCurator.selector);
        lit3Ledger.archiveEntry(
            "Unauthorized Entry",
            TEST_SOURCE,
            TEST_TIMESTAMP1,
            TEST_TIMESTAMP2,
            "Should fail",
            TEST_NFT_ADDRESS,
            TEST_NFT_ID,
            TEST_CONTENT_HASH,
            TEST_PERMAWEB_LINK,
            TEST_LICENSE
        );
    }

    /*//////////////////////////////////////////////////////////////
                         VERSIONING TESTS
    //////////////////////////////////////////////////////////////*/

    function test_VersioningChain() public {
        vm.startPrank(curator);
        
        // Archive v1
        lit3Ledger.archiveEntry(
            "Chapter",
            TEST_SOURCE,
            TEST_TIMESTAMP1,
            TEST_TIMESTAMP2,
            "Version 1",
            TEST_NFT_ADDRESS,
            TEST_NFT_ID,
            TEST_CONTENT_HASH,
            TEST_PERMAWEB_LINK,
            TEST_LICENSE
        );
        
        // Archive v2 (deprecate v1)
        lit3Ledger.archiveUpdatedEntry(
            "Chapter",
            TEST_SOURCE,
            TEST_TIMESTAMP1,
            TEST_TIMESTAMP2,
            "Version 2",
            TEST_NFT_ADDRESS,
            TEST_NFT_ID,
            TEST_CONTENT_HASH,
            TEST_PERMAWEB_LINK,
            TEST_LICENSE,
            0
        );
        
        // Archive v3 (deprecate v2)
        lit3Ledger.archiveUpdatedEntry(
            "Chapter",
            TEST_SOURCE,
            TEST_TIMESTAMP1,
            TEST_TIMESTAMP2,
            "Version 3",
            TEST_NFT_ADDRESS,
            TEST_NFT_ID,
            TEST_CONTENT_HASH,
            TEST_PERMAWEB_LINK,
            TEST_LICENSE,
            1
        );
        
        vm.stopPrank();

        // Verify version chain
        Lit3Ledger.Entry memory v1 = lit3Ledger.getEntry(0);
        assertEq(v1.versionIndex, 1);
        assertEq(v1.deprecated, true);

        Lit3Ledger.Entry memory v2 = lit3Ledger.getEntry(1);
        assertEq(v2.versionIndex, 2);
        assertEq(v2.deprecated, true);

        Lit3Ledger.Entry memory v3 = lit3Ledger.getEntry(2);
        assertEq(v3.versionIndex, 3);
        assertEq(v3.deprecated, false);
    }

    /*//////////////////////////////////////////////////////////////
                              FUZZ TESTS
    //////////////////////////////////////////////////////////////*/

    function testFuzz_ArchiveEntry(
        string memory _title,
        string memory _source,
        string memory _timestamp1,
        string memory _timestamp2,
        string memory _curatorNote
    ) public {
        vm.assume(bytes(_title).length > 0);
        vm.assume(bytes(_source).length > 0);
        vm.assume(bytes(_timestamp2).length > 0);
        vm.assume(bytes(_curatorNote).length > 0);

        vm.prank(curator);
        lit3Ledger.archiveEntry(
            _title,
            _source,
            _timestamp1,
            _timestamp2,
            _curatorNote,
            TEST_NFT_ADDRESS,
            TEST_NFT_ID,
            TEST_CONTENT_HASH,
            TEST_PERMAWEB_LINK,
            TEST_LICENSE
        );

        assertEq(lit3Ledger.getTotalEntries(), 1);
        Lit3Ledger.Entry memory entry = lit3Ledger.getEntry(0);
        assertEq(entry.title, _title);
        assertEq(entry.source, _source);
        assertEq(entry.timestamp1, _timestamp1);
        assertEq(entry.timestamp2, _timestamp2);
        assertEq(entry.curatorNote, _curatorNote);
        assertEq(entry.versionIndex, 1);
        assertEq(entry.deprecated, false);
    }

    /*//////////////////////////////////////////////////////////////
                              HELPERS
    //////////////////////////////////////////////////////////////*/

    function _archiveTestEntries(uint256 count) internal {
        vm.startPrank(curator);
        for (uint256 i = 0; i < count; i++) {
            lit3Ledger.archiveEntry(
                string(abi.encodePacked("Entry ", vm.toString(i))),
                "Test Source",
                string(abi.encodePacked("Timestamp1 ", vm.toString(i))),
                string(abi.encodePacked("Timestamp2 ", vm.toString(i))),
                "Test curator note",
                TEST_NFT_ADDRESS,
                TEST_NFT_ID,
                TEST_CONTENT_HASH,
                TEST_PERMAWEB_LINK,
                TEST_LICENSE
            );
        }
        vm.stopPrank();
    }
}