//
//  TICDSOperation.h
//  ShoppingListMac
//
//  Created by Tim Isted on 21/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICDSTypesAndEnums.h"
#import "TICDSClassesAndProtocols.h"

/**
 The `TICDSOperation` class provides the abstract behavior typical of any operation used by the `TICoreDataSync` framework.
 
 All `TICoreDataSync` operations are (in Apple terms) concurrent, which means that they return `YES` for `isConcurrent`. This means they may be used by classes using e.g. `NSURLConnection` or custom rest clients to fetch information in the background.
 
 Subclasses should make use of the operation phase methods listed below to update the values of `isExecuting` and `isFinished` so that operation queues can keep track of them. The `operationDidStart` method is called automatically when the operation begins to execute.
 
 Subclasses of `TICDSOperation` should override `needsMainThread` to return `YES` if they require their tasks to be implemented on the main thread.
 
 The `start` method automatically sets up the operation and notifies its `delegate` that it started. Subclasses should override `main` to do their work.
 
 @warning Subclasses must call one of the `operationDidCompleteSuccessfully`, `operationDidFailToComplete` or `operationWasCancelled` to update the delegate and set the necessary values such that the operation be removed from the operation queue.
 */

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

/** @name Designated Initializer */

/** Initialize the operation with a provided delegate.
 
 @param aDelegate The delegate object for the operation, notified when the operation starts, ends, fails, or is cancelled using methods defined in the `TICDSOperationDelegate` protocol.
 
 @return A properly-initialized operation.
 */
- (id)initWithDelegate:(NSObject <TICDSOperationDelegate> *)aDelegate;

/** @name Operation Phase Updates */

/** Notify the delegate when the operation starts, and set the necessary values for `isExecuting` and `isFinished`.
 
 @warning This method is called automatically by `TICDSOperation` when the opertion starts to execute, so you should not call it in a `TICDSOperation` subclass. */
- (void)operationDidStart;

/** Notify the delegate when the operation completes, and set the necessary values for `isExecuting` and `isFinished`. */
- (void)operationDidCompleteSuccessfully;

/** Notify the delegate if the operation has failed for some reason. Set the relevant `error` property before calling this method. This will set the required values for `isExecuting` and `isFinished`. */
- (void)operationDidFailToComplete;

/** Call this method if the operation is cancelled midway through its work. This will set the required values for `isExecuting` and `isFinished`. */
- (void)operationWasCancelled;

/** @name Properties */

/** The operation delegate. */
@property (nonatomic, assign) NSObject <TICDSOperationDelegate> *delegate;

/** By default returns `NO`, but override if your operation needs its code to execute on the main thread, such as for an `NSURLConnection`. */
@property (readonly) BOOL needsMainThread;

/** Indicates the operation is currently executing; this is set automatically through the operation phase methods. */
@property (readonly) BOOL isExecuting;

/** Indicates the operation has completed; this is set automatically through the operation phase methods. */
@property (readonly) BOOL isFinished;

/** The most recent error; set this before calling `operationDidFailToComplete`. */
@property (retain) NSError *error;

/** An `NSFileManager` object suitable for use by this operation. */
@property (nonatomic, readonly, retain) NSFileManager *fileManager;

/** The local location on disc of helper files needed by `TICoreDataSync` for this operation (not set automatically). */
@property (retain) NSURL *helperFileDirectoryLocation;

/** The identifier of the client application (not set automatically, but may be used whenever necessary by subclasses). */
@property (retain) NSString *clientIdentifier;

@end
