import { BigInt } from "@graphprotocol/graph-ts"
import {
  EntryArchived as EntryArchivedEvent,
  EntryDeprecated as EntryDeprecatedEvent,
  CuratorTransferred as CuratorTransferredEvent
} from "../generated/Lit3Ledger/Lit3Ledger"
import { 
  Entry, 
  EntryUpdate,
  CuratorTransfer, 
  Ledger 
} from "../generated/schema"

export function handleEntryArchived(event: EntryArchivedEvent): void {
  // Create unique ID using transaction hash and log index
  let entry = new Entry(
    event.transaction.hash.toHexString() + "-" + event.logIndex.toString()
  )
  
  // Map event parameters to entity fields
  entry.entryIndex = event.params.entryIndex
  entry.title = event.params.title
  entry.source = event.params.source
  entry.timestamp1 = event.params.timestamp1
  entry.timestamp2 = event.params.timestamp2
  entry.curatorNote = event.params.curatorNote
  entry.versionIndex = event.params.versionIndex
  entry.nftAddress = event.params.nftAddress
  entry.nftId = event.params.nftId
  entry.contentHash = event.params.contentHash
  entry.deprecated = false
  
  // Add blockchain metadata
  entry.blockNumber = event.block.number
  entry.blockTimestamp = event.block.timestamp
  entry.transactionHash = event.transaction.hash
  
  // Save the entry entity
  entry.save()
  
  // Update or create global ledger statistics
  let ledger = Ledger.load("1")
  if (ledger == null) {
    ledger = new Ledger("1")
    ledger.totalEntries = BigInt.fromI32(0)
    ledger.currentCurator = event.transaction.from
  }
  
  // Increment total entries counter
  ledger.totalEntries = ledger.totalEntries.plus(BigInt.fromI32(1))
  ledger.lastUpdated = event.block.timestamp
  ledger.save()
}

export function handleEntryDeprecated(event: EntryDeprecatedEvent): void {
  // Update the deprecated entry
  let deprecatedEntry = Entry.load(
    event.transaction.hash.toHexString() + "-" + event.logIndex.toString()
  )
  
  if (deprecatedEntry != null) {
    deprecatedEntry.deprecated = true
    deprecatedEntry.save()
  }
  
  // Create record of the deprecation/replacement
  let update = new EntryUpdate(
    event.transaction.hash.toHexString() + "-" + event.logIndex.toString()
  )
  
  update.deprecatedIndex = event.params.deprecatedIndex
  update.replacementIndex = event.params.replacementIndex
  update.title = event.params.title
  update.newVersionIndex = event.params.newVersionIndex
  update.blockNumber = event.block.number
  update.blockTimestamp = event.block.timestamp
  update.transactionHash = event.transaction.hash
  
  update.save()
}

export function handleCuratorTransferred(event: CuratorTransferredEvent): void {
  // Create unique ID for the transfer event
  let transfer = new CuratorTransfer(
    event.transaction.hash.toHexString() + "-" + event.logIndex.toString()
  )
  
  // Map event parameters
  transfer.previousCurator = event.params.previousCurator
  transfer.newCurator = event.params.newCurator
  transfer.blockNumber = event.block.number
  transfer.blockTimestamp = event.block.timestamp
  transfer.transactionHash = event.transaction.hash
  
  // Save the transfer record
  transfer.save()
  
  // Update global ledger with new curator
  let ledger = Ledger.load("1")
  if (ledger != null) {
    ledger.currentCurator = event.params.newCurator
    ledger.lastUpdated = event.block.timestamp
    ledger.save()
  }
}