//
//  TICDSiCloudBasedWholeStoreUploadOperation.m
//  ShoppingListMac
//
//  Created by Tim Isted on 25/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICoreDataSync.h"


@implementation TICDSiCloudBasedWholeStoreUploadOperation

- (void)checkWhetherThisClientTemporaryWholeStoreDirectoryExists
{
    TICDSRemoteFileStructureExistsResponseType status = [self fileExistsAtPath:[self thisDocumentTemporaryWholeStoreThisClientDirectoryPath]] ? TICDSRemoteFileStructureExistsResponseTypeDoesExist : TICDSRemoteFileStructureExistsResponseTypeDoesNotExist;
    
    [self discoveredStatusOfThisClientTemporaryWholeStoreDirectory:status];
}

- (void)deleteThisClientTemporaryWholeStoreDirectory
{
    NSError *anyError = nil;
    
    BOOL success = [self removeItemAtPath:[self thisDocumentTemporaryWholeStoreThisClientDirectoryPath] error:&anyError];
    
    if( !success ) {
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
    }
    
    [self deletedThisClientTemporaryWholeStoreDirectoryWithSuccess:success];
}

- (void)createThisClientTemporaryWholeStoreDirectory
{
    NSError *anyError = nil;
    
    BOOL success = [self createDirectoryAtPath:[self thisDocumentTemporaryWholeStoreThisClientDirectoryPath] withIntermediateDirectories:NO attributes:nil error:&anyError];
    
    if( !success ) {
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
    }
    
    [self createdThisClientTemporaryWholeStoreDirectoryWithSuccess:success];
}

- (void)uploadLocalWholeStoreFileToThisClientTemporaryWholeStoreDirectory
{
    NSError *anyError = nil;
    BOOL success = YES;
    NSString *filePath = [[self localWholeStoreFileLocation] path];
    
    if( [self shouldUseEncryption] ) {
        BOOL isDir;
        NSAssert( [self.fileManager fileExistsAtPath:filePath isDirectory:&isDir] && !isDir, @"Encryption not supported when whole store is directory.");
        
        NSString *tempPath = [[self tempFileDirectoryPath] stringByAppendingPathComponent:[filePath lastPathComponent]];
        
        success = [[self cryptor] encryptFileAtLocation:[NSURL fileURLWithPath:filePath] writingToLocation:[NSURL fileURLWithPath:tempPath] error:&anyError];
        if( !success ) {
            [self setError:[TICDSError errorWithCode:TICDSErrorCodeEncryptionError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
            [self uploadedWholeStoreFileToThisClientTemporaryWholeStoreDirectoryWithSuccess:NO];
            return;
        }
        
        filePath = tempPath;
    }
    
    success = [self copyItemAtPath:filePath toPath:[self thisDocumentTemporaryWholeStoreThisClientDirectoryWholeStoreFilePath] error:&anyError];
    
    if( !success ) {
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
    }
    
    [self uploadedWholeStoreFileToThisClientTemporaryWholeStoreDirectoryWithSuccess:success];
}

- (void)uploadLocalAppliedSyncChangeSetsFileToThisClientTemporaryWholeStoreDirectory
{
    NSError *anyError = nil;
    
    BOOL success = [self copyItemAtPath:[[self localAppliedSyncChangeSetsFileLocation] path] toPath:[self thisDocumentTemporaryWholeStoreThisClientDirectoryAppliedSyncChangeSetsFilePath] error:&anyError];
    
    if( !success ) {
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
    }
    
    [self uploadedAppliedSyncChangeSetsFileToThisClientTemporaryWholeStoreDirectoryWithSuccess:success];
}

- (void)checkWhetherThisClientWholeStoreDirectoryExists
{
    TICDSRemoteFileStructureExistsResponseType status = [self fileExistsAtPath:[self thisDocumentWholeStoreThisClientDirectoryPath]] ? TICDSRemoteFileStructureExistsResponseTypeDoesExist : TICDSRemoteFileStructureExistsResponseTypeDoesNotExist;
    
    [self discoveredStatusOfThisClientWholeStoreDirectory:status];
}

- (void)deleteThisClientWholeStoreDirectory
{
    NSError *anyError = nil;
    
    BOOL success = [self removeItemAtPath:[self thisDocumentWholeStoreThisClientDirectoryPath] error:&anyError];
    
    if( !success ) {
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
    }
    
    [self deletedThisClientWholeStoreDirectoryWithSuccess:success];
}

- (void)copyThisClientTemporaryWholeStoreDirectoryToThisClientWholeStoreDirectory
{
    NSError *anyError = nil;
    
    BOOL success = [self copyItemAtPath:[self thisDocumentTemporaryWholeStoreThisClientDirectoryPath] toPath:[self thisDocumentWholeStoreThisClientDirectoryPath] error:&anyError];
    
    if( !success ) {
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
    }
    
    [self copiedThisClientTemporaryWholeStoreDirectoryToThisClientWholeStoreDirectoryWithSuccess:success];
}

#pragma mark -
#pragma mark Properties
@synthesize thisDocumentTemporaryWholeStoreThisClientDirectoryPath = _thisDocumentTemporaryWholeStoreThisClientDirectoryPath;
@synthesize thisDocumentTemporaryWholeStoreThisClientDirectoryWholeStoreFilePath = _thisDocumentTemporaryWholeStoreThisClientDirectoryWholeStoreFilePath;
@synthesize thisDocumentTemporaryWholeStoreThisClientDirectoryAppliedSyncChangeSetsFilePath = _thisDocumentTemporaryWholeStoreThisClientDirectoryAppliedSyncChangeSetsFilePath;
@synthesize thisDocumentWholeStoreThisClientDirectoryPath = _thisDocumentWholeStoreThisClientDirectoryPath;

@end
