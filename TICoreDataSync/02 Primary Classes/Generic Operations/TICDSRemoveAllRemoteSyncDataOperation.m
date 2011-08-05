//
//  TICDSRemoveAllRemoteSyncDataOperation.m
//  iOSNotebook
//
//  Created by Tim Isted on 05/08/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICoreDataSync.h"

@interface TICDSRemoveAllRemoteSyncDataOperation ()

- (void)beginRemovingAllRemoteSyncData;

@end

@implementation TICDSRemoveAllRemoteSyncDataOperation

- (void)main
{
    [self beginRemovingAllRemoteSyncData];
}

#pragma mark - Deleting Existing identifier.plist File
- (void)beginRemovingAllRemoteSyncData
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachOperationPhase, @"Removing entire remote sync data directory");
    
    [self removeRemoteSyncDataDirectory];
}

- (void)removedRemoteSyncDataDirectoryWithSuccess:(BOOL)success
{
    if( !success ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Failed to remove all sync data");
        [self operationDidFailToComplete];
        return;
    }
    
    TICDSLog(TICDSLogVerbosityEveryStep, @"Removed all sync data");
    
    [self operationDidCompleteSuccessfully];
}

#pragma mark Overridden Method
- (void)removeRemoteSyncDataDirectory
{
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeMethodNotOverriddenBySubclass classAndMethod:__PRETTY_FUNCTION__]];
    [self removedRemoteSyncDataDirectoryWithSuccess:NO];
}

#pragma mark -
#pragma mark Initialization and Deallocation
- (void)dealloc
{
    [super dealloc];
}

@end
