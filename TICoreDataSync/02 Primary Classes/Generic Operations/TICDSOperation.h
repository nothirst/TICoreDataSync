//
//  TICDSOperation.h
//  ShoppingListMac
//
//  Created by Tim Isted on 21/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICDSTypesAndEnums.h"
#import "TICDSClassesAndProtocols.h"

@interface TICDSOperation : NSOperation {
@private
    NSObject <TICDSOperationDelegate> *_delegate;
    
    BOOL _isExecuting;
    BOOL _isFinished;
    NSError *_error;
    
    NSFileManager *_fileManager;
    NSURL *_helperFileDirectoryLocation;
    
    NSString *_clientIdentifier;
}

- (id)initWithDelegate:(NSObject <TICDSOperationDelegate> *)aDelegate;

- (void)operationDidStart;
- (void)operationDidCompleteSuccessfully;
- (void)operationDidFailToComplete;
- (void)operationWasCancelled;

@property (nonatomic, assign) NSObject <TICDSOperationDelegate> *delegate;
@property (readonly) BOOL needsMainThread;
@property (readonly) BOOL isExecuting;
@property (readonly) BOOL isFinished;
@property (nonatomic, retain) NSError *error;
@property (nonatomic, retain) NSFileManager *fileManager;
@property (nonatomic, retain) NSURL *helperFileDirectoryLocation;
@property (nonatomic, copy) NSString *clientIdentifier;

@end
