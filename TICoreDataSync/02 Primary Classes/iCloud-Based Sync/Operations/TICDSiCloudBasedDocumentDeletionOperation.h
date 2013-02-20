//
//  TICDSiCloudBasedDocumentDeletionOperation.h
//  Notebook
//
//  Created by Tim Isted on 29/05/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICDSDocumentDeletionOperation.h"

/**
 `TICDSiCloudBasedDocumentDeletionOperation` is a document deletion operation designed for use with a `TICDSiCloudBasedApplicationSyncManager`.
 */

@interface TICDSiCloudBasedDocumentDeletionOperation : TICDSDocumentDeletionOperation {
@private
    NSString *_documentDirectoryPath;
    NSString *_documentInfoPlistFilePath;
    NSString *_deletedDocumentsDirectoryIdentifierPlistFilePath;
}

/** @name Paths */

/** The path to this document's directory. */
@property (retain) NSString *documentDirectoryPath;

/** The path to this document's `documentInfo.plist` file. */
@property (retain) NSString *documentInfoPlistFilePath;

/** The path to the `identifier.plist` file for this document inside the application's `DeletedDocuments` directory. */
@property (retain) NSString *deletedDocumentsDirectoryIdentifierPlistFilePath;

@end
