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
    NSString *_clientDevicesDirectoryPath;
    NSString *_clientDevicesThisClientDeviceDirectoryPath;
}

/** @name Properties */

/** The application root path. */
@property (retain) NSString *applicationDirectoryPath;

/** The path to the `salt.ticdsync` file inside this application's `Encryption` directory. */
@property (retain) NSString *encryptionDirectorySaltDataFilePath;

/** The path to the `ClientDevices` directory. */
@property (retain) NSString *clientDevicesDirectoryPath;

/** The path to the this client's directory inside the `ClientDevices` directory. */
@property (retain) NSString *clientDevicesThisClientDeviceDirectoryPath;

@end
