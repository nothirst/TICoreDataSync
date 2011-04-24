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
 3. Get the most recent synchronization date for each document (the most recently modified file in `RecentSyncs`).
 
 Operations are typically created automatically by the relevant sync manager.
 
 @warning You must use one of the subclasses of `TICDSListOfPreviouslySynchronizedDocumentsOperation`.
 */

@interface TICDSListOfPreviouslySynchronizedDocumentsOperation : TICDSOperation {
@private
    NSMutableArray *_availableDocuments;
    
    BOOL _completionInProgress;
    TICDSOperationPhaseStatus _arrayOfDocumentIdentifiersStatus;
    
    TICDSOperationPhaseStatus _infoDictionariesStatus;
    NSUInteger _numberOfInfoDictionariesToFetch;
    NSUInteger _numberOfInfoDictionariesFetched;
    NSUInteger _numberOfInfoDictionariesThatFailedToFetch;
}

/** @name Methods Overridden by Subclasses */

/** Build an array of `NSString` document identifiers for all available, previously-synchronized documents.
 
 Call `builtArrayOfDocumentIdentifiers:` when the array is built. */
- (void)buildArrayOfDocumentIdentifiers;

/** Fetch the `documentInfo` dictionaries for each of the documents with the specified IDs.
 
 @param syncIDs The array of document identifier `NSString`s.
 
 Call `fetchedInfoDictionary:forDocumentWithSyncID:` for each document as it is fetched. */
- (void)fetchInfoDictionariesForDocumentsWithSyncIDs:(NSArray *)syncIDs;

/** @name Callbacks */

/** Pass back the assembled `NSArray` of `NSString` document identifiers.
 
 If an error occurred, call `setError:` and pass `nil`.
 
 @param anArray The array of identifiers. Pass `nil` if an error occurred. */
- (void)builtArrayOfDocumentIdentifiers:(NSArray *)anArray;

/** Pass back the `documentInfo` dictionary for a given document sync identifier.
 
 If an error occurred, call `setError:` and pass `nil` for `anInfoDictionary`.
 
 @param anInfoDictionary The `documentInfo` dictionary, or `nil` if an error occurred.
 @param aSyncID The unique synchronization identifier of the given document. */
- (void)fetchedInfoDictionary:(NSDictionary *)anInfoDictionary forDocumentWithSyncID:(NSString *)aSyncID;

/** @name Properties */

/** An array of documents, built as information comes in. */
@property (retain) NSMutableArray *availableDocuments;

/** @name Completion */

/** Used to indicate that completion is currently in progress, and that no further checks should be made. */
@property (nonatomic, assign) BOOL completionInProgress;

/** The phase status regarding building the document sync IDs array. */
@property (nonatomic, assign) TICDSOperationPhaseStatus arrayOfDocumentIdentifiersStatus;

/** The total number of info dictionaries that need to be fetched. */
@property (nonatomic, assign) NSUInteger numberOfInfoDictionariesToFetch;

/** The number of info dictionaries that have already been fetched. */
@property (nonatomic, assign) NSUInteger numberOfInfoDictionariesFetched;

/** The number of info dictionaries that failed to fetch because of an error. */
@property (nonatomic, assign) NSUInteger numberOfInfoDictionariesThatFailedToFetch;

/** The phase status of the info dictionary requests. */
@property (nonatomic, assign) TICDSOperationPhaseStatus infoDictionariesStatus;

@end
