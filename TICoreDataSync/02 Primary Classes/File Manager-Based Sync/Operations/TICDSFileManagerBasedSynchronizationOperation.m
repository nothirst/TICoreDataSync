//
//  TICDSFileManagerBasedSynchronizationOperation.m
//  ShoppingListMac
//
//  Created by Tim Isted on 26/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICoreDataSync.h"


@implementation TICDSFileManagerBasedSynchronizationOperation

- (void)buildArrayOfClientDeviceIdentifiers
{
    NSError *anyError = nil;
    NSArray *directoryContents = [[self fileManager] contentsOfDirectoryAtPath:[self thisDocumentSyncChangesDirectoryPath] error:&anyError];
    
    if( !directoryContents ) {
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
        [self builtArrayOfClientDeviceIdentifiers:nil];
        return;
    }
    
    NSMutableArray *clientDeviceIdentifiers = [NSMutableArray arrayWithCapacity:[directoryContents count]];
    for( NSString *eachDirectory in directoryContents ) {
        if( [[eachDirectory substringToIndex:1] isEqualToString:@"."] ) {
            continue;
        }
        
        [clientDeviceIdentifiers addObject:eachDirectory];
    }
    
    [self builtArrayOfClientDeviceIdentifiers:clientDeviceIdentifiers];
}

#pragma mark -
#pragma mark Initialization and Deallocation
- (void)dealloc
{
    [_thisDocumentSyncChangesDirectoryPath release], _thisDocumentSyncChangesDirectoryPath = nil;

    [super dealloc];
}

#pragma mark -
#pragma mark Properties
@synthesize thisDocumentSyncChangesDirectoryPath = _thisDocumentSyncChangesDirectoryPath;

@end
