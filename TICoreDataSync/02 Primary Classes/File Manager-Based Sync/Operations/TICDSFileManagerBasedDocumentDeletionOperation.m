//
//  TICDSFileManagerBasedDocumentDeletionOperation.m
//  Notebook
//
//  Created by Tim Isted on 29/05/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICoreDataSync.h"


@implementation TICDSFileManagerBasedDocumentDeletionOperation

#pragma mark - Overridden Methods
- (void)checkWhetherIdentifiedDocumentDirectoryExists
{
    if( [[self fileManager] fileExistsAtPath:[self documentDirectoryPath]] ) {
        [self discoveredStatusOfIdentifiedDocumentDirectory:TICDSRemoteFileStructureExistsResponseTypeDoesExist];
    } else {
        [self discoveredStatusOfIdentifiedDocumentDirectory:TICDSRemoteFileStructureExistsResponseTypeDoesNotExist];
    }
}

- (void)checkForExistingIdentifierPlistInDeletedDocumentsDirectory
{
    if( [[self fileManager] fileExistsAtPath:[self deletedDocumentsDirectoryIdentifierPlistFilePath]] ) {
        [self discoveredStatusOfIdentifierPlistInDeletedDocumentsDirectory:TICDSRemoteFileStructureExistsResponseTypeDoesExist];
    } else {
        [self discoveredStatusOfIdentifierPlistInDeletedDocumentsDirectory:TICDSRemoteFileStructureExistsResponseTypeDoesNotExist];
    }
}

- (void)deleteDocumentInfoPlistFromDeletedDocumentsDirectory
{
    NSError *anyError = nil;
    BOOL success = [[self fileManager] removeItemAtPath:[self deletedDocumentsDirectoryIdentifierPlistFilePath] error:&anyError];
    
    if( !success ) {
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
    }
    
    [self deletedDocumentInfoPlistFromDeletedDocumentsDirectoryWithSuccess:success];
}

- (void)copyDocumentInfoPlistToDeletedDocumentsDirectory
{
    NSError *anyError = nil;
    BOOL success = [[self fileManager] copyItemAtPath:[self documentInfoPlistFilePath] toPath:[self deletedDocumentsDirectoryIdentifierPlistFilePath] error:&anyError];
    
    if( !success ) {
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
    }
    
    [self copiedDocumentInfoPlistToDeletedDocumentsDirectoryWithSuccess:success];
}

- (void)deleteDocumentDirectory
{
    NSError *anyError = nil;
    BOOL success = [[self fileManager] removeItemAtPath:[self documentDirectoryPath] error:&anyError];
    
    if( !success ) {
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
    }
    
    [self deletedDocumentDirectoryWithSuccess:success];
}

#pragma mark - Initialization and Deallocation
- (void)dealloc
{
    _documentDirectoryPath = nil;
    _documentInfoPlistFilePath = nil;
    _deletedDocumentsDirectoryIdentifierPlistFilePath = nil;
    
}
#pragma mark - Properties
@synthesize documentDirectoryPath = _documentDirectoryPath;
@synthesize documentInfoPlistFilePath = _documentInfoPlistFilePath;
@synthesize deletedDocumentsDirectoryIdentifierPlistFilePath = _deletedDocumentsDirectoryIdentifierPlistFilePath;

@end
