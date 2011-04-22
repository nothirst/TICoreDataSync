//
//  TICDSClassesAndProtocols.h
//  ShoppingListMac
//
//  Created by Tim Isted on 21/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#pragma mark -
#pragma mark PRIMARY CLASSES
@class TICDSApplicationSyncManager;

#pragma mark File Manager-Based
@class TICDSFileManagerBasedApplicationSyncManager;
@class TICDSFileManagerBasedApplicationRegistrationOperation;

#pragma mark Operations
@class TICDSOperation;
@class TICDSApplicationRegistrationOperation;

#pragma mark -
#pragma mark DELEGATE PROTOCOLS
#pragma mark Application Sync Manager
@protocol TICDSApplicationSyncManagerDelegate <NSObject>

@optional
// REGISTRATION PHASE
- (void)syncManagerDidStartRegistration:(TICDSApplicationSyncManager *)aSyncManager;
- (void)syncManager:(TICDSApplicationSyncManager *)aSyncManager encounteredRegistrationError:(NSError *)anError;
// end of registration
- (void)syncManagerFailedToRegister:(TICDSApplicationSyncManager *)aSyncManager;
- (void)syncManagerDidRegisterSuccessfully:(TICDSApplicationSyncManager *)aSyncManager;

@end

#pragma mark Operations
@protocol TICDSOperationDelegate <NSObject>

- (void)operationCompletedSuccessfully:(TICDSOperation *)anOperation;
- (void)operationWasCancelled:(TICDSOperation *)anOperation;
- (void)operationFailedToComplete:(TICDSOperation *)anOperation;

@end