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
    
    if ([self ti_delegateRespondsToSelector:@selector(removeAllSyncDataOperationWillRemoveAllSyncData:)]) {
        [self runOnMainQueueWithoutDeadlocking:^{
            [(id)self.delegate removeAllSyncDataOperationWillRemoveAllSyncData:self];
        }];
    }
    TICDSLog(TICDSLogVerbosityEveryStep, @"Clearing cryptor's password and salt");
    if( ![self cryptor] ) {
        FZACryptor *aCryptor = [[FZACryptor alloc] init];
        [self setCryptor:aCryptor];
    }
    [[self cryptor] clearPasswordAndSalt];
    
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
    if ([self ti_delegateRespondsToSelector:@selector(removeAllSyncDataOperationDidRemoveAllSyncData:)]) {
        [self runOnMainQueueWithoutDeadlocking:^{
            [(id)self.delegate removeAllSyncDataOperationDidRemoveAllSyncData:self];
        }];
    }
    
    [self operationDidCompleteSuccessfully];
}

#pragma mark Overridden Method
- (void)removeRemoteSyncDataDirectory
{
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeMethodNotOverriddenBySubclass classAndMethod:__PRETTY_FUNCTION__]];
    [self removedRemoteSyncDataDirectoryWithSuccess:NO];
}

#pragma mark - Initialization and Deallocation
- (id)initWithDelegate:(NSObject<TICDSRemoveAllRemoteSyncDataOperationDelegate> *)aDelegate
{
    return [super initWithDelegate:aDelegate];
}


@end
