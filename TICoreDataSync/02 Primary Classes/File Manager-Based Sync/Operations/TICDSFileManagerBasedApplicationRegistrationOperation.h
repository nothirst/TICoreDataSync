//
//  TICDSFileManagerBasedApplicationRegistrationOperation.h
//  ShoppingListMac
//
//  Created by Tim Isted on 22/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICDSApplicationRegistrationOperation.h"

/**
 `TICDSFileManagerBasedApplicationRegistrationOperation` is an application registration operation designed for use with a `TICDSFileManagerBasedApplicationSyncManager`.
 */

@interface TICDSFileManagerBasedApplicationRegistrationOperation : TICDSApplicationRegistrationOperation {
@private
    NSString *_applicationDirectoryPath;
    NSString *_encryptionDirectorySaltDataFilePath;
    NSString *_encryptionDirectoryTestDataFilePath;
    NSString *_clientDevicesDirectoryPath;
    NSString *_clientDevicesThisClientDeviceDirectoryPath;
}

/** @name Properties */

/** The path to the application root directory. */
@property (copy) NSString *applicationDirectoryPath;

/** The path to the `salt.ticdsync` file inside this application's `Encryption` directory. */
@property (copy) NSString *encryptionDirectorySaltDataFilePath;

/** The path to the `test.ticdsync` file inside this application's `Encryption` directory. */
@property (copy) NSString *encryptionDirectoryTestDataFilePath;

/** The path to the `ClientDevices` directory. */
@property (copy) NSString *clientDevicesDirectoryPath;

/** The path to the this client's directory inside the `ClientDevices` directory. */
@property (copy) NSString *clientDevicesThisClientDeviceDirectoryPath;

@end
