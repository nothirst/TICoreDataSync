//
//  TICDSFileManagerBasedListOfPreviouslySynchronizedDocumentsOperation.m
//  ShoppingListMac
//
//  Created by Tim Isted on 24/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICoreDataSync.h"


@implementation TICDSFileManagerBasedListOfPreviouslySynchronizedDocumentsOperation

- (void)buildArrayOfDocumentIdentifiers
{
    NSError *anyError = nil;
    NSArray *contentsOfDirectory = [[self fileManager] contentsOfDirectoryAtPath:[self documentsDirectoryPath] error:&anyError];
    
    if( !contentsOfDirectory ) {
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
        [self builtArrayOfDocumentIdentifiers:nil];
        return;
    }
    
    NSMutableArray *contentsToReturn = [NSMutableArray arrayWithCapacity:[contentsOfDirectory count]];
    for( NSString *eachFile in contentsOfDirectory ) {
        if( [[eachFile substringToIndex:1] isEqualToString:@"."] ) {
            continue;
        }
        
        [contentsToReturn addObject:eachFile];
    }
    
    [self builtArrayOfDocumentIdentifiers:contentsToReturn];
}

- (void)fetchInfoDictionaryForDocumentWithSyncID:(NSString *)aSyncID
{
    NSError *anyError = nil;
    NSDictionary *dictionary = nil;
    NSString *filePath = [self pathToDocumentInfoForDocumentWithIdentifier:aSyncID];
    
    if( [self shouldUseEncryption] ) {
        NSString *tmpFilePath = [[self tempFileDirectoryPath] stringByAppendingPathComponent:[filePath lastPathComponent]];
        
        BOOL success = [[self cryptor] decryptFileAtLocation:[NSURL fileURLWithPath:filePath] writingToLocation:[NSURL fileURLWithPath:tmpFilePath] error:&anyError];
        
        if( !success ) {
            [self setError:[TICDSError errorWithCode:TICDSErrorCodeEncryptionError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
            [self fetchedInfoDictionary:nil forDocumentWithSyncID:aSyncID];
            return;
        }
        
        filePath = tmpFilePath;
    }
    
    dictionary = [NSDictionary dictionaryWithContentsOfFile:filePath];
        
    if( !dictionary ) {
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
    }
    
    [self fetchedInfoDictionary:dictionary forDocumentWithSyncID:aSyncID];
}

- (void)fetchLastSynchronizationDateForDocumentWithSyncID:(NSString *)aSyncID
{
    NSError *anyError = nil;
    NSDictionary *dictionary = [[self fileManager] attributesOfItemAtPath:[self pathToDocumentRecentSyncsDirectoryForIdentifier:aSyncID] error:&anyError];
    
    if( !dictionary ) {
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
        
    }
    
    [self fetchedLastSynchronizationDate:[dictionary valueForKey:NSFileModificationDate] forDocumentWithSyncID:aSyncID];
}

#pragma mark - Paths
- (NSString *)pathToDocumentInfoForDocumentWithIdentifier:(NSString *)anIdentifier
{
    return [[[self documentsDirectoryPath] stringByAppendingPathComponent:anIdentifier] stringByAppendingPathComponent:TICDSDocumentInfoPlistFilenameWithExtension];
}

- (NSString *)pathToDocumentRecentSyncsDirectoryForIdentifier:(NSString *)anIdentifier
{
    return [[[self documentsDirectoryPath] stringByAppendingPathComponent:anIdentifier] stringByAppendingPathComponent:TICDSRecentSyncsDirectoryName];
}

#pragma mark - Initialization and Deallocation
- (void)dealloc
{
    _documentsDirectoryPath = nil;

}

#pragma mark - Properties
@synthesize documentsDirectoryPath = _documentsDirectoryPath;

@end
