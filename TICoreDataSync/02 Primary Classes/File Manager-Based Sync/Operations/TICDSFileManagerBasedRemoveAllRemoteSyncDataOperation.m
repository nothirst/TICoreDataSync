//
//  TICDSFileManagerBasedRemoveAllRemoteSyncDataOperation.m
//  Notebook
//
//  Created by Tim Isted on 05/08/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICoreDataSync.h"


@implementation TICDSFileManagerBasedRemoveAllRemoteSyncDataOperation

- (void)removeRemoteSyncDataDirectory
{
    NSError *anyError = nil;
    
    if( ![[self fileManager] fileExistsAtPath:[self applicationDirectoryPath]] ) {
        // directory doesn't exist to delete, so deletion is 'complete'
        [self removedRemoteSyncDataDirectoryWithSuccess:YES];
        return;
    }
    
    BOOL success = [[self fileManager] removeItemAtPath:[self applicationDirectoryPath] error:&anyError];
    
    if( !success ) {
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
    }
    
    [self removedRemoteSyncDataDirectoryWithSuccess:success];
}

#pragma mark - Initialization and Deallocation
- (void)dealloc
{
    _applicationDirectoryPath = nil;
    
}

#pragma mark - Properties
@synthesize applicationDirectoryPath = _applicationDirectoryPath;

@end
