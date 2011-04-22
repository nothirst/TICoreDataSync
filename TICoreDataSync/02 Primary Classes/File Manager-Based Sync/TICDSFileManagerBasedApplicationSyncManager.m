//
//  TICDSFileManagerBasedApplicationSyncManager.m
//  ShoppingListMac
//
//  Created by Tim Isted on 22/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICDSFileManagerBasedApplicationSyncManager.h"
#import "TICoreDataSync.h"

@implementation TICDSFileManagerBasedApplicationSyncManager

#pragma mark -
#pragma mark Overridden Methods
- (TICDSApplicationRegistrationOperation *)applicationRegistrationOperation
{
    TICDSFileManagerBasedApplicationRegistrationOperation *operation = [[TICDSFileManagerBasedApplicationRegistrationOperation alloc] initWithDelegate:self];
    
    [operation setLocalApplicationDirectoryLocation:[self localApplicationDirectoryLocation]];
    [operation setLocalClientDevicesDirectoryLocation:[self localClientDevicesDirectoryLocation]];
    [operation setLocalDocumentsDirectoryLocation:[self localDocumentsDirectoryLocation]];
    [operation setLocalClientDevicesThisClientDeviceDirectoryLocation:[self localClientDevicesThisClientDeviceDirectoryLocation]];
    
    return [operation autorelease];
}

#pragma mark -
#pragma mark Initialization and Deallocation
- (void)dealloc
{
    [_localApplicationContainingDirectoryLocation release], _localApplicationContainingDirectoryLocation = nil;

    [super dealloc];
}

#pragma mark -
#pragma mark Properties
@synthesize localApplicationContainingDirectoryLocation = _localApplicationContainingDirectoryLocation;

- (NSURL *)localApplicationDirectoryLocation
{
    return [NSURL fileURLWithPath:[[[self localApplicationContainingDirectoryLocation] path] stringByAppendingPathComponent:[self appIdentifier]]];
}

- (NSURL *)localDocumentsDirectoryLocation
{
    return [NSURL fileURLWithPath:[[[self localApplicationDirectoryLocation] path] stringByAppendingPathComponent:[self relativePathToDocumentsDirectory]]];
}

- (NSURL *)localClientDevicesDirectoryLocation
{
    return [NSURL fileURLWithPath:[[[self localApplicationDirectoryLocation] path] stringByAppendingPathComponent:[self relativePathToClientDevicesDirectory]]];
}

- (NSURL *)localClientDevicesThisClientDeviceDirectoryLocation
{
    return [NSURL fileURLWithPath:[[[self localApplicationDirectoryLocation] path] stringByAppendingPathComponent:[self relativePathToThisClientDeviceDirectory]]];
}

@end
