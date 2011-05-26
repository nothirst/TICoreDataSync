//
//  TICDSDropboxSDKBasedListOfApplicationRegisteredClientsOperation.m
//  iOSNotebook
//
//  Created by Tim Isted on 23/05/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#if TARGET_OS_IPHONE

#import "TICoreDataSync.h"


@implementation TICDSDropboxSDKBasedListOfApplicationRegisteredClientsOperation

- (BOOL)needsMainThread
{
    return YES;
}

- (void)fetchArrayOfClientUUIDStrings
{
    [[self restClient] loadMetadata:[self clientDevicesDirectoryPath]];
}

- (void)fetchDeviceInfoDictionaryForClientWithIdentifier:(NSString *)anIdentifier
{
    NSString *path = [[[self clientDevicesDirectoryPath] stringByAppendingPathComponent:anIdentifier] stringByAppendingPathComponent:TICDSDeviceInfoPlistFilenameWithExtension];
    
    [[self restClient] loadFile:path intoPath:[[self tempFileDirectoryPath] stringByAppendingPathComponent:anIdentifier]];
}

- (void)fetchArrayOfDocumentUUIDStrings
{
    [[self restClient] loadMetadata:[self documentsDirectoryPath]];
}

- (void)fetchArrayOfClientsRegisteredForDocumentWithIdentifier:(NSString *)anIdentifier
{
    NSString *path = [[[self documentsDirectoryPath] stringByAppendingPathComponent:anIdentifier] stringByAppendingPathComponent:TICDSSyncChangesDirectoryName];
    
    [[self restClient] loadMetadata:path];
}

#pragma mark -
#pragma mark Rest Client Delegate
#pragma mark Metadata
- (void)restClient:(DBRestClient*)client loadedMetadata:(DBMetadata*)metadata
{
    NSString *path = [metadata path];
    
    if( [path isEqualToString:[self clientDevicesDirectoryPath]] ) {
        NSMutableArray *clientIdentifiers = [NSMutableArray arrayWithCapacity:[[metadata contents] count]];
        
        for( DBMetadata *eachSubMetadata in [metadata contents] ) {
            if( ![eachSubMetadata isDirectory] || [eachSubMetadata isDeleted] ) {
                continue;
            }
            
            [clientIdentifiers addObject:[[eachSubMetadata path] lastPathComponent]];
        }
        
        [self fetchedArrayOfClientUUIDStrings:clientIdentifiers];
        
        return;
    }
    
    if( [path isEqualToString:[self documentsDirectoryPath]] ) {
        NSMutableArray *documentIdentifiers = [NSMutableArray arrayWithCapacity:[[metadata contents] count]];
        
        for( DBMetadata *eachSubMetadata in [metadata contents] ) {
            if( ![eachSubMetadata isDirectory] || [eachSubMetadata isDeleted] ) {
                continue;
            }
            
            [documentIdentifiers addObject:[[eachSubMetadata path] lastPathComponent]];
        }
        
        [self fetchedArrayOfDocumentUUIDStrings:documentIdentifiers];
        
        return;
    }
    
    if( [[path lastPathComponent] isEqualToString:TICDSSyncChangesDirectoryName] ) {
        NSMutableArray *clientIdentifiers = [NSMutableArray arrayWithCapacity:[[metadata contents] count]];
        
        for( DBMetadata *eachSubMetadata in [metadata contents] ) {
            if( ![eachSubMetadata isDirectory] || [eachSubMetadata isDeleted] ) {
                continue;
            }
            
            [clientIdentifiers addObject:[[eachSubMetadata path] lastPathComponent]];
        }
        
        [self fetchedArrayOfClients:clientIdentifiers registeredForDocumentWithIdentifier:[[path stringByDeletingLastPathComponent] lastPathComponent]];
        return;
    }
}

- (void)restClient:(DBRestClient*)client metadataUnchangedAtPath:(NSString*)path
{
    
}

- (void)restClient:(DBRestClient*)client loadMetadataFailedWithError:(NSError*)error
{
    NSString *path = [[error userInfo] valueForKey:@"path"];
    
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeDropboxSDKRestClientError underlyingError:error classAndMethod:__PRETTY_FUNCTION__]];
    
    if( [path isEqualToString:[self clientDevicesDirectoryPath]] ) {
        [self fetchedArrayOfClientUUIDStrings:nil ];
        return;
    }
    
    if( [path isEqualToString:[self documentsDirectoryPath]] ) {
        [self fetchedArrayOfDocumentUUIDStrings:nil];
        return;
    }
    
    if( [[path lastPathComponent] isEqualToString:TICDSSyncChangesDirectoryName] ) {
        [self fetchedArrayOfClients:nil registeredForDocumentWithIdentifier:[[path stringByDeletingLastPathComponent] lastPathComponent]];
        return;
    }
}

#pragma mark Loading Files
- (void)restClient:(DBRestClient*)client loadedFile:(NSString*)destPath
{
    NSError *anyError = nil;
    BOOL success = YES;
    
    // Only one file loaded by this operation...
    
    NSString *identifier = [destPath lastPathComponent];
    
    if( [self shouldUseEncryption] ) {
        NSString *tmpPath = [destPath stringByAppendingPathExtension:@"decrypt"];
        
        success = [[self cryptor] decryptFileAtLocation:[NSURL fileURLWithPath:destPath] writingToLocation:[NSURL fileURLWithPath:tmpPath] error:&anyError];
        
        if( !success ) {
            [self setError:[TICDSError errorWithCode:TICDSErrorCodeEncryptionError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
            [self fetchedDeviceInfoDictionary:nil forClientWithIdentifier:identifier];
            return;
        }
        
        destPath = tmpPath;
    }
    
    NSDictionary *dictionary = [NSDictionary dictionaryWithContentsOfFile:destPath];
    
    if( !dictionary ) {
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError classAndMethod:__PRETTY_FUNCTION__]];
    }
    
    [self fetchedDeviceInfoDictionary:dictionary forClientWithIdentifier:identifier];
}

- (void)restClient:(DBRestClient *)client loadFileFailedWithError:(NSError *)error
{
    NSString *path = [[error userInfo] valueForKey:@"path"];
    
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeDropboxSDKRestClientError underlyingError:error classAndMethod:__PRETTY_FUNCTION__]];
    
    [self fetchedDeviceInfoDictionary:nil forClientWithIdentifier:[path lastPathComponent]];
}

#pragma mark -
#pragma mark Initialization and Deallocation
- (void)dealloc
{
    [_dbSession release], _dbSession = nil;
    [_restClient release], _restClient = nil;
    [_clientDevicesDirectoryPath release], _clientDevicesDirectoryPath = nil;
    [_documentsDirectoryPath release], _documentsDirectoryPath = nil;

    [super dealloc];
}

#pragma mark -
#pragma mark Lazy Accessors
- (DBRestClient *)restClient
{
    if( _restClient ) return _restClient;
    
    _restClient = [[DBRestClient alloc] initWithSession:[self dbSession]];
    [_restClient setDelegate:self];
    
    return _restClient;
}

#pragma mark -
#pragma mark Properties
@synthesize dbSession = _dbSession;
@synthesize restClient = _restClient;
@synthesize clientDevicesDirectoryPath = _clientDevicesDirectoryPath;
@synthesize documentsDirectoryPath = _documentsDirectoryPath;

@end

#endif