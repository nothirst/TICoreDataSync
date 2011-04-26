//
//  TICDSFileManagerBasedApplicationRegistrationOperation.m
//  ShoppingListMac
//
//  Created by Tim Isted on 22/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICoreDataSync.h"

@implementation TICDSFileManagerBasedApplicationRegistrationOperation

#pragma mark -
#pragma mark Helper Methods
- (BOOL)createDirectoryContentsFromDictionary:(NSDictionary *)aDictionary inDirectory:(NSString *)aDirectoryPath
{
    NSError *anyError = nil;
    
    for( NSString *eachName in [aDictionary allKeys] ) {
        
        id object = [aDictionary valueForKey:eachName];
        
        if( eachName == kTICDSUtilitiesFileStructureClientDeviceUID ) {
            eachName = [self clientIdentifier];
        }
        
        if( [object isKindOfClass:[NSDictionary class]] ) {
            NSString *thisPath = [aDirectoryPath stringByAppendingPathComponent:eachName];
            
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
- (void)checkWhetherRemoteGlobalAppFileStructureExists
{
    if( ![[self fileManager] fileExistsAtPath:[self applicationDirectoryPath]] ) {
        // The directory does not exist at all
        [self discoveredStatusOfRemoteGlobalAppFileStructure:TICDSRemoteFileStructureExistsResponseTypeDoesNotExist];
        return;
    }
    
    NSError *anyError = nil;
    NSArray *contents = [[self fileManager] contentsOfDirectoryAtPath:[self applicationDirectoryPath] error:&anyError];
    
    if( !contents ) {
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
        [self discoveredStatusOfRemoteGlobalAppFileStructure:TICDSRemoteFileStructureExistsResponseTypeError];
        return;
    }
    
    if( [contents count] > 1 ) {
        [self discoveredStatusOfRemoteGlobalAppFileStructure:TICDSRemoteFileStructureExistsResponseTypeDoesExist];
        return;
    }
    
    // if we reach here, there's a problem with the structure...
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeUnexpectedOrIncompleteFileLocationOrDirectoryStructure classAndMethod:__PRETTY_FUNCTION__]];
    [self discoveredStatusOfRemoteGlobalAppFileStructure:TICDSRemoteFileStructureExistsResponseTypeError];
}

- (void)createRemoteGlobalAppFileStructure
{
    NSDictionary *fileStructure = [TICDSUtilities remoteGlobalAppFileStructure];
    
    NSError *anyError = nil;
    BOOL success = [self createDirectoryContentsFromDictionary:fileStructure inDirectory:[self applicationDirectoryPath]];
    
    // Create Read Me.txt
    if( success ) { 
        NSString *pathToResource = [[NSBundle mainBundle] pathForResource:@"ReadMe" ofType:@"txt" inDirectory:nil];
        NSString *pathToNewFile = [[self applicationDirectoryPath] stringByAppendingPathComponent:@"ReadMe.txt"];
        success = [[self fileManager] copyItemAtPath:pathToResource toPath:pathToNewFile error:&anyError];
    }
    
    if( !success ) {
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
    }
    
    [self createdRemoteGlobalAppFileStructureSuccessfully:success];
}

- (void)checkWhetherRemoteGlobalAppThisClientDeviceFileStructureExists
{
    if( ![[self fileManager] fileExistsAtPath:[self clientDevicesThisClientDeviceDirectoryPath]] ) {
        [self discoveredStatusOfRemoteClientDeviceFileStructure:TICDSRemoteFileStructureExistsResponseTypeDoesNotExist];
        return;
    }
    
    NSError *anyError = nil;
    NSArray *contents = [[self fileManager] contentsOfDirectoryAtPath:[self clientDevicesThisClientDeviceDirectoryPath] error:&anyError];
    
    if( !contents ) {
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
        [self discoveredStatusOfRemoteClientDeviceFileStructure:TICDSRemoteFileStructureExistsResponseTypeError];
        return;
    }
    
    if( [contents count] > 0 ) {
        [self discoveredStatusOfRemoteClientDeviceFileStructure:TICDSRemoteFileStructureExistsResponseTypeDoesExist];
        return;
    }
    
    // Currently won't get here until we make a better check that the entire directory structure exists
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
    
    [self discoveredStatusOfRemoteClientDeviceFileStructure:TICDSRemoteFileStructureExistsResponseTypeError];
}

- (void)createRemoteGlobalAppThisClientDeviceFileStructure
{
    NSDictionary *fileStructure = [TICDSUtilities remoteGlobalAppClientDeviceFileStructure];
    
    NSError *anyError = nil;
    BOOL success = [self createDirectoryContentsFromDictionary:fileStructure inDirectory:[self clientDevicesDirectoryPath]];
    
    // Create deviceInfo.plist
    if( success ) { 
        NSString *pathToResource = [[NSBundle mainBundle] pathForResource:@"deviceInfo" ofType:@"plist" inDirectory:nil];
        NSMutableDictionary *deviceInfo = [NSMutableDictionary dictionaryWithContentsOfFile:pathToResource];
        [deviceInfo setValue:[self clientDescription] forKey:kTICDSClientDeviceDescription];
        [deviceInfo setValue:[self applicationUserInfo] forKey:kTICDSClientDeviceUserInfo];
        
        NSString *pathToNewFile = [[self clientDevicesThisClientDeviceDirectoryPath] stringByAppendingPathComponent:@"deviceInfo.plist"];
        success = [deviceInfo writeToFile:pathToNewFile atomically:YES];
    }
    
    if( !success ) {
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
    }
    
    [self createdRemoteClientDeviceFileStructureSuccessfully:success];
}

#pragma mark -
#pragma mark Initialization and Deallocation
- (void)dealloc
{
    [_applicationDirectoryPath release], _applicationDirectoryPath = nil;
    [_documentsDirectoryPath release], _documentsDirectoryPath = nil;
    [_clientDevicesDirectoryPath release], _clientDevicesDirectoryPath = nil;
    [_clientDevicesThisClientDeviceDirectoryPath release], _clientDevicesThisClientDeviceDirectoryPath = nil;
    
    [super dealloc];
}

#pragma mark -
#pragma mark Properties
@synthesize applicationDirectoryPath = _applicationDirectoryPath;
@synthesize documentsDirectoryPath = _documentsDirectoryPath;
@synthesize clientDevicesDirectoryPath = _clientDevicesDirectoryPath;
@synthesize clientDevicesThisClientDeviceDirectoryPath = _clientDevicesThisClientDeviceDirectoryPath;

@end
