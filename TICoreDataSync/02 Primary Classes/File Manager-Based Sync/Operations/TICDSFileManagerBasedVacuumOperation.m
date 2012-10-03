//
//  TICDSFileManagerBasedVacuumOperation.m
//  ShoppingListMac
//
//  Created by Tim Isted on 29/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICoreDataSync.h"


@implementation TICDSFileManagerBasedVacuumOperation

- (void)findOutDateOfOldestWholeStore
{
    NSError *anyError = nil;
    NSArray *clientIdentifiers = [[self fileManager] contentsOfDirectoryAtPath:[self thisDocumentWholeStoreDirectoryPath] error:&anyError];
    
    if( !clientIdentifiers ) {
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
        [self foundOutDateOfOldestWholeStoreFile:nil];
        return;
    }
    
    NSDate *latestModificationDate = nil;
    NSDate *eachModificationDate = nil;
    NSDictionary *attributes = nil;
    for( NSString *eachIdentifier in clientIdentifiers ) {
        if( [[eachIdentifier substringToIndex:1] isEqualToString:@"."] ) {
            continue;
        }
        
        attributes = [[self fileManager] attributesOfItemAtPath:[self pathToWholeStoreFileForClientWithIdentifier:eachIdentifier] error:&anyError];
        
        if( !attributes ) {
            continue;
        }
        
        eachModificationDate = [attributes valueForKey:NSFileModificationDate];
        
        if( !latestModificationDate ) {
            latestModificationDate = eachModificationDate;
            continue;
        } else if( [eachModificationDate compare:latestModificationDate] == NSOrderedAscending ) {
            latestModificationDate = eachModificationDate;
        }
    }
    
    if( !latestModificationDate && anyError ) {
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
        [self foundOutDateOfOldestWholeStoreFile:nil];
        return;
    }
    
    if( !latestModificationDate ) {
        latestModificationDate = [NSDate date];
    }
    
    [self foundOutDateOfOldestWholeStoreFile:latestModificationDate];
}

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
        [self foundOutLeastRecentClientSyncDate:[NSDate date]];
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
        
        if( [(NSDate *)[attributes valueForKey:NSFileModificationDate] compare:[self earliestDateForFilesToKeep]] == NSOrderedAscending ) {
            success = [[self fileManager] removeItemAtPath:filePath error:&anyError];
        }
        
        if( !success ) {
            break;
        }
    }
    
    if( !success ) {
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
    }
    
    [self removedOldSyncChangeSetFilesWithSuccess:success];
}

#pragma mark - Paths
- (NSString *)pathToWholeStoreFileForClientWithIdentifier:(NSString *)anIdentifier
{
    return [[[self thisDocumentWholeStoreDirectoryPath] stringByAppendingPathComponent:anIdentifier] stringByAppendingPathComponent:TICDSWholeStoreFilename];
}

#pragma mark - Initialization and Deallocation
- (void)dealloc
{
    _thisDocumentWholeStoreDirectoryPath = nil;
    _thisDocumentSyncChangesThisClientDirectoryPath = nil;
    _thisDocumentRecentSyncsDirectoryPath = nil;

}

#pragma mark - Properties
@synthesize thisDocumentWholeStoreDirectoryPath = _thisDocumentWholeStoreDirectoryPath;
@synthesize thisDocumentRecentSyncsDirectoryPath = _thisDocumentRecentSyncsDirectoryPath;
@synthesize thisDocumentSyncChangesThisClientDirectoryPath = _thisDocumentSyncChangesThisClientDirectoryPath;

@end
