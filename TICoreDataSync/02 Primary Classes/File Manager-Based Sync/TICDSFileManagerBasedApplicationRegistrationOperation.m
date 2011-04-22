//
//  TICDSFileManagerBasedApplicationRegistrationOperation.m
//  ShoppingListMac
//
//  Created by Tim Isted on 22/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICDSFileManagerBasedApplicationRegistrationOperation.h"
#import "TICoreDataSync.h"

@implementation TICDSFileManagerBasedApplicationRegistrationOperation

#pragma mark -
#pragma mark Helper Methods
- (BOOL)createDirectoryContentsFromDictionary:(NSDictionary *)aDictionary inDirectory:(NSURL *)aDirectoryLocation
{
    NSError *anyError = nil;
    
    for( NSString *eachName in [aDictionary allKeys] ) {
        
        id object = [aDictionary valueForKey:eachName];
        
        if( eachName == kTICDSUtilitiesFileStructureClientDeviceUID ) {
            eachName = [self clientIdentifier];
        }
        
        if( [object isKindOfClass:[NSDictionary class]] ) {
            NSURL *thisPath = [NSURL fileURLWithPath:[[aDirectoryLocation path] stringByAppendingPathComponent:eachName]];
            
            // create directory
            BOOL success = [[self fileManager] createDirectoryAtPath:[thisPath path] withIntermediateDirectories:YES attributes:nil error:&anyError];
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
    if( ![[self fileManager] fileExistsAtPath:[[self localApplicationDirectoryLocation] path]] ) {
        // The directory does not exist at all
        [self discoveredStatusOfRemoteGlobalAppFileStructure:TICDSRemoteFileStructureExistsResponseTypeDoesNotExist];
        return;
    }
    
    NSError *anyError = nil;
    NSArray *contents = [[self fileManager] contentsOfDirectoryAtPath:[[self localApplicationDirectoryLocation] path] error:&anyError];
    
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
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeUnexpectedOrIncompleteDirectoryStructure classAndMethod:__PRETTY_FUNCTION__]];
    [self discoveredStatusOfRemoteGlobalAppFileStructure:TICDSRemoteFileStructureExistsResponseTypeError];
}

- (void)createRemoteGlobalAppFileStructure
{
    NSDictionary *fileStructure = [TICDSUtilities remoteGlobalAppFileStructure];
    
    NSError *anyError = nil;
    BOOL success = [self createDirectoryContentsFromDictionary:fileStructure inDirectory:[self localApplicationDirectoryLocation]];
    
    // Create Read Me.txt
    if( success ) { 
        NSString *pathToResource = [[NSBundle mainBundle] pathForResource:@"ReadMe" ofType:@"txt" inDirectory:nil];
        NSString *pathToNewFile = [[[self localApplicationDirectoryLocation] path] stringByAppendingPathComponent:@"ReadMe.txt"];
        success = [[self fileManager] copyItemAtPath:pathToResource toPath:pathToNewFile error:&anyError];
    }
    
    if( !success ) {
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
    }
    
    [self createdRemoteGlobalAppFileStructureSuccessfully:success];
}

- (void)checkWhetherRemoteClientDeviceFileStructureExists
{
    if( ![[self fileManager] fileExistsAtPath:[[self localClientDevicesThisClientDeviceDirectoryLocation] path]] ) {
        [self discoveredStatusOfRemoteClientDeviceFileStructure:TICDSRemoteFileStructureExistsResponseTypeDoesNotExist];
        return;
    }
    
    NSError *anyError = nil;
    NSArray *contents = [[self fileManager] contentsOfDirectoryAtPath:[[self localClientDevicesThisClientDeviceDirectoryLocation] path] error:&anyError];
    
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

- (void)createRemoteClientDeviceFileStructure
{
    NSDictionary *fileStructure = [TICDSUtilities remoteClientDeviceFileStructure];
    
    NSError *anyError = nil;
    BOOL success = [self createDirectoryContentsFromDictionary:fileStructure inDirectory:[self localClientDevicesDirectoryLocation]];
    
    // Create deviceInfo.plist
    if( success ) { 
        NSString *pathToResource = [[NSBundle mainBundle] pathForResource:@"deviceInfo" ofType:@"plist" inDirectory:nil];
        NSMutableDictionary *deviceInfo = [NSMutableDictionary dictionaryWithContentsOfFile:pathToResource];
        [deviceInfo setValue:[self clientDescription] forKey:kTICDSClientDeviceDescription];
        [deviceInfo setValue:[self userInfo] forKey:kTICDSClientDeviceUserInfo];
        
        NSString *pathToNewFile = [[[self localClientDevicesThisClientDeviceDirectoryLocation] path] stringByAppendingPathComponent:@"deviceInfo.plist"];
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
    [_localApplicationDirectoryLocation release], _localApplicationDirectoryLocation = nil;
    [_localDocumentsDirectoryLocation release], _localDocumentsDirectoryLocation = nil;
    [_localClientDevicesDirectoryLocation release], _localClientDevicesDirectoryLocation = nil;
    [_localClientDevicesThisClientDeviceDirectoryLocation release], _localClientDevicesThisClientDeviceDirectoryLocation = nil;
    
    [super dealloc];
}

#pragma mark -
#pragma mark Properties
@synthesize localApplicationDirectoryLocation = _localApplicationDirectoryLocation;
@synthesize localDocumentsDirectoryLocation = _localDocumentsDirectoryLocation;
@synthesize localClientDevicesDirectoryLocation = _localClientDevicesDirectoryLocation;
@synthesize localClientDevicesThisClientDeviceDirectoryLocation = _localClientDevicesThisClientDeviceDirectoryLocation;

@end
