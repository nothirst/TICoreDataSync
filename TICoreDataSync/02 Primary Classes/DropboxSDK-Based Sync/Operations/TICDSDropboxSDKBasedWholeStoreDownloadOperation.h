//
//  TICDSDropboxSDKBasedWholeStoreDownloadOperation.h
//  iOSNotebook
//
//  Created by Tim Isted on 14/05/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICDSWholeStoreDownloadOperation.h"
#import "DropboxSDK.h"

@interface TICDSDropboxSDKBasedWholeStoreDownloadOperation : TICDSWholeStoreDownloadOperation <DBRestClientDelegate> {
@private
    DBSession *_dbSession;
    DBRestClient *_restClient;
    
    NSString *_thisDocumentWholeStoreDirectoryPath;
    
    NSUInteger _numberOfWholeStoresToCheck;
    NSMutableDictionary *_wholeStoreModifiedDates;
}

/** @name Properties */

/** The DropboxSDK `DBSession` for use by this operation's `DBRestClient`. */
@property (retain) DBSession *dbSession;

/** The DropboxSDK `DBRestClient` for use by this operation for methods relating to the global application directory. */
@property (nonatomic, retain) DBRestClient *restClient;

/** A mutable dictionary to hold the last modified dates of each client identifier's whole store. */
@property (nonatomic, retain) NSMutableDictionary *wholeStoreModifiedDates;

/** @name Paths */

/** The path to a given client's `WholeStore.ticdsync` file within this document's `WholeStore` directory.
 
 @param anIdentifier The unique sync identifier of the document. */
- (NSString *)pathToWholeStoreFileForClientWithIdentifier:(NSString *)anIdentifier;

/** The path to a given client's `AppliedSyncChanges.ticdsync` file within this document's `WholeStore` directory.
 
 @param anIdentifier The unique sync identifier of the document. */
- (NSString *)pathToAppliedSyncChangesFileForClientWithIdentifier:(NSString *)anIdentifier;

/** The path to this document's `WholeStore` directory. */
@property (retain) NSString *thisDocumentWholeStoreDirectoryPath;

@end
