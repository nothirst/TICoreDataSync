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

- (void)fetchInfoDictionariesForDocumentsWithSyncIDs:(NSArray *)syncIDs
{
    NSError *anyError = nil;
    NSDictionary *dictionary = nil;
    
    for( NSString *eachSyncID in syncIDs ) {
        dictionary = [NSDictionary dictionaryWithContentsOfFile:[self pathToDocumentInfoForDocumentWithIdentifier:eachSyncID]];
        
        if( !dictionary ) {
            [self setError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
        }
        
        [self fetchedInfoDictionary:dictionary forDocumentWithSyncID:eachSyncID];
    }
}

#pragma mark -
#pragma mark Paths
- (NSString *)pathToDocumentInfoForDocumentWithIdentifier:(NSString *)anIdentifier
{
    return [[[self documentsDirectoryPath] stringByAppendingPathComponent:anIdentifier] stringByAppendingPathComponent:@"documentInfo.plist"];
}

#pragma mark -
#pragma mark Initialization and Deallocation
- (void)dealloc
{
    [_documentsDirectoryPath release], _documentsDirectoryPath = nil;

    [super dealloc];
}

#pragma mark -
#pragma mark Properties
@synthesize documentsDirectoryPath = _documentsDirectoryPath;

@end
