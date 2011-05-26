//
//  TICDSFileManagerBasedListOfApplicationRegisteredClientsOperation.h
//  Notebook
//
//  Created by Tim Isted on 23/05/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICDSListOfApplicationRegisteredClientsOperation.h"


@interface TICDSFileManagerBasedListOfApplicationRegisteredClientsOperation : TICDSListOfApplicationRegisteredClientsOperation {
@private
    NSString *_clientDevicesDirectoryPath;
    NSString *_documentsDirectoryPath;
}

@property (retain) NSString *clientDevicesDirectoryPath;
@property (retain) NSString *documentsDirectoryPath;

@end
