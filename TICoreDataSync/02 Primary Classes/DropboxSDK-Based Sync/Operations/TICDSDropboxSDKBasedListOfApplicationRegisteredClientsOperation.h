//
//  TICDSDropboxSDKBasedListOfApplicationRegisteredClientsOperation.h
//  iOSNotebook
//
//  Created by Tim Isted on 23/05/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//


#import "TICDSListOfApplicationRegisteredClientsOperation.h"

#if TARGET_OS_IPHONE
#import <DropboxSDK/DropboxSDK.h>
#else
#import <DropboxSDK/DropboxOSX.h>
#endif

/**
 `TICDSDropboxSDKBasedListOfApplicationRegisteredClientsOperation` is a "List of Registered Clients for an Application" operation designed for use with a `TICDSDropboxSDKBasedDocumentSyncManager`.
 */
@interface TICDSDropboxSDKBasedListOfApplicationRegisteredClientsOperation : TICDSListOfApplicationRegisteredClientsOperation <DBRestClientDelegate> {
@private
    DBRestClient *_restClient;
    
    NSString *_clientDevicesDirectoryPath;
    NSString *_documentsDirectoryPath;
}

/** @name Properties */

/** The DropboxSDK `DBRestClient` for use by this operation. */
@property (nonatomic, readonly) DBRestClient *restClient;

/** @name Paths */

/** The path to the application's `ClientDevices` directory. */
@property (nonatomic, copy) NSString *clientDevicesDirectoryPath;

/** The path to the application's `Documents` directory. */
@property (nonatomic, copy) NSString *documentsDirectoryPath;

@end

