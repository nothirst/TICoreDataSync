//
//  TICDSFileManagerBasedWholeStoreDownloadOperation.m
//  ShoppingListMac
//
//  Created by Tim Isted on 26/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICoreDataSync.h"


@implementation TICDSFileManagerBasedWholeStoreDownloadOperation

- (void)checkForMostRecentClientWholeStore
{
    NSError *anyError = nil;
    NSArray *clientIdentifiers = [[self fileManager] contentsOfDirectoryAtPath:[self thisDocumentWholeStoreDirectoryPath] error:&anyError];
    
    if( !clientIdentifiers ) {
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
        [self determinedMostRecentWholeStoreWasUploadedByClientWithIdentifier:nil];
        return;
    }
    
    NSString *identifierToReturn = nil;
    NSDate *latestModificationDate = nil;
    NSDate *eachModificationDate = nil;
    NSDictionary *attributes = nil;
    for( NSString *eachIdentifier in clientIdentifiers ) {
        if( [[eachIdentifier substringToIndex:1] isEqualToString:@"1"] ) {
            continue;
        }
        
        attributes = [[self fileManager] attributesOfItemAtPath:[self pathToWholeStoreFileForClientWithIdentifier:eachIdentifier] error:&anyError];
        
        if( !attributes ) {
            continue;
        }
        
        eachModificationDate = [attributes valueForKey:NSFileModificationDate];
        
        if( !latestModificationDate ) {
            latestModificationDate = eachModificationDate;
            identifierToReturn = eachIdentifier;
            continue;
        } else if( [eachModificationDate compare:latestModificationDate] == NSOrderedDescending ) {
            latestModificationDate = eachModificationDate;
            identifierToReturn = eachIdentifier;
        }
    }
    
    if( !identifierToReturn && anyError ) {
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
        [self determinedMostRecentWholeStoreWasUploadedByClientWithIdentifier:nil];
        return;
    }
    
    if( !identifierToReturn ) {
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeNoPreviouslyUploadedStoreExists classAndMethod:__PRETTY_FUNCTION__]];
        [self determinedMostRecentWholeStoreWasUploadedByClientWithIdentifier:nil];
        return;
    }
    
    [self determinedMostRecentWholeStoreWasUploadedByClientWithIdentifier:identifierToReturn];
}

#pragma mark -
#pragma mark Paths
- (NSString *)pathToWholeStoreFileForClientWithIdentifier:(NSString *)anIdentifier
{
    return [[[self thisDocumentWholeStoreDirectoryPath] stringByAppendingPathComponent:anIdentifier] stringByAppendingPathComponent:TICDSWholeStoreFilename];
}

- (NSString *)pathToAppliedSyncChangesFileForClientWithIdentifier:(NSString *)anIdentifier
{
    return [[[self thisDocumentWholeStoreDirectoryPath] stringByAppendingPathComponent:anIdentifier] stringByAppendingPathComponent:TICDSAppliedSyncChangeSetsFilename];
}

#pragma mark -
#pragma mark Initialization and Deallocation
- (void)dealloc
{
    [_thisDocumentWholeStoreDirectoryPath release], _thisDocumentWholeStoreDirectoryPath = nil;
    
    [super dealloc];
}

#pragma mark -
#pragma mark Properties
@synthesize thisDocumentWholeStoreDirectoryPath = _thisDocumentWholeStoreDirectoryPath;

@end
