//
//  TICDSFileManagerBasedListOfApplicationRegisteredClientsOperation.h
//  Notebook
//
//  Created by Tim Isted on 23/05/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICDSListOfApplicationRegisteredClientsOperation.h"

/**
 `TICDSFileManagerBasedListOfApplicationRegisteredClientsOperation` is a "list of clients registered to an application" operation designed for use with a `TICDSFileManagerBasedApplicationSyncManager`.
 */

@interface TICDSFileManagerBasedListOfApplicationRegisteredClientsOperation : TICDSListOfApplicationRegisteredClientsOperation {
@private
    NSString *_clientDevicesDirectoryPath;
    NSString *_documentsDirectoryPath;
}

/** @name Paths */

/** The path to the `ClientDevices` directory. */
@property (copy) NSString *clientDevicesDirectoryPath;

/** The path to the `Documents` directory. */
@property (copy) NSString *documentsDirectoryPath;

@end
