//
//  TICDSFileManagerBasedListOfDocumentRegisteredClientsOperation.h
//  Notebook
//
//  Created by Tim Isted on 23/05/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICDSListOfDocumentRegisteredClientsOperation.h"

/**
 `TICDSFileManagerBasedListOfDocumentRegisteredClientsOperation` is a "list of clients registered to a document" operation designed for use with a `TICDSFileManagerBasedDocumentSyncManager`.
 */
@interface TICDSFileManagerBasedListOfDocumentRegisteredClientsOperation : TICDSListOfDocumentRegisteredClientsOperation {
@private
    NSString *_thisDocumentSyncChangesDirectoryPath;
    NSString *_clientDevicesDirectoryPath;
    NSString *_thisDocumentRecentSyncsDirectoryPath;
    NSString *_thisDocumentWholeStoreDirectoryPath;
}


/** @name Paths */

/** The path to this document's `SyncChanges` directory. */
@property (copy) NSString *thisDocumentSyncChangesDirectoryPath;

/** The path to the `ClientDevices` directory. */
@property (copy) NSString *clientDevicesDirectoryPath;

/** The path to this document's `RecentSyncs` directory. */
@property (copy) NSString *thisDocumentRecentSyncsDirectoryPath;

/** The path to this document's `WholeStore` directory. */
@property (copy) NSString *thisDocumentWholeStoreDirectoryPath;

/** Return the path to the `deviceInfo.plist` file for a specified client, inside the `ClientDevices` directory.
 
 @param anIdentifier The identifier of the client.
 
 @return The path to the `deviceInfo.plist` file. */
- (NSString *)pathToDeviceInfoPlistForDeviceWithIdentifier:(NSString *)anIdentifier;

/** Return the path to the `wholeStore.ticdsync` file uploaded by a client with a specified identifier. 
 
 @param anIdentifier The identifier of the client.
 
 @return The path to the client's `wholeStore.ticdsync` file. */
- (NSString *)pathToWholeStoreFileForDeviceWithIdentifier:(NSString *)anIdentifier;

@end
