//
//  TICDSDocumentRegistrationOperation.h
//  ShoppingListMac
//
//  Created by Tim Isted on 22/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICDSOperation.h"


@interface TICDSDocumentRegistrationOperation : TICDSOperation {
@private
    BOOL _paused;
    BOOL _shouldCreateDocumentFileStructure;
    
    NSString *_documentIdentifier;
    NSString *_documentDescription;
    NSString *_clientDescription;
    NSDictionary *_userInfo;
    
    BOOL _documentHasBeenSynchronizedByAnyClient;
    BOOL _documentHasBeenSynchronizedByThisClient;
    
    BOOL _completionInProgress;
    TICDSOperationPhaseStatus _documentFileStructureStatus;
    TICDSOperationPhaseStatus _documentClientDeviceFileStructureStatus;
}

/** Overridden Methods */
- (void)checkWhetherRemoteDocumentFileStructureExists;
- (void)createRemoteDocumentFileStructure;
- (void)checkWhetherRemoteDocumentSyncChangesThisClientFileStructureExists;
- (void)createRemoteDocumentSyncChangesThisClientFileStructure;

/** Callbacks */
- (void)discoveredStatusOfRemoteDocumentFileStructure:(TICDSRemoteFileStructureExistsResponseType)status;
- (void)createdRemoteDocumentFileStructureWithSuccess:(BOOL)success;
- (void)discoveredStatusOfRemoteDocumentSyncChangesThisClientFileStructure:(TICDSRemoteFileStructureExistsResponseType)status;
- (void)createdRemoteDocumentSyncChangesThisClientFileStructureWithSuccess:(BOOL)success;

@property (assign, getter = isPaused) BOOL paused;
@property (assign) BOOL shouldCreateDocumentFileStructure;
@property (retain) NSString *documentIdentifier;
@property (retain) NSString *documentDescription;
@property (retain) NSString *clientDescription;
@property (retain) NSDictionary *userInfo;
@property (assign) BOOL documentHasBeenSynchronizedByAnyClient;
@property (assign) BOOL documentHasBeenSynchronizedByThisClient;
@property (nonatomic, assign) BOOL completionInProgress;
@property (nonatomic, assign) TICDSOperationPhaseStatus documentFileStructureStatus;
@property (nonatomic, assign) TICDSOperationPhaseStatus documentClientDeviceFileStructureStatus;

@end
