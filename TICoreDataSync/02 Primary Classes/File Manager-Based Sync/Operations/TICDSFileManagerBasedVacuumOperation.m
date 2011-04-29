//
//  TICDSFileManagerBasedVacuumOperation.m
//  ShoppingListMac
//
//  Created by Tim Isted on 29/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICoreDataSync.h"


@implementation TICDSFileManagerBasedVacuumOperation

- (void)findOutLeastRecentClientSyncDate
{
    NSError *anyError = nil;
    
    NSArray *fileNames = [[self fileManager] contentsOfDirectoryAtPath:[self thisDocumentRecentSyncsDirectoryPath] error:&anyError];
    
    if( !fileNames ) {
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
        [self foundOutLeastRecentClientSyncDate:nil];
        return;
    }
    
    if( [fileNames count] < 1 ) {
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeUnexpectedOrIncompleteFileLocationOrDirectoryStructure classAndMethod:__PRETTY_FUNCTION__]];
        [self foundOutLeastRecentClientSyncDate:nil];
        return;
    }
    
    NSString *filePath = nil;
    NSDate *oldestFileDate = nil;
    NSDictionary *attributes = nil;
    
    for( NSString *eachFileName in fileNames ) {
        filePath = [[self thisDocumentRecentSyncsDirectoryPath] stringByAppendingPathComponent:eachFileName];
        
        attributes = [[self fileManager] attributesOfItemAtPath:filePath error:&anyError];
        if( !attributes ) {
            [self setError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
            [self foundOutLeastRecentClientSyncDate:nil];
            return;
        }
        
        if( !oldestFileDate || [oldestFileDate compare:[attributes valueForKey:NSFileModificationDate]] == NSOrderedDescending ) {
            oldestFileDate = [attributes valueForKey:NSFileModificationDate];
        }
    }
    
    [self foundOutLeastRecentClientSyncDate:oldestFileDate];
}

- (void)removeOldSyncChangeSetFiles
{
    NSError *anyError = nil;
    
    NSArray *fileNames = [[self fileManager] contentsOfDirectoryAtPath:[self thisDocumentSyncChangesThisClientDirectoryPath] error:&anyError];
    
    if( !fileNames ) {
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
        [self removedOldSyncChangeSetFilesWithSuccess:NO];
        return;
    }
    
    NSString *filePath = nil;
    NSDictionary *attributes = nil;
    BOOL success = YES;
    
    for( NSString *eachFileName in fileNames ) {
        filePath = [[self thisDocumentSyncChangesThisClientDirectoryPath] stringByAppendingPathComponent:eachFileName];
        
        attributes = [[self fileManager] attributesOfItemAtPath:filePath error:&anyError];
        if( !attributes ) {
            success = NO;
            break;
        }
        
        if( [(NSDate *)[attributes valueForKey:NSFileModificationDate] compare:[self leastRecentClientSyncDate]] ) {
            success = [[self fileManager] removeItemAtPath:filePath error:&anyError];
        }
    }
    
    if( !success ) {
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
    }
    
    [self removedOldSyncChangeSetFilesWithSuccess:success];
}

#pragma mark -
#pragma mark Initialization and Deallocation
- (void)dealloc
{
    [_thisDocumentSyncChangesThisClientDirectoryPath release], _thisDocumentSyncChangesThisClientDirectoryPath = nil;
    [_thisDocumentRecentSyncsDirectoryPath release], _thisDocumentRecentSyncsDirectoryPath = nil;

    [super dealloc];
}

#pragma mark -
#pragma mark Properties
@synthesize thisDocumentRecentSyncsDirectoryPath = _thisDocumentRecentSyncsDirectoryPath;
@synthesize thisDocumentSyncChangesThisClientDirectoryPath = _thisDocumentSyncChangesThisClientDirectoryPath;

@end
