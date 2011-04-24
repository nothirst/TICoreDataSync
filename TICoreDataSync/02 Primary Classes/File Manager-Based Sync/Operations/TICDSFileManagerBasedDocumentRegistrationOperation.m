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
        
        if( eachName == kTICDSUtilitiesFileStructureDocumentUID ) {
            eachName = [self documentIdentifier];
        }
        
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
#pragma mark Overridden Methods
#pragma mark Document File Structure
- (void)checkWhetherRemoteDocumentFileStructureExists
{
    if( ![[self fileManager] fileExistsAtPath:[self thisDocumentDirectoryPath]] ) {
        [self discoveredStatusOfRemoteDocumentFileStructure:TICDSRemoteFileStructureExistsResponseTypeDoesNotExist];
        return;
    }
    
    NSError *anyError = nil;
    NSArray *contents = [[self fileManager] contentsOfDirectoryAtPath:[self thisDocumentDirectoryPath] error:&anyError];
    
    if( !contents ) {
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
        [self discoveredStatusOfRemoteDocumentFileStructure:TICDSRemoteFileStructureExistsResponseTypeError];
        return;
    }
    
    if( [contents count] > 1 ) {
        [self discoveredStatusOfRemoteDocumentFileStructure:TICDSRemoteFileStructureExistsResponseTypeDoesExist];
        return;
    }
    
    // Currently won't get here until we make a better check that the entire directory structure exists
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeUnexpectedOrIncompleteDirectoryStructure classAndMethod:__PRETTY_FUNCTION__]];
    
    [self discoveredStatusOfRemoteDocumentFileStructure:TICDSRemoteFileStructureExistsResponseTypeError];
}

- (void)createRemoteDocumentFileStructure
{
    NSDictionary *fileStructure = [TICDSUtilities remoteDocumentFileStructure];
    
    BOOL success = [self createDirectoryContentsFromDictionary:fileStructure inDirectory:[self documentsDirectoryPath]];
    
    // Create documentInfo.plist
    if( success ) { 
        NSString *pathToResource = [[NSBundle mainBundle] pathForResource:@"documentInfo" ofType:@"plist" inDirectory:nil];
        NSMutableDictionary *documentInfo = [NSMutableDictionary dictionaryWithContentsOfFile:pathToResource];
        [documentInfo setValue:[self documentDescription] forKey:kTICDSDocumentDescription];
        [documentInfo setValue:[self clientDescription] forKey:kTICDSOriginalDeviceDescription];
        [documentInfo setValue:[self clientIdentifier] forKey:kTICDSOriginalDeviceIdentifier];
        [documentInfo setValue:[self userInfo] forKey:kTICDSDocumentUserInfo];
        
        NSURL *fileLocation = [NSURL fileURLWithPath:[[self thisDocumentDirectoryPath] stringByAppendingPathComponent:@"documentInfo.plist"]];
        success = [documentInfo writeToURL:fileLocation atomically:YES];
    }
    
    [self createdRemoteDocumentFileStructureWithSuccess:success];
}

#pragma mark Document Client Device
- (void)checkWhetherRemoteDocumentSyncChangesThisClientFileStructureExists
{
    if( ![[self fileManager] fileExistsAtPath:[self thisDocumentSyncChangesThisClientDirectoryPath]] ) {
        [self discoveredStatusOfRemoteDocumentSyncChangesThisClientFileStructure:TICDSRemoteFileStructureExistsResponseTypeDoesNotExist];
        return;
    }
    
    NSError *anyError = nil;
    NSArray *contents = [[self fileManager] contentsOfDirectoryAtPath:[self thisDocumentSyncChangesThisClientDirectoryPath] error:&anyError];
    
    if( !contents ) {
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
        [self discoveredStatusOfRemoteDocumentSyncChangesThisClientFileStructure:TICDSRemoteFileStructureExistsResponseTypeError];
        return;
    } else { // there may not be any contents, but as long as the array is !nil, the directory exists
        [self discoveredStatusOfRemoteDocumentSyncChangesThisClientFileStructure:TICDSRemoteFileStructureExistsResponseTypeDoesExist];
        return;
    }
    
    // Currently won't get here until we make a better check that the entire directory structure exists
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeUnexpectedOrIncompleteDirectoryStructure classAndMethod:__PRETTY_FUNCTION__]];
    
    [self discoveredStatusOfRemoteDocumentSyncChangesThisClientFileStructure:TICDSRemoteFileStructureExistsResponseTypeError];
}

- (void)createRemoteDocumentSyncChangesThisClientFileStructure
{
    // Just create a directory with this client's UID in the doc's SyncChanges directory
    NSString *pathToDirectory = [self thisDocumentSyncChangesThisClientDirectoryPath];
    
    NSError *anyError = nil;
    BOOL success = [[self fileManager] createDirectoryAtPath:pathToDirectory withIntermediateDirectories:YES attributes:nil error:&anyError];
    
    if( !success ) {
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
    }
    
    [self createdRemoteDocumentSyncChangesThisClientFileStructureWithSuccess:success];
}

#pragma mark -
#pragma mark Initialization and Deallocation
- (void)dealloc
{
    [_documentsDirectoryPath release], _documentsDirectoryPath = nil;
    [_thisDocumentDirectoryPath release], _thisDocumentDirectoryPath = nil;
    [_thisDocumentSyncChangesThisClientDirectoryPath release], _thisDocumentSyncChangesThisClientDirectoryPath = nil;
    
    [super dealloc];
}

#pragma mark -
#pragma mark Properties
@synthesize documentsDirectoryPath = _documentsDirectoryPath;
@synthesize thisDocumentDirectoryPath = _thisDocumentDirectoryPath;
@synthesize thisDocumentSyncChangesThisClientDirectoryPath = _thisDocumentSyncChangesThisClientDirectoryPath;

@end
