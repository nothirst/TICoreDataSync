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
    BOOL success = [[self fileManager] removeItemAtPath:[self applicationDirectoryPath] error:&anyError];
    
    if( !success ) {
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
    }
    
    [self removedRemoteSyncDataDirectoryWithSuccess:success];
}

#pragma mark -
#pragma mark Initialization and Deallocation
- (void)dealloc
{
    [_applicationDirectoryPath release], _applicationDirectoryPath = nil;
    
    [super dealloc];
}

#pragma mark -
#pragma mark Properties
@synthesize applicationDirectoryPath = _applicationDirectoryPath;

@end
