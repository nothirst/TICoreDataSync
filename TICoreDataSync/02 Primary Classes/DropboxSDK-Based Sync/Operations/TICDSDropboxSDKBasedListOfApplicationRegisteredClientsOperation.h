//
//  TICDSDropboxSDKBasedListOfApplicationRegisteredClientsOperation.h
//  iOSNotebook
//
//  Created by Tim Isted on 23/05/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#if TARGET_OS_IPHONE

#import "TICDSListOfApplicationRegisteredClientsOperation.h"
#import "DropboxSDK.h"

/**
 `TICDSDropboxSDKBasedListOfApplicationRegisteredClientsOperation` is a "List of Registered Clients for an Application" operation designed for use with a `TICDSDropboxSDKBasedDocumentSyncManager`.
 */
@interface TICDSDropboxSDKBasedListOfApplicationRegisteredClientsOperation : TICDSListOfApplicationRegisteredClientsOperation <DBRestClientDelegate> {
@private
    DBSession *_dbSession;
    DBRestClient *_restClient;
    
    NSString *_clientDevicesDirectoryPath;
    NSString *_documentsDirectoryPath;
}

/** @name Properties */

/** The DropboxSDK `DBSession` for use by this operation's `DBRestClient`. */
@property (retain) DBSession *dbSession;

/** The DropboxSDK `DBRestClient` for use by this operation for methods relating to the global application directory. */
@property (nonatomic, retain) DBRestClient *restClient;

@property (nonatomic, retain) NSString *clientDevicesDirectoryPath;
@property (nonatomic, retain) NSString *documentsDirectoryPath;

@end

#endif