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
    NSString *_applicationDirectoryPath;
    NSString *_documentsDirectoryPath;
    NSString *_clientDevicesDirectoryPath;
    NSString *_clientDevicesThisClientDeviceDirectoryPath;
}

@property (retain) NSString *applicationDirectoryPath;
@property (retain) NSString *documentsDirectoryPath;
@property (retain) NSString *clientDevicesDirectoryPath;
@property (retain) NSString *clientDevicesThisClientDeviceDirectoryPath;

@end
