//
//  TICDSDropboxSDKBasedApplicationSyncManager.h
//  iOSNotebook
//
//  Created by Tim Isted on 13/05/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICDSApplicationSyncManager.h"

/** The `TICDSDropboxSDKBasedApplicationSyncManager` describes a class used to synchronize an iOS application with a remote service that can be accessed via the Dropbox SDK.
 
 The requirements are: 
 */

@class DBSession;

@interface TICDSDropboxSDKBasedApplicationSyncManager : TICDSApplicationSyncManager {
@private
    DBSession *_dbSession;
}

/** @name Properties */

/** The DropboxSDK `DBSession` object to use for Dropbox access. If you don't set this property, TICoreDataSync will use the `[DBSession sharedSession]`. */
@property (nonatomic, retain) DBSession *dbSession;

/** @name Paths */
/** The path to root application directory (will be `/globalAppIdentifier`). */
@property (nonatomic, readonly) NSString *applicationDirectoryPath;

/** The path to the `salt.ticdsync` file inside the `Encryption` directory at the root of the application. */
@property (nonatomic, readonly) NSString *encryptionDirectorySaltDataFilePath;

/** The path to the `test.ticdsync` file inside the `Encryption` directory at the root of the application. */
@property (nonatomic, readonly) NSString *encryptionDirectoryTestDataFilePath;

/** The path to this client's directory inside the `ClientDevices` directory at the root of the application. */
@property (nonatomic, readonly) NSString *clientDevicesThisClientDeviceDirectoryPath;

@end
