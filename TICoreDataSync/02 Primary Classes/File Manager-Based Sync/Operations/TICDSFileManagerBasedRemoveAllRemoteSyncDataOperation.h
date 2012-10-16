//
//  TICDSFileManagerBasedRemoveAllRemoteSyncDataOperation.h
//  Notebook
//
//  Created by Tim Isted on 05/08/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICDSRemoveAllRemoteSyncDataOperation.h"

/**
 `TICDSFileManagerBasedRemoveAllRemoteSyncDataOperation` is a 'remove all remote sync data' operation designed for use with a `TICDSFileManagerBasedApplicationSyncManager`.
 */

@interface TICDSFileManagerBasedRemoveAllRemoteSyncDataOperation : TICDSRemoveAllRemoteSyncDataOperation {
@private
    NSString *_applicationDirectoryPath;
}

/** @name Properties */

/** The path to the application root directory. */
@property (copy) NSString *applicationDirectoryPath;

@end
