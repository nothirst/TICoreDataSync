//
//  TICDSDocumentDeletionOperation.h
//  Notebook
//
//  Created by Tim Isted on 29/05/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICDSOperation.h"


@interface TICDSDocumentDeletionOperation : TICDSOperation {
@private
    NSString *_documentIdentifier;
    BOOL _documentWasFoundAndDeleted;
}

#pragma mark Overridden Methods
/** @name Overridden Methods */

/** Check whether the document directory with specified identifier exists.
  
 This method must call `discoveredStatusOfTemporaryWholeStoreDirectory:` to indicate the status. */
- (void)checkWhetherIdentifiedDocumentDirectoryExists:(NSString *)anIdentifier;

#pragma mark Callbacks
/** @name Callbacks */


- (void)discoveredStatusOfIdentifiedDocumentDirectory:(TICDSRemoteFileStructureExistsResponseType)status;

#pragma mark Properties
/** @name Properties */

/** The identifier of the document to delete. */
@property (retain) NSString *documentIdentifier;

/** Used to indicate (once the operation completes) whether the document was found and deleted successfully. */
@property (assign) BOOL documentWasFoundAndDeleted;

@end
