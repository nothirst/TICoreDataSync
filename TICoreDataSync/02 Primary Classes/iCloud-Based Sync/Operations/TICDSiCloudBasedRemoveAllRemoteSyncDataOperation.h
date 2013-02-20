//
//  TICDSiCloudBasedRemoveAllRemoteSyncDataOperation.h
//  Notebook
//
//  Created by Tim Isted on 05/08/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICDSRemoveAllRemoteSyncDataOperation.h"

/**
 `TICDSiCloudBasedRemoveAllRemoteSyncDataOperation` is a 'remove all remote sync data' operation designed for use with a `TICDSiCloudBasedApplicationSyncManager`.
 */

@interface TICDSiCloudBasedRemoveAllRemoteSyncDataOperation : TICDSRemoveAllRemoteSyncDataOperation {
@private
    NSString *_applicationDirectoryPath;
}

/** @name Properties */

/** The path to the application root directory. */
@property (retain) NSString *applicationDirectoryPath;

@end
