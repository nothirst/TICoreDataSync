//
//  TICDSApplicationSyncManager.h
//  ShoppingListMac
//
//  Created by Tim Isted on 21/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICDSClassesAndProtocols.h"
#import "TICDSTypesAndEnums.h"

@interface TICDSApplicationSyncManager : NSObject {
@private
    TICDSApplicationSyncManagerState _state;
    
    id <TICDSApplicationSyncManagerDelegate> _delegate;
    NSString *_appIdentifier;
    NSString *_clientIdentifier;
    NSString *_clientDescription;
    NSDictionary *_userInfo;
    
    NSOperationQueue *_registrationQueue;
    NSOperationQueue *_otherTasksQueue;
}

/** Returns an application-wide Sync Manager */
+ (id)defaultApplicationSyncManager;

/** If you need to release the default manager, or need to use a different default manager for some reason: */
+ (void)setDefaultApplicationSyncManager:(TICDSApplicationSyncManager *)aSyncManager;

/** Register an application for future synchronization 
 Call this method before using the sync manager for any other purpose */
- (void)registerWithDelegate:(id <TICDSApplicationSyncManagerDelegate>)aDelegate globalAppIdentifier:(NSString *)anAppIdentifier uniqueClientIdentifier:(NSString *)aClientIdentifier description:(NSString *)aClientDescription userInfo:(NSDictionary *)someUserInfo;

#pragma mark -
#pragma mark Methods Overridden by Subclasses
- (TICDSApplicationRegistrationOperation *)applicationRegistrationOperation;

@property (nonatomic, assign) TICDSApplicationSyncManagerState state;
@property (nonatomic, assign) id <TICDSApplicationSyncManagerDelegate> delegate;
@property (nonatomic, readonly, retain) NSString *appIdentifier;
@property (nonatomic, readonly, retain) NSString *clientIdentifier;
@property (nonatomic, readonly, retain) NSString *clientDescription;
@property (nonatomic, readonly, retain) NSDictionary *userInfo;
@property (nonatomic, retain) NSOperationQueue *registrationQueue;
@property (nonatomic, retain) NSOperationQueue *otherTasksQueue;
@property (nonatomic, readonly) NSString *relativePathToClientDevicesDirectory;
@property (nonatomic, readonly) NSString *relativePathToDocumentsDirectory;
@property (nonatomic, readonly) NSString *relativePathToThisClientDeviceDirectory;

@end
