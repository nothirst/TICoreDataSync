//
//  TICDSDropboxSDKBasedWholeStoreDownloadOperation.h
//  iOSNotebook
//
//  Created by Tim Isted on 14/05/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//


#import "TICDSWholeStoreDownloadOperation.h"

#if TARGET_OS_IPHONE
#import <DropboxSDK/DropboxSDK.h>
#else
#import <DropboxSDK/DropboxOSX.h>
#endif

/**
 `TICDSDropboxSDKBasedWholeStoreDownloadOperation` is a "whole store download" operation designed for use with a `TICDSDropboxSDKBasedDocumentSyncManager`.
 */

@interface TICDSDropboxSDKBasedWholeStoreDownloadOperation : TICDSWholeStoreDownloadOperation <DBRestClientDelegate> {
@private
    DBRestClient *_restClient;
    
    NSString *_thisDocumentDirectoryPath;
    NSString *_thisDocumentWholeStoreDirectoryPath;
    
    NSUInteger _numberOfWholeStoresToCheck;
    NSMutableDictionary *_wholeStoreModifiedDates;
}

/** @name Properties */

/** The DropboxSDK `DBRestClient` for use by this operation. */
@property (nonatomic, readonly) DBRestClient *restClient;

/** @name Paths */

/** The path to a given client's `WholeStore.ticdsync` file within this document's `WholeStore` directory.
 
 @param anIdentifier The unique sync identifier of the document. */
- (NSString *)pathToWholeStoreFileForClientWithIdentifier:(NSString *)anIdentifier;

/** The path to a given client's `AppliedSyncChanges.ticdsync` file within this document's `WholeStore` directory.
 
 @param anIdentifier The unique sync identifier of the document. */
- (NSString *)pathToAppliedSyncChangesFileForClientWithIdentifier:(NSString *)anIdentifier;

/** The path to this document's directory. */
@property (copy) NSString *thisDocumentDirectoryPath;

/** The path to this document's `WholeStore` directory. */
@property (copy) NSString *thisDocumentWholeStoreDirectoryPath;

@end

