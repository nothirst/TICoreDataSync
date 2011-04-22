//
//  TICDSFileManagerBasedApplicationRegistrationOperation.h
//  ShoppingListMac
//
//  Created by Tim Isted on 22/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICDSApplicationRegistrationOperation.h"


@interface TICDSFileManagerBasedApplicationRegistrationOperation : TICDSApplicationRegistrationOperation {
@private
    NSURL *_localApplicationDirectoryLocation;
    NSURL *_localDocumentsDirectoryLocation;
    NSURL *_localClientDevicesDirectoryLocation;
    NSURL *_localClientDevicesThisClientDeviceDirectoryLocation;
}

@property (nonatomic, retain) NSURL *localApplicationDirectoryLocation;
@property (nonatomic, retain) NSURL *localDocumentsDirectoryLocation;
@property (nonatomic, retain) NSURL *localClientDevicesDirectoryLocation;
@property (nonatomic, retain) NSURL *localClientDevicesThisClientDeviceDirectoryLocation;

@end
