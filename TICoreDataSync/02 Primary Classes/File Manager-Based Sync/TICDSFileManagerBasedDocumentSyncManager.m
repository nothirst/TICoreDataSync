//
//  TICDSFileManagerBasedDocumentSyncManager.m
//  ShoppingListMac
//
//  Created by Tim Isted on 22/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICoreDataSync.h"

@implementation TICDSFileManagerBasedDocumentSyncManager

#pragma mark -
#pragma mark Registration
- (void)registerWithDelegate:(id<TICDSDocumentSyncManagerDelegate>)aDelegate appSyncManager:(TICDSApplicationSyncManager *)anAppSyncManager managedObjectContext:(TICDSSynchronizedManagedObjectContext *)aContext documentIdentifier:(NSString *)aDocumentIdentifier description:(NSString *)aDocumentDescription userInfo:(NSDictionary *)someUserInfo
{
    if( [anAppSyncManager isKindOfClass:[TICDSFileManagerBasedApplicationSyncManager class]] ) {
        [self setApplicationDirectoryPath:[(TICDSFileManagerBasedApplicationSyncManager *)anAppSyncManager applicationDirectoryPath]];
    }
    
    [super registerWithDelegate:aDelegate appSyncManager:anAppSyncManager managedObjectContext:aContext documentIdentifier:aDocumentIdentifier description:aDocumentDescription userInfo:someUserInfo];
}

#pragma mark -
#pragma mark Operation Classes
- (TICDSDocumentRegistrationOperation *)documentRegistrationOperation
{
    TICDSFileManagerBasedDocumentRegistrationOperation *operation = [[TICDSFileManagerBasedDocumentRegistrationOperation alloc] initWithDelegate:self];
    
    [operation setDocumentsDirectoryPath:[self documentsDirectoryPath]];
    [operation setThisDocumentDirectoryPath:[self thisDocumentDirectoryPath]];
    [operation setThisDocumentSyncChangesThisClientDirectoryPath:[self thisDocumentSyncChangesThisClientDirectoryPath]];
    [operation setThisDocumentSyncCommandsThisClientDirectoryPath:[self thisDocumentSyncCommandsThisClientDirectoryPath]];
    
    return [operation autorelease];
}

- (TICDSWholeStoreUploadOperation *)wholeStoreUploadOperation
{
    TICDSFileManagerBasedWholeStoreUploadOperation *operation = [[TICDSFileManagerBasedWholeStoreUploadOperation alloc] initWithDelegate:self];
    
    [operation setThisDocumentWholeStoreThisClientDirectoryPath:[self thisDocumentWholeStoreThisClientDirectoryPath]];
    [operation setThisDocumentWholeStoreThisClientDirectoryWholeStoreFilePath:[self thisDocumentWholeStoreFilePath]];
    [operation setThisDocumentWholeStoreThisClientDirectoryAppliedSyncChangeSetsFilePath:[self thisDocumentAppliedSyncChangeSetsFilePath]];
    
    return [operation autorelease];
}

- (TICDSSynchronizationOperation *)synchronizationOperation
{
    TICDSFileManagerBasedSynchronizationOperation *operation = [[TICDSFileManagerBasedSynchronizationOperation alloc] initWithDelegate:self];
    
    [operation setThisDocumentSyncChangesDirectoryPath:[self thisDocumentSyncChangesDirectoryPath]];
    [operation setThisDocumentSyncChangesThisClientDirectoryPath:[self thisDocumentSyncChangesThisClientDirectoryPath]];
    [operation setThisDocumentRecentSyncsThisClientFilePath:[self thisDocumentRecentSyncsThisClientFilePath]];
    
    return [operation autorelease];
}

- (TICDSVacuumOperation *)vacuumOperation
{
    TICDSFileManagerBasedVacuumOperation *operation = [[TICDSFileManagerBasedVacuumOperation alloc] initWithDelegate:self];
    
    [operation setThisDocumentWholeStoreDirectoryPath:[self thisDocumentWholeStoreDirectoryPath]];
    [operation setThisDocumentRecentSyncsDirectoryPath:[self thisDocumentRecentSyncsDirectoryPath]];
    [operation setThisDocumentSyncChangesThisClientDirectoryPath:[self thisDocumentSyncChangesThisClientDirectoryPath]];
    
    return [operation autorelease];
}

#pragma mark -
#pragma mark Paths
- (NSString *)documentsDirectoryPath
{
    return [[self applicationDirectoryPath] stringByAppendingPathComponent:[self relativePathToDocumentsDirectory]];
}

- (NSString *)thisDocumentDirectoryPath
{
    return [[self applicationDirectoryPath] stringByAppendingPathComponent:[self relativePathToThisDocumentDirectory]];
}

- (NSString *)thisDocumentSyncChangesDirectoryPath
{
    return [[self applicationDirectoryPath] stringByAppendingPathComponent:[self relativePathToThisDocumentSyncChangesDirectory]];
}

- (NSString *)thisDocumentSyncChangesThisClientDirectoryPath
{
    return [[self applicationDirectoryPath] stringByAppendingPathComponent:[self relativePathToThisDocumentSyncChangesThisClientDirectory]];
}

- (NSString *)thisDocumentSyncCommandsDirectoryPath
{
    return [[self applicationDirectoryPath] stringByAppendingPathComponent:[self relativePathToThisDocumentSyncCommandsDirectory]];
}

- (NSString *)thisDocumentSyncCommandsThisClientDirectoryPath
{
    return [[self applicationDirectoryPath] stringByAppendingPathComponent:[self relativePathToThisDocumentSyncCommandsThisClientDirectory]];
}

- (NSString *)thisDocumentWholeStoreDirectoryPath
{
    return [[self applicationDirectoryPath] stringByAppendingPathComponent:[self relativePathToThisDocumentWholeStoreDirectory]];
}

- (NSString *)thisDocumentWholeStoreThisClientDirectoryPath
{
    return [[self applicationDirectoryPath] stringByAppendingPathComponent:[self relativePathToThisDocumentWholeStoreThisClientDirectory]];
}

- (NSString *)thisDocumentWholeStoreFilePath
{
    return [[self applicationDirectoryPath] stringByAppendingPathComponent:[self relativePathToThisDocumentWholeStoreThisClientDirectoryWholeStoreFile]];
}

- (NSString *)thisDocumentAppliedSyncChangeSetsFilePath
{
    return [[self applicationDirectoryPath] stringByAppendingPathComponent:[self relativePathToThisDocumentWholeStoreThisClientDirectoryAppliedSyncChangeSetsFile]];
}

- (NSString *)thisDocumentRecentSyncsDirectoryPath
{
    return [[self applicationDirectoryPath] stringByAppendingPathComponent:[self relativePathToThisDocumentRecentSyncsDirectory]];
}

- (NSString *)thisDocumentRecentSyncsThisClientFilePath
{
    return [[self applicationDirectoryPath] stringByAppendingPathComponent:[self relativePathToThisDocumentRecentSyncsDirectoryThisClientFile]];
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
