//
//  TICDSDropboxSDKBasedApplicationRegistrationOperation.h
//  iOSNotebook
//
//  Created by Tim Isted on 13/05/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICoreDataSync.h"
#import "DropboxSDK.h"

/**
 `TICDSDropboxSDKBasedApplicationRegistrationOperation` is an application registration operation designed for use with a `TICDSDropboxSDKBasedApplicationSyncManager`.
 */

@interface TICDSDropboxSDKBasedApplicationRegistrationOperation : TICDSApplicationRegistrationOperation <DBRestClientDelegate> {
@private
    DBSession *_dbSession;
    DBRestClient *_appDirectoryRestClient;
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

/** The DropboxSDK `DBRestClient` for use by this operation for methods relating to the global application directory. */
@property (nonatomic, retain) DBRestClient *appDirectoryRestClient;

/** The application root path. */
@property (retain) NSString *applicationDirectoryPath;

/** The path to the `salt.ticdsync` file inside this application's `Encryption` directory. */
@property (retain) NSString *encryptionDirectorySaltDataFilePath;

/** The path to the `test.ticdsync` file inside this application's `Encryption` directory. */
@property (retain) NSString *encryptionDirectoryTestDataFilePath;

/** The path to this client's directory in the `ClientDevices` directory. */
@property (retain) NSString *clientDevicesThisClientDeviceDirectoryPath;

@end
