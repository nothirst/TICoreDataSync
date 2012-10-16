//
//  TICDSFileManagerBasedListOfPreviouslySynchronizedDocumentsOperation.h
//  ShoppingListMac
//
//  Created by Tim Isted on 24/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICDSListOfPreviouslySynchronizedDocumentsOperation.h"

/**
 `TICDSFileManagerBasedListOfPreviouslySynchronizedDocumentsOperation` is a "list of previously-synchronized documents" operation designed for use with a `TICDSFileManagerBasedApplicationSyncManager`.
 */
@interface TICDSFileManagerBasedListOfPreviouslySynchronizedDocumentsOperation : TICDSListOfPreviouslySynchronizedDocumentsOperation {
@private
    NSString *_documentsDirectoryPath;
}

/** @name Paths */

/** The path to the `Documents` directory. */
@property (copy) NSString *documentsDirectoryPath;

/** Returns the path to the `documentInfo.plist` file for a document with the specified identifier.
 
 @param anIdentifier The identifier of the document.
 
 @return A path to the specified document. */
- (NSString *)pathToDocumentInfoForDocumentWithIdentifier:(NSString *)anIdentifier;

/** Returns the path to the `RecentSyncs` directory for a document with the specified identifier.
 
 @param anIdentifier The identifier of the document.
 
 @return A path to the `RecentSyncs` directory. */
- (NSString *)pathToDocumentRecentSyncsDirectoryForIdentifier:(NSString *)anIdentifier;

@end
