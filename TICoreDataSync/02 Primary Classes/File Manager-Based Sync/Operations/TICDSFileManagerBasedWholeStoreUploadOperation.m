//
//  TICDSFileManagerBasedWholeStoreUploadOperation.m
//  ShoppingListMac
//
//  Created by Tim Isted on 25/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICoreDataSync.h"


@implementation TICDSFileManagerBasedWholeStoreUploadOperation

- (void)checkWhetherThisClientWholeStoreDirectoryExists
{
    if( [[self fileManager] fileExistsAtPath:[self thisDocumentWholeStoreThisClientDirectoryPath]] ) {
        [self discoveredStatusOfWholeStoreDirectory:TICDSRemoteFileStructureExistsResponseTypeDoesExist];
    } else {
        [self discoveredStatusOfWholeStoreDirectory:TICDSRemoteFileStructureExistsResponseTypeDoesNotExist];
    }
}

- (void)createThisClientWholeStoreDirectory
{
    NSError *anyError = nil;
    
    BOOL success = [[self fileManager] createDirectoryAtPath:[self thisDocumentWholeStoreThisClientDirectoryPath] withIntermediateDirectories:NO attributes:nil error:&anyError];
    
    if( !success ) {
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
        [self createdThisClientWholeStoreDirectorySuccessfully:NO];
        return;
    }
    
    [self createdThisClientWholeStoreDirectorySuccessfully:YES];
}

- (void)uploadWholeStoreFile
{
    NSError *anyError = nil;
    BOOL success = YES;
    
    NSString *backupFilePath = [[self thisDocumentWholeStoreThisClientDirectoryPath] stringByAppendingPathComponent:@"WholeStoreBackup.ticdsync"];
    
    // Delete the backup, if it exists
    if( [[self fileManager] fileExistsAtPath:backupFilePath] ) {
        success = [[self fileManager] removeItemAtPath:backupFilePath error:&anyError];
    }
    
    if( !success ) {
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
        [self uploadedWholeStoreFileWithSuccess:NO];
        return;
    }
    
    // Move the existing file, if it exists, to the backup location
    if( [[self fileManager] fileExistsAtPath:[self thisDocumentWholeStoreThisClientDirectoryWholeStoreFilePath]] ) {
        success = [[self fileManager] moveItemAtPath:[self thisDocumentWholeStoreThisClientDirectoryWholeStoreFilePath] toPath:backupFilePath error:&anyError];
    }
    
    if( !success ) {
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
        [self uploadedWholeStoreFileWithSuccess:NO];
        return;
    }
    
    // Copy the whole store to the correct location
    success = [[self fileManager] copyItemAtPath:[[self localWholeStoreFileLocation] path] toPath:[self thisDocumentWholeStoreThisClientDirectoryWholeStoreFilePath] error:&anyError];
    
    if( !success ) {
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
        [self uploadedWholeStoreFileWithSuccess:NO];
        return;
    }
    
    // Delete the backup, if it exists
    if( [[self fileManager] fileExistsAtPath:backupFilePath] ) {
        success = [[self fileManager] removeItemAtPath:backupFilePath error:&anyError];
    }
    
    if( !success ) {
        // not being able to delete the backup file isn't catastrophic...
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Failed to delete the whole store backup file, but carrying on as it's not catastrophic");
    }
    
    // If we get this far, everything went to plan
    [self uploadedWholeStoreFileWithSuccess:YES];
}

- (void)uploadAppliedSyncChangeSetsFile
{
    NSError *anyError = nil;
    BOOL success = YES;
    
    NSString *backupFilePath = [[self thisDocumentWholeStoreThisClientDirectoryPath] stringByAppendingPathComponent:@"AppliedSyncChangeSetsBackup.ticdsync"];
    
    // Delete the backup, if it exists
    if( [[self fileManager] fileExistsAtPath:backupFilePath] ) {
        success = [[self fileManager] removeItemAtPath:backupFilePath error:&anyError];
    }
    
    if( !success ) {
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
        [self uploadedAppliedSyncChangeSetsFileWithSuccess:NO];
        return;
    }
    
    // Move the existing file, if it exists, to the backup location
    if( [[self fileManager] fileExistsAtPath:[self thisDocumentWholeStoreThisClientDirectoryAppliedSyncChangeSetsFilePath]] ) {
        success = [[self fileManager] moveItemAtPath:[self thisDocumentWholeStoreThisClientDirectoryAppliedSyncChangeSetsFilePath] toPath:backupFilePath error:&anyError];
    }
    
    if( !success ) {
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
        [self uploadedAppliedSyncChangeSetsFileWithSuccess:NO];
        return;
    }
    
    // Copy the whole store to the correct location
    success = [[self fileManager] copyItemAtPath:[[self localAppliedSyncChangeSetsFileLocation] path] toPath:[self thisDocumentWholeStoreThisClientDirectoryAppliedSyncChangeSetsFilePath] error:&anyError];
    
    if( !success ) {
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
        [self uploadedAppliedSyncChangeSetsFileWithSuccess:NO];
        return;
    }
    
    // Delete the backup, if it exists
    if( [[self fileManager] fileExistsAtPath:backupFilePath] ) {
        success = [[self fileManager] removeItemAtPath:backupFilePath error:&anyError];
    }
    
    if( !success ) {
        // not being able to delete the backup file isn't catastrophic...
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Failed to delete the applied sync changes backup file, but carrying on as it's not catastrophic");
    }
    
    // If we get this far, everything went to plan
    [self uploadedAppliedSyncChangeSetsFileWithSuccess:YES];
}

#pragma mark -
#pragma mark Initialization and Deallocation
- (void)dealloc
{
    [_thisDocumentWholeStoreThisClientDirectoryPath release], _thisDocumentWholeStoreThisClientDirectoryPath = nil;
    [_thisDocumentWholeStoreThisClientDirectoryWholeStoreFilePath release], _thisDocumentWholeStoreThisClientDirectoryWholeStoreFilePath = nil;
    [_thisDocumentWholeStoreThisClientDirectoryAppliedSyncChangeSetsFilePath release], _thisDocumentWholeStoreThisClientDirectoryAppliedSyncChangeSetsFilePath = nil;

    [super dealloc];
}

#pragma mark -
#pragma mark Properties
@synthesize thisDocumentWholeStoreThisClientDirectoryPath = _thisDocumentWholeStoreThisClientDirectoryPath;
@synthesize thisDocumentWholeStoreThisClientDirectoryWholeStoreFilePath = _thisDocumentWholeStoreThisClientDirectoryWholeStoreFilePath;
@synthesize thisDocumentWholeStoreThisClientDirectoryAppliedSyncChangeSetsFilePath = _thisDocumentWholeStoreThisClientDirectoryAppliedSyncChangeSetsFilePath;

@end
