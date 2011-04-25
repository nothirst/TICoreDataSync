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
