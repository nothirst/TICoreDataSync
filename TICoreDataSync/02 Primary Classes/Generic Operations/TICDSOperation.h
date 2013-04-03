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
 
 If an operation needs to create temporary files on disk during execution, it can call `tempFileDirectoryPath` to get access to a directory created specifically for the operation. This directory (and its contents) will automatically be removed from disk once the operation calls one of the completion methods.
 
 @warning Subclasses must call one of the `operationDidCompleteSuccessfully`, `operationDidFailToComplete` or `operationWasCancelled` to update the delegate and set the necessary values such that the operation be removed from the operation queue.
 */

@interface TICDSOperation : NSOperation {
@private
    BOOL _shouldUseEncryption;
    FZACryptor *_cryptor;
    
    BOOL _shouldUseCompressionForWholeStoreMoves;
    
    NSObject <TICDSOperationDelegate> *__weak _delegate;
    NSDictionary *_userInfo;
    
    BOOL _isExecuting;
    BOOL _isFinished;
    NSError *_error;
    
    NSFileManager *_fileManager;
    NSString *_tempFileDirectoryPath;
    
    NSString *_clientIdentifier;
    
    CGFloat _progress;

#if TARGET_OS_IPHONE
    UIBackgroundTaskIdentifier _backgroundTaskID;
#endif
    BOOL _shouldContinueProcessingInBackgroundState;
}

/** @name Designated Initializer */

/** Initialize the operation with a provided delegate, notified when the operation starts, ends, fails, or is cancelled using methods defined in the `TICDSOperationDelegate` protocol.
 
 @param aDelegate The delegate object for the operation.
 
 @return A properly-initialized operation.
 */
- (id)initWithDelegate:(NSObject <TICDSOperationDelegate> *)aDelegate;

/** @name Operation Phase Updates */

/** Notify the delegate when the operation starts, and set the necessary values for `isExecuting` and `isFinished`.
 
 @warning This method is called automatically by `TICDSOperation` when the operation starts to execute, so you should not call it from a `TICDSOperation` subclass. */
- (void)operationDidStart;

/** Notify the delegate when the operation completes, and set the necessary values for `isExecuting` and `isFinished`. */
- (void)operationDidCompleteSuccessfully;

/** Notify the delegate if the operation has failed for some reason. Set the relevant `error` property before calling this method. This will set the required values for `isExecuting` and `isFinished`. */
- (void)operationDidFailToComplete;

/** Call this method if the operation is cancelled midway through its work. This will set the required values for `isExecuting` and `isFinished`. */
- (void)operationWasCancelled;

/** Call this method if the operation wants to announce an update in the task progress. */
- (void)operationDidMakeProgress;

/** @name Properties */

/** Used to indicate whether the operation should encrypt files stored on the remote. */
@property (assign) BOOL shouldUseEncryption;

/** The `FZACryptor` object used to encrypt and decrypt files used by this operation, if `shouldUseEncryption` is `YES`. */
@property (nonatomic, strong) FZACryptor *cryptor;

/** Used to indicate whether the operation should use compression when moving the whole store. */
@property (assign) BOOL shouldUseCompressionForWholeStoreMoves;

/** The operation delegate. */
@property (nonatomic, weak) NSObject <TICDSOperationDelegate> *delegate;

/** A user info dictionary for sync managers to keep task-specific information. */
@property (strong) NSDictionary *userInfo;

/** By default returns `NO`, but override if your operation needs its code to execute on the main thread, such as for an `NSURLConnection`. */
@property (readonly) BOOL needsMainThread;

/** Indicates the operation is currently executing; this is set automatically through the operation phase methods. */
@property (readonly) BOOL isExecuting;

/** Indicates the operation has completed; this is set automatically through the operation phase methods. */
@property (readonly) BOOL isFinished;

/** The most recent error; set this before calling `operationDidFailToComplete`. */
@property (strong) NSError *error;

/** An `NSFileManager` object suitable for use by this operation. */
@property (nonatomic, readonly, strong) NSFileManager *fileManager;

/** The path to a directory inside `NSTemporaryDirectory()` guaranteed to be unique to this operation, created when path first requested and removed when operation finishes. */
@property (nonatomic, copy) NSString *tempFileDirectoryPath;

/** The identifier of the client application (not set automatically, but may be used whenever necessary by subclasses). */
@property (copy) NSString *clientIdentifier;

/** Used to report the completion progress of the operation (eg. during device to cloud file transfers). */
@property (nonatomic, assign) CGFloat progress;

#if TARGET_OS_IPHONE
/** Unique task identifier used when this operation must complete as a background operation */
@property (nonatomic, assign) UIBackgroundTaskIdentifier backgroundTaskID;
#endif

/** Indicates whether the operation should be setup to continue processing after the app has been moved from the Active to Background state */
@property (nonatomic, assign) BOOL shouldContinueProcessingInBackgroundState;

@end
