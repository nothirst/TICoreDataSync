//
//  TICDSFileManagerBasedApplicationSyncManager.h
//  ShoppingListMac
//
//  Created by Tim Isted on 22/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICDSApplicationSyncManager.h"

/** The `TICDSFileManagerBasedApplicationSyncManager` describes a class used to synchronize an application with a remote service that can be accessed via an `NSFileManager`. This includes:
 
 1. Dropbox (files are typically accessed via `~/Dropbox`)
 2. iDisk
 
 The only requirement is that you set the `NSURL` location of the directory that should contain the application *before* you register the sync manager. For example, if you wish to have sync information stored in `~/Dropbox/com.timisted.MySynchronizedApp/`, specify `~/Dropbox` as the `applicationContainingDirectoryLocation`.
 */

@interface TICDSFileManagerBasedApplicationSyncManager : TICDSApplicationSyncManager {
@private
    NSURL *_applicationContainingDirectoryLocation;
}

/** @name Properties */

/** The location of the directory that should contain the file structure for this application's synchronization. */
@property (nonatomic, retain) NSURL *applicationContainingDirectoryLocation;

/** @name Paths */

/** The path to the root application directory. */
@property (nonatomic, readonly) NSString *applicationDirectoryPath;

/** The path to the `Documents` directory at the root of the application. */
@property (nonatomic, readonly) NSString *documentsDirectoryPath;

/** The path to the `ClientDevices` directory at the root of the application. */
@property (nonatomic, readonly) NSString *clientDevicesDirectoryPath;

/** The path to this client's directory inside the `ClientDevices` directory at the root of the application. */
@property (nonatomic, readonly) NSString *clientDevicesThisClientDeviceDirectoryPath;

/** The path to the `WholeStore` directory for a document with a given identifier. */
- (NSString *)pathToWholeStoreDirectoryForDocumentWithIdentifier:(NSString *)anIdentifier;

@end
