//
//  TICDSApplicationRegistrationOperation.h
//  ShoppingListMac
//
//  Created by Tim Isted on 21/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICDSOperation.h"

@interface TICDSApplicationRegistrationOperation : TICDSOperation {
@private
    NSString *_appIdentifier;
    NSString *_clientDescription;
    NSDictionary *_userInfo;
    
    BOOL _completionInProgress;
    TICDSOperationPhaseStatus _globalAppFileStructureStatus;
    TICDSOperationPhaseStatus _clientDeviceFileStructureStatus;
}

/** Methods called back by subclasses */
- (void)discoveredStatusOfRemoteGlobalAppFileStructure:(TICDSRemoteFileStructureExistsResponseType)status;
- (void)createdRemoteGlobalAppFileStructureSuccessfully:(BOOL)someSuccess;
- (void)discoveredStatusOfRemoteClientDeviceFileStructure:(TICDSRemoteFileStructureExistsResponseType)status;
- (void)createdRemoteClientDeviceFileStructureSuccessfully:(BOOL)someSuccess;

/** Methods overridden by subclasses */
- (void)checkWhetherRemoteGlobalAppFileStructureExists;
- (void)createRemoteGlobalAppFileStructure;
- (void)checkWhetherRemoteGlobalAppThisClientDeviceFileStructureExists;
- (void)createRemoteGlobalAppThisClientDeviceFileStructure;

@property (nonatomic, retain) NSString *appIdentifier;
@property (nonatomic, retain) NSString *clientDescription;
@property (nonatomic, retain) NSDictionary *userInfo;
@property (nonatomic, assign) BOOL completionInProgress;
@property (nonatomic, assign) TICDSOperationPhaseStatus globalAppFileStructureStatus;
@property (nonatomic, assign) TICDSOperationPhaseStatus clientDeviceFileStructureStatus;

@end
