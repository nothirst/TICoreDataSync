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
    NSURL *_applicationContainingDirectoryLocation;
}

@property (nonatomic, retain) NSURL *applicationContainingDirectoryLocation;
@property (nonatomic, readonly) NSString *applicationDirectoryPath;
@property (nonatomic, readonly) NSString *documentsDirectoryPath;
@property (nonatomic, readonly) NSString *clientDevicesDirectoryPath;
@property (nonatomic, readonly) NSString *clientDevicesThisClientDeviceDirectoryPath;

@end
