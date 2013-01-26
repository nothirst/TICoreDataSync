//
//  TICDSDropboxSDKBasedRemoveAllRemoteSyncDataOperation.h
//  iOSNotebook
//
//  Created by Tim Isted on 05/08/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//


#import "TICDSRemoveAllRemoteSyncDataOperation.h"

#if TARGET_OS_IPHONE
#import <DropboxSDK/DropboxSDK.h>
#else
#import <DropboxSDK/DropboxOSX.h>
#endif

/**
 `TICDSDropboxSDKBasedApplicationRegistrationOperation` is an application registration operation designed for use with a `TICDSDropboxSDKBasedApplicationSyncManager`.
 */

@interface TICDSDropboxSDKBasedRemoveAllRemoteSyncDataOperation : TICDSRemoveAllRemoteSyncDataOperation <DBRestClientDelegate> {
@private
    DBRestClient *_restClient;
    NSString *_applicationDirectoryPath;
}

/** @name Properties */

/** The DropboxSDK `DBRestClient` for use by this operation. */
@property (nonatomic, readonly) DBRestClient *restClient;

/** @name Paths */

/** The path to the root of the application. */
@property (copy) NSString *applicationDirectoryPath;

@end

