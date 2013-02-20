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
    
    NSObject <TICDSOperationDelegate> *__weak _delegate;
    NSDictionary *_userInfo;
    
    BOOL _isExecuting;
    BOOL _isFinished;
    NSError *_error;
    
    NSFileManager *_fileManager;
    NSString *_tempFileDirectoryPath;
    
    NSString *_clientIdentifier;
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

/** @name Coordinated I/O */

/** Copy a file or directory using coordinated reads/writes. **/
- (BOOL)copyItemAtPath:(NSString *)fromPath toPath:(NSString *)toPath error:(NSError **)error;

/** Move a file or directory using coordinated reads/writes. **/
- (BOOL)moveItemAtPath:(NSString *)fromPath toPath:(NSString *)toPath error:(NSError **)error;

/** Remove a file or directory using coordinated reads/writes. **/
- (BOOL)removeItemAtPath:(NSString *)fromPath error:(NSError **)error;

/** Create directory using coordinated write **/
- (BOOL)createDirectoryAtPath:(NSString *)path withIntermediateDirectories:(BOOL)createIntermediates attributes:(NSDictionary *)attributes error:(NSError **)error;

/** Check for existence of file or directory using coordinated read **/
- (BOOL)fileExistsAtPath:(NSString *)path;

/** Get directory contents using coordinated read **/
- (NSArray *)contentsOfDirectoryAtPath:(NSString *)path error:(NSError **)error;

/** Get item attributes using coordinated read **/
- (NSDictionary *)attributesOfItemAtPath:(NSString *)path error:(NSError **)error;

/** Write data to file in coordinated way **/
-(BOOL)writeData:(NSData *)data toFile:(NSString *)path error:(NSError **)error;

/** Write object to file in coordinated way **/
-(BOOL)writeObject:(id)object toFile:(NSString *)path;

/** Read data in coordinated way **/
-(NSData *)dataWithContentsOfFile:(NSString *)file error:(NSError **)error;

/** Read data in a coordinated way **/
-(id)readObjectFromFile:(NSString *)path;

/** @name Properties */

/** Used to indicate whether the operation should encrypt files stored on the remote. */
@property (assign) BOOL shouldUseEncryption;

/** The `FZACryptor` object used to encrypt and decrypt files used by this operation, if `shouldUseEncryption` is `YES`. */
@property (nonatomic, strong) FZACryptor *cryptor;

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

@end
