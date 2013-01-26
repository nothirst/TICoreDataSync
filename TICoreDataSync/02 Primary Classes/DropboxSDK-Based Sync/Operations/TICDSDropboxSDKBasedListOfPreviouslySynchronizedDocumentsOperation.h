//
//  TICDSDropboxSDKBasedListOfPreviouslySynchronizedDocumentsOperation.h
//  iOSNotebook
//
//  Created by Tim Isted on 15/05/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//


#import "TICDSListOfPreviouslySynchronizedDocumentsOperation.h"

#if TARGET_OS_IPHONE
#import <DropboxSDK/DropboxSDK.h>
#else
#import <DropboxSDK/DropboxOSX.h>
#endif

/**
 `TICDSDropboxSDKBasedListOfPreviouslySynchronizedDocumentsOperation` is a "List of Previously Synchronized Documents" operation designed for use with a `TICDSDropboxSDKBasedDocumentSyncManager`.
 */

@interface TICDSDropboxSDKBasedListOfPreviouslySynchronizedDocumentsOperation : TICDSListOfPreviouslySynchronizedDocumentsOperation <DBRestClientDelegate> {
@private
    DBRestClient *_restClient;
    
    NSString *_documentsDirectoryPath;
}

/** @name Properties */

/** The DropboxSDK `DBRestClient` for use by this operation. */
@property (nonatomic, readonly) DBRestClient *restClient;

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

