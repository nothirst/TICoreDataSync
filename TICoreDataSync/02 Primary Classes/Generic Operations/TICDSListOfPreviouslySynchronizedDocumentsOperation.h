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
    NSUInteger _numberOfInfoDictionariesToFetch;
    NSUInteger _numberOfInfoDictionariesFetched;
    NSUInteger _numberOfInfoDictionariesThatFailedToFetch;
    
    TICDSOperationPhaseStatus _infoDictionariesStatus;
}

/** @name Methods Overridden by Subclasses */

/** Build an array of `NSString` document identifiers for all available, previously-synchronized documents.
 
 Call `builtArrayOfDocumentIdentifiers:` when the array is built.
 */
- (void)buildArrayOfDocumentIdentifiers;

/** @name Callbacks */

/** Pass back the assembled `NSArray` of `NSString` document identifiers.
 
 If an error occurred, call `setError:` and pass `nil`.
 
 @param anArray The array of identifiers. Pass `nil` if an error occurred. */
- (void)builtArrayOfDocumentIdentifiers:(NSArray *)anArray;

/** @name Properties */

/** An array of documents, built as information comes in. */
@property (retain) NSMutableArray *availableDocuments;

/** @name Completion */

/** Used to indicate that completion is currently in progress, and that no further checks should be made. */
@property (nonatomic, assign) BOOL completionInProgress;

/** The phase status regarding building the document sync IDs array. */
@property (nonatomic, assign) TICDSOperationPhaseStatus arrayOfDocumentIdentifiersStatus;

/** The phase status of the info dictionary requests. */
@property (nonatomic, assign) TICDSOperationPhaseStatus infoDictionariesStatus;

@end
