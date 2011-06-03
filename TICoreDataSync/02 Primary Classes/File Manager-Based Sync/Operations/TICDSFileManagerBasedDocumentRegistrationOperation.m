//
//  TICDSFileManagerBasedDocumentRegistrationOperation.m
//  ShoppingListMac
//
//  Created by Tim Isted on 23/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICoreDataSync.h"

@implementation TICDSFileManagerBasedDocumentRegistrationOperation

#pragma mark -
#pragma mark Helper Methods
- (BOOL)createDirectoryContentsFromDictionary:(NSDictionary *)aDictionary inDirectory:(NSString *)aPath
{
    NSError *anyError = nil;
    
    for( NSString *eachName in [aDictionary allKeys] ) {
        
        id object = [aDictionary valueForKey:eachName];
        
        if( [object isKindOfClass:[NSDictionary class]] ) {
            NSString *thisPath = [aPath stringByAppendingPathComponent:eachName];
            
            // create directory
            BOOL success = [[self fileManager] createDirectoryAtPath:thisPath withIntermediateDirectories:YES attributes:nil error:&anyError];
            if( !success ) {
                [self setError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
                return NO;
            }
            
            success = [self createDirectoryContentsFromDictionary:object inDirectory:thisPath];
            if( !success ) {
                return NO;
            }
            
        }
    }
    
    return YES;
}

#pragma mark -
#pragma mark Overridden Document Methods
- (void)checkWhetherRemoteDocumentDirectoryExists
{
    if( [[self fileManager] fileExistsAtPath:[self thisDocumentDirectoryPath]] ) {
        [self discoveredStatusOfRemoteDocumentDirectory:TICDSRemoteFileStructureExistsResponseTypeDoesExist];
    } else {
        [self discoveredStatusOfRemoteDocumentDirectory:TICDSRemoteFileStructureExistsResponseTypeDoesNotExist];
    }
}

- (void)checkWhetherRemoteDocumentWasDeleted
{
    if( [[self fileManager] fileExistsAtPath:[self deletedDocumentsThisDocumentIdentifierPlistPath]] ) {
        [self discoveredDeletionStatusOfRemoteDocument:TICDSRemoteFileStructureDeletionResponseTypeDeleted];
    } else {
        [self discoveredDeletionStatusOfRemoteDocument:TICDSRemoteFileStructureDeletionResponseTypeNotDeleted];
    }
}

- (void)createRemoteDocumentDirectoryStructure
{
    NSDictionary *documentStructure = [TICDSUtilities remoteDocumentDirectoryHierarchy];
    
    NSError *anyError = nil;
    BOOL success = [self createDirectoryContentsFromDictionary:documentStructure inDirectory:[self thisDocumentDirectoryPath]];
    
    if( !success ) {
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
    }
    
    [self createdRemoteDocumentDirectoryStructureWithSuccess:success];
}

- (void)saveRemoteDocumentInfoPlistFromDictionary:(NSDictionary *)aDictionary
{
    BOOL success = YES;
    NSString *finalFilePath = [[self thisDocumentDirectoryPath] stringByAppendingPathComponent:TICDSDocumentInfoPlistFilenameWithExtension];
    
    if( ![self shouldUseEncryption] ) {
        success = [aDictionary writeToFile:finalFilePath atomically:NO];
        
        if( !success ) {
            [self setError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError classAndMethod:__PRETTY_FUNCTION__]];
        }
        
        [self savedRemoteDocumentInfoPlistWithSuccess:success];
        return;
    }
    
    // if encryption, save to temporary directory first, then encrypt, writing directly to final location
    NSString *tmpFilePath = [[self tempFileDirectoryPath] stringByAppendingPathComponent:TICDSDocumentInfoPlistFilenameWithExtension];
    
    success = [aDictionary writeToFile:tmpFilePath atomically:NO];
    
    if( !success ) {
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError classAndMethod:__PRETTY_FUNCTION__]];
        [self savedRemoteDocumentInfoPlistWithSuccess:success];
        return;
    }
    
    NSError *anyError = nil;
    success = [[self cryptor] encryptFileAtLocation:[NSURL fileURLWithPath:tmpFilePath] writingToLocation:[NSURL fileURLWithPath:finalFilePath] error:&anyError];
    
    if( !success ) {
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeEncryptionError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
    }
    
    [self savedRemoteDocumentInfoPlistWithSuccess:success];
}

- (void)fetchListOfIdentifiersOfAllRegisteredClientsForThisApplication
{
    NSError *anyError = nil;
    
    NSArray *contents = [[self fileManager] contentsOfDirectoryAtPath:[self clientDevicesDirectoryPath] error:&anyError];
    
    if( !contents ) {
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
    }
    
    [self fetchedListOfIdentifiersOfAllRegisteredClientsForThisApplication:contents];
}

- (void)addDeviceInfoPlistToDocumentDeletedClientsForClientWithIdentifier:(NSString *)anIdentifier
{
    NSError *anyError = nil;
    
    NSString *deviceInfoPlistPath = [[[self clientDevicesDirectoryPath] stringByAppendingPathComponent:anIdentifier] stringByAppendingPathComponent:TICDSDeviceInfoPlistFilenameWithExtension];
    
    NSString *finalFilePath = [[[self thisDocumentDeletedClientsDirectoryPath] stringByAppendingPathComponent:anIdentifier] stringByAppendingPathExtension:TICDSDeviceInfoPlistExtension];
    
    BOOL success = [[self fileManager] copyItemAtPath:deviceInfoPlistPath toPath:finalFilePath error:&anyError];
    
    if( !success ) {
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
    }
    
    [self addedDeviceInfoPlistToDocumentDeletedClientsForClientWithIdentifier:anIdentifier withSuccess:success];
}

- (void)deleteDocumentInfoPlistFromDeletedDocumentsDirectory
{
    NSError *anyError = nil;
    BOOL success = [[self fileManager] removeItemAtPath:[self deletedDocumentsThisDocumentIdentifierPlistPath] error:&anyError];
    
    if( !success ) {
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
    }
    
    [self deletedDocumentInfoPlistFromDeletedDocumentsDirectoryWithSuccess:success];
}

#pragma mark -
#pragma mark Overridden Client Device Directories
- (void)checkWhetherClientDirectoryExistsInRemoteDocumentSyncChangesDirectory
{
    if( [[self fileManager] fileExistsAtPath:[self thisDocumentSyncChangesThisClientDirectoryPath]] ) {
        [self discoveredStatusOfClientDirectoryInRemoteDocumentSyncChangesDirectory:TICDSRemoteFileStructureExistsResponseTypeDoesExist];
    } else {
        [self discoveredStatusOfClientDirectoryInRemoteDocumentSyncChangesDirectory:TICDSRemoteFileStructureExistsResponseTypeDoesNotExist];
    }
}

- (void)createClientDirectoriesInRemoteDocumentDirectories
{
    NSError *anyError = nil;
    BOOL success = NO;
    success = [[self fileManager] createDirectoryAtPath:[self thisDocumentSyncChangesThisClientDirectoryPath] withIntermediateDirectories:NO attributes:nil error:&anyError];
    
    if( !success ) {
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
        [self createdClientDirectoriesInRemoteDocumentDirectoriesWithSuccess:NO];
        return;
    }
    
    success = [[self fileManager] createDirectoryAtPath:[self thisDocumentSyncCommandsThisClientDirectoryPath] withIntermediateDirectories:NO attributes:nil error:&anyError];
    
    if( !success ) {
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
    }
    
    [self createdClientDirectoriesInRemoteDocumentDirectoriesWithSuccess:success];
}

#pragma mark -
#pragma mark Initialization and Deallocation
- (void)dealloc
{
    [_documentsDirectoryPath release], _documentsDirectoryPath = nil;
    [_clientDevicesDirectoryPath release], _clientDevicesDirectoryPath = nil;
    [_thisDocumentDeletedClientsDirectoryPath release], _thisDocumentDeletedClientsDirectoryPath = nil;
    [_deletedDocumentsThisDocumentIdentifierPlistPath release], _deletedDocumentsThisDocumentIdentifierPlistPath = nil;
    [_thisDocumentDirectoryPath release], _thisDocumentDirectoryPath = nil;
    [_thisDocumentSyncChangesThisClientDirectoryPath release], _thisDocumentSyncChangesThisClientDirectoryPath = nil;
    [_thisDocumentSyncCommandsThisClientDirectoryPath release], _thisDocumentSyncCommandsThisClientDirectoryPath = nil;

    [super dealloc];
}

#pragma mark -
#pragma mark Properties
@synthesize documentsDirectoryPath = _documentsDirectoryPath;
@synthesize clientDevicesDirectoryPath = _clientDevicesDirectoryPath;
@synthesize deletedDocumentsThisDocumentIdentifierPlistPath = _deletedDocumentsThisDocumentIdentifierPlistPath;
@synthesize thisDocumentDeletedClientsDirectoryPath = _thisDocumentDeletedClientsDirectoryPath;
@synthesize thisDocumentDirectoryPath = _thisDocumentDirectoryPath;
@synthesize thisDocumentSyncChangesThisClientDirectoryPath = _thisDocumentSyncChangesThisClientDirectoryPath;
@synthesize thisDocumentSyncCommandsThisClientDirectoryPath = _thisDocumentSyncCommandsThisClientDirectoryPath;

@end
