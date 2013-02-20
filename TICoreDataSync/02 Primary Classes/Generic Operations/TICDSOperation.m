//
//  TICDSOperation.m
//  ShoppingListMac
//
//  Created by Tim Isted on 21/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICoreDataSync.h"


@implementation TICDSOperation

#pragma mark - Primary Operation
- (void)start
{
    if( [self needsMainThread] && ![NSThread isMainThread])
    {
        [self performSelectorOnMainThread:@selector(start) withObject:nil waitUntilDone:NO];
        return;
    } else if( ![self needsMainThread] && [NSThread isMainThread] ) {
        [self performSelectorInBackground:@selector(start) withObject:nil];
        return;
    }
    
    // Configure the Cryptor object, if encryption is enabled
    if( [self shouldUseEncryption] ) {
        FZACryptor *aCryptor = [[FZACryptor alloc] init];
        [self setCryptor:aCryptor];
    }

    [self operationDidStart];
    
    if( [self isCancelled] ) {
        [self operationWasCancelled];
        return;
    }
    
    [self main];
}

- (void)main
{
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeMethodNotOverriddenBySubclass classAndMethod:__PRETTY_FUNCTION__]];
    
    [self operationDidFailToComplete];
}

#pragma mark - Operation Settings
- (BOOL)isConcurrent
{
    return YES;
}

- (BOOL)needsMainThread
{
    return NO;
}

#pragma mark - Completion
- (void)endExecution
{
    [self willChangeValueForKey:@"isExecuting"];
    [self willChangeValueForKey:@"isFinished"];
    
    _isExecuting = NO;
    _isFinished = YES;
    
    [self didChangeValueForKey:@"isExecuting"];
    [self didChangeValueForKey:@"isFinished"];
}

- (void)ticdPrivate_operationDidCompleteSuccessfully:(BOOL)success cancelled:(BOOL)wasCancelled
{
    // cleanup temporary directory, if necessary
    if( _tempFileDirectoryPath ) {
        [self removeItemAtPath:_tempFileDirectoryPath error:NULL];
    }
    
    if( success ) {
        TICDSLog(TICDSLogVerbosityStartAndEndOfMainOperationPhase, @"TICDSOperation completed successfully");
        if ([self ti_delegateRespondsToSelector:@selector(operationCompletedSuccessfully:)]) {
            [self runOnMainQueueWithoutDeadlocking:^{
                [(id)self.delegate operationCompletedSuccessfully:self];
            }];
        }
    } else if( wasCancelled ) {
        TICDSLog(TICDSLogVerbosityStartAndEndOfMainOperationPhase, @"TICDSOperation was cancelled");
        if ([self ti_delegateRespondsToSelector:@selector(operationWasCancelled:)]) {
            [self runOnMainQueueWithoutDeadlocking:^{
                [(id)self.delegate operationWasCancelled:self];
            }];
        }
    } else {
        TICDSLog(TICDSLogVerbosityStartAndEndOfMainOperationPhase, @"TICDSOperation failed to complete");
        if ([self ti_delegateRespondsToSelector:@selector(operationFailedToComplete:)]) {
            [self runOnMainQueueWithoutDeadlocking:^{
                [(id)self.delegate operationFailedToComplete:self];
            }];
        }
    }
    
    // This is a nasty way to, I think, avoid a problem with the DropboxSDK on iOS - must revisit and sort out soon
    if( [NSThread isMainThread] ) {
        [self performSelector:@selector(endExecution) withObject:nil afterDelay:0.1];
    } else {
        [self endExecution];
    }
}

- (void)operationDidStart
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfMainOperationPhase, @"TICDSOperation started");
    
    [self willChangeValueForKey:@"isExecuting"];
    _isExecuting = YES;
    [self didChangeValueForKey:@"isExecuting"];
}

- (void)operationDidCompleteSuccessfully
{
    [self ticdPrivate_operationDidCompleteSuccessfully:YES cancelled:NO];
}

- (void)operationDidFailToComplete
{
    [self ticdPrivate_operationDidCompleteSuccessfully:NO cancelled:NO];
}

- (void)operationWasCancelled
{
    [self ticdPrivate_operationDidCompleteSuccessfully:NO cancelled:YES];
}

#pragma mark - Lazy Accessors
- (NSFileManager *)fileManager
{
    if( _fileManager ) return _fileManager;
    
    _fileManager = [[NSFileManager alloc] init];
    
    return _fileManager;
}

#pragma mark - Initialization and Deallocation
- (id)initWithDelegate:(NSObject <TICDSOperationDelegate> *)aDelegate
{
    self = [super init];
    if( !self ) return nil;
    
    _delegate = aDelegate;
    
    _isExecuting = NO;
    _isFinished = NO;
    
    return self;
}

- (void)dealloc
{
    _cryptor = nil;
    _userInfo = nil;
    _error = nil;
    _clientIdentifier = nil;
    _fileManager = nil;
    _tempFileDirectoryPath = nil;

}

#pragma mark - Lazy Accessors
- (NSString *)tempFileDirectoryPath
{
    if( _tempFileDirectoryPath ) {
        return _tempFileDirectoryPath;
    }
    
    NSString *aDirectoryPath = [NSTemporaryDirectory() stringByAppendingPathComponent:[TICDSUtilities uuidString]];
    
    NSError *anyError = nil;
    BOOL success = [[self fileManager] createDirectoryAtPath:aDirectoryPath withIntermediateDirectories:NO attributes:nil error:&anyError];
    
    if( !success ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Internal error: unable to create temp file directory");
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
    }
    
    _tempFileDirectoryPath = aDirectoryPath;
    
    return _tempFileDirectoryPath;
}

#pragma mark - Coordinated I/O

// This queue is used to schedule file coordinator cancels, and serialize access to state variables
// used to determine whether to continue a file operation.
+ (dispatch_queue_t)fileCoordinationDispatchQueue
{
    static dispatch_queue_t queue = NULL;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = dispatch_queue_create("ticdsoperationfilecoordinatorqueue", DISPATCH_QUEUE_SERIAL);
    });
    return queue;
}

+ (void)scheduleFileCoordinatorTimeoutBlock:(void(^)(void))block
{
    static const double TICDSOperationFileCoordinatorTimeout = 20.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, TICDSOperationFileCoordinatorTimeout * NSEC_PER_SEC);
    dispatch_after(popTime, [self fileCoordinationDispatchQueue], block);
}

- (BOOL)copyItemAtPath:(NSString *)fromPath toPath:(NSString *)toPath error:(NSError **)error
{
    __block NSError *anyError = nil;
    __block BOOL success = NO;
    
    NSURL *readURL = [NSURL fileURLWithPath:fromPath];
    NSURL *writeURL = [NSURL fileURLWithPath:toPath];
    
    __block BOOL beganFileOperation = NO;
    __block BOOL cancelled = NO;
    NSFileCoordinator *fileCoordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
    [self.class scheduleFileCoordinatorTimeoutBlock:^{
        if ( !beganFileOperation ) {
            [fileCoordinator cancel];
            cancelled = YES;
        }
    }];
    
    [fileCoordinator coordinateReadingItemAtURL:readURL options:0 writingItemAtURL:writeURL options:NSFileCoordinatorWritingForReplacing error:&anyError byAccessor:^(NSURL *newReadingURL, NSURL *newWritingURL) {
        dispatch_sync([self.class fileCoordinationDispatchQueue], ^{ beganFileOperation = YES; });
        if ( cancelled ) return;
        [[self fileManager] removeItemAtURL:newWritingURL error:NULL];
        success = [[self fileManager] copyItemAtURL:newReadingURL toURL:newWritingURL error:&anyError];
    }];
    
    if ( !success && !cancelled ) {
        // Force it
        anyError = nil;
        [[self fileManager] removeItemAtURL:writeURL error:NULL];
        success = [[self fileManager] copyItemAtURL:readURL toURL:writeURL error:&anyError];
    }

    if ( error ) *error = anyError;
    return success;
}

- (BOOL)moveItemAtPath:(NSString *)fromPath toPath:(NSString *)toPath error:(NSError **)error
{
    __block NSError *anyError = nil;
    NSURL *fromURL = [NSURL fileURLWithPath:fromPath];
    NSURL *toURL = [NSURL fileURLWithPath:toPath];
    __block BOOL success = NO;
    
    __block BOOL beganFileOperation = NO;
    __block BOOL cancelled = NO;
    NSFileCoordinator *fileCoordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
    [self.class scheduleFileCoordinatorTimeoutBlock:^{
        if ( !beganFileOperation ) {
            [fileCoordinator cancel];
            cancelled = YES;
        }
    }];
    
    [fileCoordinator coordinateWritingItemAtURL:fromURL options:NSFileCoordinatorWritingForDeleting writingItemAtURL:toURL options:NSFileCoordinatorWritingForReplacing error:&anyError byAccessor:^(NSURL *newFromURL, NSURL *newToURL) {
        dispatch_sync([self.class fileCoordinationDispatchQueue], ^{ beganFileOperation = YES; });
        if ( cancelled ) return;
        success = [[self fileManager] moveItemAtURL:newFromURL toURL:newToURL error:&anyError];
        [fileCoordinator itemAtURL:newFromURL didMoveToURL:newToURL];
    }];
    
    if ( error ) *error = anyError;
    return success;
}

- (BOOL)removeItemAtPath:(NSString *)fromPath error:(NSError **)error
{
    NSURL *fromURL = [NSURL fileURLWithPath:fromPath];
    __block BOOL success = NO;
    __block NSError *anyError = nil;
    
    __block BOOL beganFileOperation = NO;
    __block BOOL cancelled = NO;
    NSFileCoordinator *fileCoordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
    [self.class scheduleFileCoordinatorTimeoutBlock:^{
        if ( !beganFileOperation ) {
            [fileCoordinator cancel];
            cancelled = YES;
        }
    }];
    
    [fileCoordinator coordinateWritingItemAtURL:fromURL options:NSFileCoordinatorWritingForDeleting error:&anyError byAccessor:^(NSURL *newURL) {
        dispatch_sync([self.class fileCoordinationDispatchQueue], ^{ beganFileOperation = YES; });
        if ( cancelled ) return;
        success = [[self fileManager] removeItemAtURL:newURL error:&anyError];
    }];
    
    if ( error ) *error = anyError;
    
    return success;
}

- (BOOL)fileExistsAtPath:(NSString *)fromPath
{
    NSURL *url = [NSURL fileURLWithPath:fromPath];
    __block NSError *anyError = nil;
    __block BOOL result = NO;
    
    __block BOOL beganFileOperation = NO;
    __block BOOL cancelled = NO;
    NSFileCoordinator *fileCoordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
    [self.class scheduleFileCoordinatorTimeoutBlock:^{
        if ( !beganFileOperation ) {
            [fileCoordinator cancel];
            cancelled = YES;
        }
    }];
    
    [fileCoordinator coordinateReadingItemAtURL:url options:0 error:&anyError byAccessor:^(NSURL *newURL) {
        dispatch_sync([self.class fileCoordinationDispatchQueue], ^{ beganFileOperation = YES; });
        if ( cancelled ) return;
        result = [[self fileManager] fileExistsAtPath:newURL.path];
    }];
    
    if ( anyError ) {
        result = [[self fileManager] fileExistsAtPath:url.path];
    }
    
    return result;
}

- (BOOL)createDirectoryAtPath:(NSString *)path withIntermediateDirectories:(BOOL)createIntermediates attributes:(NSDictionary *)attributes error:(NSError **)error
{
    NSURL *url = [NSURL fileURLWithPath:path];
    __block BOOL success = NO;
    __block NSError *anyError = nil;

    __block BOOL beganFileOperation = NO;
    __block BOOL cancelled = NO;
    NSFileCoordinator *fileCoordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
    [self.class scheduleFileCoordinatorTimeoutBlock:^{
        if ( !beganFileOperation ) {
            [fileCoordinator cancel];
            cancelled = YES;
        }
    }];
    
    [fileCoordinator coordinateWritingItemAtURL:url options:NSFileCoordinatorWritingForReplacing error:&anyError byAccessor:^(NSURL *newURL) {
        dispatch_sync([self.class fileCoordinationDispatchQueue], ^{ beganFileOperation = YES; });
        if ( cancelled ) return;
        success = [[self fileManager] createDirectoryAtPath:newURL.path withIntermediateDirectories:createIntermediates attributes:attributes error:&anyError];
    }];

    if ( error ) *error = anyError;
    return success;
}

- (NSArray *)contentsOfDirectoryAtPath:(NSString *)path error:(NSError **)error
{
    NSURL *url = [NSURL fileURLWithPath:path];
    __block NSError *anyError;
    __block NSArray *result = nil;

    __block BOOL beganFileOperation = NO;
    __block BOOL cancelled = NO;
    NSFileCoordinator *fileCoordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
    [self.class scheduleFileCoordinatorTimeoutBlock:^{
        if ( !beganFileOperation ) {
            [fileCoordinator cancel];
            cancelled = YES;
        }
    }];
    
    [fileCoordinator coordinateReadingItemAtURL:url options:0 error:&anyError byAccessor:^(NSURL *newURL) {
        dispatch_sync([self.class fileCoordinationDispatchQueue], ^{ beganFileOperation = YES; });
        if ( cancelled ) return;
        result = [[self fileManager] contentsOfDirectoryAtPath:newURL.path error:&anyError];
    }];
    
    if ( error ) *error = anyError;
    return result;
}

- (NSDictionary *)attributesOfItemAtPath:(NSString *)path error:(NSError **)error
{
    NSURL *url = [NSURL fileURLWithPath:path];
    __block NSError *anyError;
    __block NSDictionary *result = nil;

    __block BOOL beganFileOperation = NO;
    __block BOOL cancelled = NO;
    NSFileCoordinator *fileCoordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
    [self.class scheduleFileCoordinatorTimeoutBlock:^{
        if ( !beganFileOperation ) {
            [fileCoordinator cancel];
            cancelled = YES;
        }
    }];
    
    [fileCoordinator coordinateReadingItemAtURL:url options:0 error:&anyError byAccessor:^(NSURL *newURL) {
        dispatch_sync([self.class fileCoordinationDispatchQueue], ^{ beganFileOperation = YES; });
        if ( cancelled ) return;
        result = [[self fileManager] attributesOfItemAtPath:newURL.path error:&anyError];
    }];
    
    if ( error ) *error = anyError;
    return result;
}

-(BOOL)writeData:(NSData *)data toFile:(NSString *)path error:(NSError **)error
{
    NSURL *url = [NSURL fileURLWithPath:path];
    __block BOOL success = NO;
    __block NSError *anyError = nil;

    __block BOOL beganFileOperation = NO;
    __block BOOL cancelled = NO;
    NSFileCoordinator *fileCoordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
    [self.class scheduleFileCoordinatorTimeoutBlock:^{
        if ( !beganFileOperation ) {
            [fileCoordinator cancel];
            cancelled = YES;
        }
    }];
    
    [fileCoordinator coordinateWritingItemAtURL:url options:NSFileCoordinatorWritingForReplacing error:&anyError byAccessor:^(NSURL *newURL) {
        dispatch_sync([self.class fileCoordinationDispatchQueue], ^{ beganFileOperation = YES; });
        if ( cancelled ) return;
        success = [data writeToFile:newURL.path options:0 error:&anyError];
    }];
    
    if ( error ) *error = anyError;
    return success;
}

-(BOOL)writeObject:(id)object toFile:(NSString *)path
{
    NSURL *url = [NSURL fileURLWithPath:path];
    __block BOOL success = NO;
    __block NSError *anyError = nil;

    __block BOOL beganFileOperation = NO;
    __block BOOL cancelled = NO;
    NSFileCoordinator *fileCoordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
    [self.class scheduleFileCoordinatorTimeoutBlock:^{
        if ( !beganFileOperation ) {
            [fileCoordinator cancel];
            cancelled = YES;
        }
    }];
    
    [fileCoordinator coordinateWritingItemAtURL:url options:NSFileCoordinatorWritingForReplacing error:&anyError byAccessor:^(NSURL *newURL) {
        dispatch_sync([self.class fileCoordinationDispatchQueue], ^{ beganFileOperation = YES; });
        if ( cancelled ) return;
        success = [object writeToFile:newURL.path atomically:NO];
    }];
    
    return success;
}

-(NSData *)dataWithContentsOfFile:(NSString *)path error:(NSError **)error
{
    NSURL *url = [NSURL fileURLWithPath:path];
    __block NSError *anyError;
    __block NSData *result = nil;

    __block BOOL beganFileOperation = NO;
    __block BOOL cancelled = NO;
    NSFileCoordinator *fileCoordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
    [self.class scheduleFileCoordinatorTimeoutBlock:^{
        if ( !beganFileOperation ) {
            [fileCoordinator cancel];
            cancelled = YES;
        }
    }];
    
    [fileCoordinator coordinateReadingItemAtURL:url options:0 error:&anyError byAccessor:^(NSURL *newURL) {
        dispatch_sync([self.class fileCoordinationDispatchQueue], ^{ beganFileOperation = YES; });
        if ( cancelled ) return;
        result = [NSData dataWithContentsOfFile:newURL.path options:0 error:&anyError];
    }];
    
    if ( error ) *error = anyError;
    return result;
}

-(id)readObjectFromFile:(NSString *)path
{
    NSURL *url = [NSURL fileURLWithPath:path];
    __block NSError *anyError;
    __block id result = nil;

    __block BOOL beganFileOperation = NO;
    __block BOOL cancelled = NO;
    NSFileCoordinator *fileCoordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
    [self.class scheduleFileCoordinatorTimeoutBlock:^{
        if ( !beganFileOperation ) {
            [fileCoordinator cancel];
            cancelled = YES;
        }
    }];
    
    [fileCoordinator coordinateReadingItemAtURL:url options:0 error:&anyError byAccessor:^(NSURL *newURL) {
        dispatch_sync([self.class fileCoordinationDispatchQueue], ^{ beganFileOperation = YES; });
        if ( cancelled ) return;
        NSInputStream *stream = [NSInputStream inputStreamWithFileAtPath:newURL.path];
        result = [NSPropertyListSerialization propertyListWithStream:stream options:0 format:0 error:&anyError];
    }];
    
    return result;
}

#pragma mark - Properties
@synthesize shouldUseEncryption = _shouldUseEncryption;
@synthesize cryptor = _cryptor;
@synthesize delegate = _delegate;
@synthesize userInfo = _userInfo;
@synthesize isExecuting = _isExecuting;
@synthesize isFinished = _isFinished;
@synthesize error = _error;
@synthesize fileManager = _fileManager;
@synthesize tempFileDirectoryPath = _tempFileDirectoryPath;
@synthesize clientIdentifier = _clientIdentifier;

@end
