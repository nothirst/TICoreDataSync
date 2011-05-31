//
//  TICDSDropboxSDKBasedApplicationRegistrationOperation.h
//  iOSNotebook
//
//  Created by Tim Isted on 13/05/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#if TARGET_OS_IPHONE

#import "TICoreDataSync.h"
#import "DropboxSDK.h"

/**
 `TICDSDropboxSDKBasedApplicationRegistrationOperation` is an application registration operation designed for use with a `TICDSDropboxSDKBasedApplicationSyncManager`.
 */

@interface TICDSDropboxSDKBasedApplicationRegistrationOperation : TICDSApplicationRegistrationOperation <DBRestClientDelegate> {
@private
    DBSession *_dbSession;
    DBRestClient *_restClient;
    NSString *_applicationDirectoryPath;
    NSString *_encryptionDirectorySaltDataFilePath;
    NSString *_encryptionDirectoryTestDataFilePath;
    NSString *_clientDevicesThisClientDeviceDirectoryPath;
    
    NSUInteger _numberOfAppDirectoriesToCreate;
    NSUInteger _numberOfAppDirectoriesThatFailedToBeCreated;
    NSUInteger _numberOfAppDirectoriesThatWereCreated;
}

/** @name Properties */

/** The DropboxSDK `DBSession` for use by this operation's `DBRestClient`. */
@property (retain) DBSession *dbSession;

/** The DropboxSDK `DBRestClient` for use by this operation. */
@property (nonatomic, readonly) DBRestClient *restClient;

/** @name Paths */

/** The path to the root of the application. */
@property (retain) NSString *applicationDirectoryPath;

/** The path to the `salt.ticdsync` file inside the application's `Encryption` directory. */
@property (retain) NSString *encryptionDirectorySaltDataFilePath;

/** The path to the `test.ticdsync` file inside the application's `Encryption` directory. */
@property (retain) NSString *encryptionDirectoryTestDataFilePath;

/** The path to this client's directory in the `ClientDevices` directory. */
@property (retain) NSString *clientDevicesThisClientDeviceDirectoryPath;

@end

#endif