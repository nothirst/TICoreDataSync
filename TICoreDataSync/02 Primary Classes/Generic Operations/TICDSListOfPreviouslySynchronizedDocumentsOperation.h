//
//  TICDSListOfPreviouslySynchronizedDocumentsOperation.h
//  ShoppingListMac
//
//  Created by Tim Isted on 24/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICDSOperation.h"

/** The `TICDSListOfPreviouslySynchronizedDocumentsOperation` class describes a generic operation used by the `TICoreDataSync` framework to fetch a list of documents that have previously been synchronized for this application.
 
 The operation carries out the following tasks:
 
 1. Get a list of document identifiers for available documents.
 2. Fetch the `documentInfo` dictionary for each document.
 3. Get the most recent synchronization date for each successfully-fetched document dictionary (the most recently modified file in `RecentSyncs`).
 
 Operations are typically created automatically by the relevant sync manager.
 
 @warning You must use one of the subclasses of `TICDSListOfPreviouslySynchronizedDocumentsOperation`.
 */

@interface TICDSListOfPreviouslySynchronizedDocumentsOperation : TICDSOperation {
@private
    NSMutableArray *_availableDocuments;
    
    NSArray *_availableDocumentSyncIDs;
    
    NSUInteger _numberOfInfoDictionariesToFetch;
    NSUInteger _numberOfInfoDictionariesFetched;
    NSUInteger _numberOfInfoDictionariesThatFailedToFetch;
    
    NSUInteger _numberOfLastSynchronizationDatesToFetch;
    NSUInteger _numberOfLastSynchronizationDatesFetched;
    NSUInteger _numberOfLastSynchronizationDatesThatFailedToFetch;
}

/** @name Methods Overridden by Subclasses */

/** Build an array of `NSString` document identifiers for all available, previously-synchronized documents.
 
 Call `builtArrayOfDocumentIdentifiers:` when the array is built. */
- (void)buildArrayOfDocumentIdentifiers;

/** Fetch the `documentInfo` dictionary for the document with the specified ID.
 
 @param aSyncID The synchronization identifier for the document.
 
 Call `fetchedInfoDictionary:forDocumentWithSyncID:` for each document as it is fetched. */
- (void)fetchInfoDictionaryForDocumentWithSyncID:(NSString *)aSyncID;

/** Fetch the last synchronization date for a document with the given synchronization ID.
 
 @param aSyncID The synchronization identifier for the document.
 
 Call `fetchedLastSynchronizationDate:forDocumentWithSyncID:` when the date is fetched. */
- (void)fetchLastSynchronizationDateForDocumentWithSyncID:(NSString *)aSyncID;

/** @name Callbacks */

/** Pass back the assembled `NSArray` of `NSString` document identifiers.
 
 If an error occurred, call `setError:` first, then specify `nil` for `anArray`.
 
 @param anArray The array of identifiers. Pass `nil` if an error occurred. */
- (void)builtArrayOfDocumentIdentifiers:(NSArray *)anArray;

/** Pass back the `documentInfo` dictionary for a given document sync identifier.
 
 If an error occurred, call `setError:` first, then specify `nil` for `anInfoDictionary`.
 
 @param anInfoDictionary The `documentInfo` dictionary, or `nil` if an error occurred.
 @param aSyncID The unique synchronization identifier of the given document. */
- (void)fetchedInfoDictionary:(NSDictionary *)anInfoDictionary forDocumentWithSyncID:(NSString *)aSyncID;

/** Pass back the last synchronization date for a given document sync identifier.
 
 If an error occurred, call `setError:` first, then specify `nil` for `aDate`.
 
 @param aDate The last synchronization date, or `nil` if an error occurred.
 @param aSyncID The unique synchronization identifier of the given document. */
- (void)fetchedLastSynchronizationDate:(NSDate *)aDate forDocumentWithSyncID:(NSString *)aSyncID;

/** @name Properties */

/** An array of documents, built as information comes in. */
@property (strong) NSMutableArray *availableDocuments;

/** An array used internally by the operation to keep track of the available document sync identifiers. */
@property (nonatomic, strong) NSArray *availableDocumentSyncIDs;

/** @name Completion */

/** The total number of info dictionaries that need to be fetched. */
@property (nonatomic, assign) NSUInteger numberOfInfoDictionariesToFetch;

/** The number of info dictionaries that have already been fetched. */
@property (nonatomic, assign) NSUInteger numberOfInfoDictionariesFetched;

/** The number of info dictionaries that failed to fetch because of an error. */
@property (nonatomic, assign) NSUInteger numberOfInfoDictionariesThatFailedToFetch;

/** The total number of last synchronization dates that need to be fetched. */
@property (nonatomic, assign) NSUInteger numberOfLastSynchronizationDatesToFetch;

/** The number of last synchronization dates that have already been fetched. */
@property (nonatomic, assign) NSUInteger numberOfLastSynchronizationDatesFetched;

/** The number of last synchronization dates failed to fetch because of an error. */
@property (nonatomic, assign) NSUInteger numberOfLastSynchronizationDatesThatFailedToFetch;

@end
