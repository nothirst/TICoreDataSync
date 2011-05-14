//
//  TICDSDropboxSDKBasedApplicationSyncManager.m
//  iOSNotebook
//
//  Created by Tim Isted on 13/05/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICoreDataSync.h"

#import "DropboxSDK.h"

@implementation TICDSDropboxSDKBasedApplicationSyncManager

#pragma mark -
#pragma mark Overridden Methods
- (TICDSApplicationRegistrationOperation *)applicationRegistrationOperation
{
    TICDSDropboxSDKBasedApplicationRegistrationOperation *operation = [[TICDSDropboxSDKBasedApplicationRegistrationOperation alloc] initWithDelegate:self];
    
    [operation setDbSession:[self dbSession]];
    [operation setApplicationDirectoryPath:[self applicationDirectoryPath]];
    [operation setEncryptionDirectorySaltDataFilePath:[self encryptionDirectorySaltDataFilePath]];
    [operation setEncryptionDirectoryTestDataFilePath:[self encryptionDirectoryTestDataFilePath]];
    [operation setClientDevicesThisClientDeviceDirectoryPath:[self clientDevicesThisClientDeviceDirectoryPath]];
    
    return [operation autorelease];
}

#pragma mark -
#pragma mark Paths
- (NSString *)applicationDirectoryPath
{
    return [NSString stringWithFormat:@"/%@", [self appIdentifier]];
}

- (NSString *)encryptionDirectorySaltDataFilePath
{
    return [[self applicationDirectoryPath] stringByAppendingPathComponent:[self relativePathToEncryptionDirectorySaltDataFilePath]];
}

- (NSString *)encryptionDirectoryTestDataFilePath
{
    return [[self applicationDirectoryPath] stringByAppendingPathComponent:[self relativePathToEncryptionDirectoryTestDataFilePath]];
}

- (NSString *)clientDevicesThisClientDeviceDirectoryPath
{
    return [[self applicationDirectoryPath] stringByAppendingPathComponent:[self relativePathToClientDevicesThisClientDeviceDirectory]];
}

#pragma mark -
#pragma mark Initialization and Deallocation
- (void)dealloc
{
    [_dbSession release], _dbSession = nil;

    [super dealloc];
}

#pragma mark -
#pragma mark Lazy Accessors
- (DBSession *)dbSession
{
    if( _dbSession ) {
        return _dbSession;
    }
    
    _dbSession = [[DBSession sharedSession] retain];
    
    return _dbSession;
}

#pragma mark -
#pragma mark Properties
@synthesize dbSession = _dbSession;

@end
