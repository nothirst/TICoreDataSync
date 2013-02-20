//
//  TICDSiCloudBasedApplicationRegistrationOperation.h
//  ShoppingListMac
//
//  Created by Tim Isted on 22/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICDSApplicationRegistrationOperation.h"

/**
 `TICDSiCloudBasedApplicationRegistrationOperation` is an application registration operation designed for use with a `TICDSiCloudBasedApplicationSyncManager`.
 */

@interface TICDSiCloudBasedApplicationRegistrationOperation : TICDSApplicationRegistrationOperation {
@private
    NSString *_applicationDirectoryPath;
    NSString *_encryptionDirectorySaltDataFilePath;
    NSString *_encryptionDirectoryTestDataFilePath;
    NSString *_clientDevicesDirectoryPath;
    NSString *_clientDevicesThisClientDeviceDirectoryPath;
}

/** @name Properties */

/** The path to the application root directory. */
@property (retain) NSString *applicationDirectoryPath;

/** The path to the `salt.ticdsync` file inside this application's `Encryption` directory. */
@property (retain) NSString *encryptionDirectorySaltDataFilePath;

/** The path to the `test.ticdsync` file inside this application's `Encryption` directory. */
@property (retain) NSString *encryptionDirectoryTestDataFilePath;

/** The path to the `ClientDevices` directory. */
@property (retain) NSString *clientDevicesDirectoryPath;

/** The path to the this client's directory inside the `ClientDevices` directory. */
@property (retain) NSString *clientDevicesThisClientDeviceDirectoryPath;

@end
