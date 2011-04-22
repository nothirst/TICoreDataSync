//
//  TICDSFileManagerBasedApplicationSyncManager.h
//  ShoppingListMac
//
//  Created by Tim Isted on 22/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICDSApplicationSyncManager.h"


@interface TICDSFileManagerBasedApplicationSyncManager : TICDSApplicationSyncManager {
@private
    NSURL *_localApplicationContainingDirectoryLocation;
}

@property (nonatomic, retain) NSURL *localApplicationContainingDirectoryLocation;
@property (nonatomic, readonly) NSURL *localApplicationDirectoryLocation;
@property (nonatomic, readonly) NSURL *localDocumentsDirectoryLocation;
@property (nonatomic, readonly) NSURL *localClientDevicesDirectoryLocation;
@property (nonatomic, readonly) NSURL *localClientDevicesThisClientDeviceDirectoryLocation;

@end
