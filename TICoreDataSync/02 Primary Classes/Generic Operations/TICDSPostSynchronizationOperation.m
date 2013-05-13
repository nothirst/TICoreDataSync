//
//  TICDSPostSynchronizationOperation.m
//  ShoppingListMac
//
//  Created by Tim Isted on 26/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICoreDataSync.h"

@interface TICDSPostSynchronizationOperation () <TICoreDataFactoryDelegate>

/** @name File Locations */

/** @name Managed Object Contexts and Factories */

/** A `TICoreDataFactory` to access the contents of the `AppliedSyncChangeSets.ticdsync` file. */
@property (nonatomic, strong) TICoreDataFactory *appliedSyncChangeSetsCoreDataFactory;

/** The managed object context for the `AppliedSyncChangeSets.ticdsync` file. */
@property (nonatomic, strong) NSManagedObjectContext *appliedSyncChangeSetsContext;

@property (nonatomic, copy) NSString *changeSetProgressString;
@property (nonatomic, readonly) NSNumberFormatter *uuidPrefixFormatter;
@property (nonatomic, copy) NSString *localSyncChangeSetIdentifier;

@end

@implementation TICDSPostSynchronizationOperation

@synthesize uuidPrefixFormatter = _uuidPrefixFormatter;

- (void)main
{
    if (self.isCancelled) {
        [self operationWasCancelled];
        return;
    }
    
    [self beginUploadOfLocalSyncCommands];
}

#pragma mark - UPLOAD OF LOCAL SYNC COMMANDS
- (void)beginUploadOfLocalSyncCommands
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachOperationPhase, @"Starting to upload local sync commands");

    // TODO: Upload of Local Sync Commands
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachOperationPhase, @"***Not yet implemented*** so 'finished' local sync commands");

    [self beginUploadOfLocalSyncChanges];
}

#pragma mark - UPLOAD OF LOCAL SYNC CHANGES

- (void)beginUploadOfLocalSyncChanges
{
    if (self.isCancelled) {
        [self operationWasCancelled];
        return;
    }
    
    if ([[self fileManager] fileExistsAtPath:[self.localSyncChangesToMergeURL path]] == NO) {
        TICDSLog(TICDSLogVerbosityEveryStep, @"No local sync changes file to push on this sync");
        [self beginUploadOfRecentSyncFile];
        return;
    }

    TICDSLog(TICDSLogVerbosityEveryStep, @"Renaming sync changes file ready for upload");

    self.localSyncChangeSetIdentifier = [NSString stringWithFormat:@"%@-%@", [self.uuidPrefixFormatter stringFromNumber:[NSNumber numberWithDouble:CFAbsoluteTimeGetCurrent()]], [TICDSUtilities uuidString]];

    NSString *filePath = [self.localSyncChangesToMergeURL path];
    filePath = [filePath stringByDeletingLastPathComponent];
    filePath = [filePath stringByAppendingPathComponent:self.localSyncChangeSetIdentifier];
    filePath = [filePath stringByAppendingPathExtension:TICDSSyncChangeSetFileExtension];

    NSError *anyError = nil;
    BOOL success = [[self fileManager] copyItemAtPath:[self.localSyncChangesToMergeURL path] toPath:filePath error:&anyError];

    if (success == NO) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Failed to copy local sync changes to merge file");

        [self setError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
        [self operationDidFailToComplete];
        return;
    }

    TICDSLog(TICDSLogVerbosityStartAndEndOfEachOperationPhase, @"Starting to upload local sync changes");
    [self uploadLocalSyncChangeSetFileAtLocation:[NSURL fileURLWithPath:filePath]];
}

- (void)uploadedLocalSyncChangeSetFileSuccessfully:(BOOL)success
{
    if (self.isCancelled) {
        [self operationWasCancelled];
        return;
    }
    
    if (success == NO) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Failed to upload local sync changes files");
        [self operationDidFailToComplete];
        return;
    }

    TICDSLog(TICDSLogVerbosityStartAndEndOfEachOperationPhase, @"Uploaded local sync changes file");

    NSDate *date = [NSDate date];
    
    TICDSLog(TICDSLogVerbosityEveryStep, @"Adding local sync change set into AppliedSyncChanges");
    TICDSSyncChangeSet *appliedSyncChangeSet = [TICDSSyncChangeSet syncChangeSetWithIdentifier:self.localSyncChangeSetIdentifier fromClient:[self clientIdentifier] creationDate:date inManagedObjectContext:self.appliedSyncChangeSetsContext];
    
    if (appliedSyncChangeSet == nil) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Unable to create sync change set in applied sync change sets context");
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeObjectCreationError classAndMethod:__PRETTY_FUNCTION__]];
        [self operationDidFailToComplete];
        return;
    }
    
    [appliedSyncChangeSet setLocalDateOfApplication:date];
    
    // Save Applied Sync Change Sets context (AppliedSyncChangeSets.ticdsync file)
    NSError *anyError = nil;
    success = [self.appliedSyncChangeSetsContext save:&anyError];
    if (success == NO) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Failed to save applied sync change sets context, after adding local merged changes: %@", anyError);
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeCoreDataSaveError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
        [self operationDidFailToComplete];
        return;
    }
    
    // The file has been copied and uploaded so we can get rid of the original version
    [[self fileManager] removeItemAtPath:[self.localSyncChangesToMergeURL path] error:&anyError];

    [self beginUploadOfRecentSyncFile];
}

#pragma mark Overridden Method
- (void)uploadLocalSyncChangeSetFileAtLocation:(NSURL *)aLocation
{
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeMethodNotOverriddenBySubclass classAndMethod:__PRETTY_FUNCTION__]];
    [self uploadedLocalSyncChangeSetFileSuccessfully:NO];
}

#pragma mark - RECENT SYNC FILE
- (void)beginUploadOfRecentSyncFile
{
    if (self.isCancelled) {
        [self operationWasCancelled];
        return;
    }
    
    NSString *recentSyncFilePath = [self.localRecentSyncFileLocation path];

    NSDictionary *recentSyncDictionary = [NSDictionary dictionaryWithObject:[NSDate date] forKey:kTICDSLastSyncDate];

    BOOL success = [recentSyncDictionary writeToFile:recentSyncFilePath atomically:YES];

    if (success == NO) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Failed to write RecentSync file to helper file location, but not absolutely fatal so continuing");
        [self operationDidCompleteSuccessfully];
        return;
    }

    [self uploadRecentSyncFileAtLocation:[NSURL fileURLWithPath:recentSyncFilePath]];
}

- (void)uploadedRecentSyncFileSuccessfully:(BOOL)success
{
    if (self.isCancelled) {
        [self operationWasCancelled];
        return;
    }
    
    if (success == NO) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Failed to upload RecentSync file, but not absolutely fatal so continuing: %@", [self error]);
    }

    [self operationDidCompleteSuccessfully];
}

#pragma mark Overridden Method
- (void)uploadRecentSyncFileAtLocation:(NSURL *)aLocation
{
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeMethodNotOverriddenBySubclass classAndMethod:__PRETTY_FUNCTION__]];
    [self uploadedRecentSyncFileSuccessfully:NO];
}

#pragma mark - TICoreDataFactory Delegate
- (void)coreDataFactory:(TICoreDataFactory *)aFactory encounteredError:(NSError *)anError
{
    TICDSLog(TICDSLogVerbosityErrorsOnly, @"Applied Sync Change Sets Factory Error: %@", anError);
}

#pragma mark - Lazy Accessors

- (NSManagedObjectContext *)appliedSyncChangeSetsContext
{
    if (_appliedSyncChangeSetsContext) {
        return _appliedSyncChangeSetsContext;
    }

    _appliedSyncChangeSetsContext = [self.appliedSyncChangeSetsCoreDataFactory managedObjectContext];
    [_appliedSyncChangeSetsContext setUndoManager:nil];

    return _appliedSyncChangeSetsContext;
}

- (TICoreDataFactory *)appliedSyncChangeSetsCoreDataFactory
{
    if (_appliedSyncChangeSetsCoreDataFactory) {
        return _appliedSyncChangeSetsCoreDataFactory;
    }

    TICDSLog(TICDSLogVerbosityEveryStep, @"Creating Core Data Factory (TICoreDataFactory)");
    _appliedSyncChangeSetsCoreDataFactory = [[TICoreDataFactory alloc] initWithMomdName:TICDSSyncChangeSetDataModelName];
    [_appliedSyncChangeSetsCoreDataFactory setPersistentStoreType:TICDSSyncChangeSetsCoreDataPersistentStoreType];
    [_appliedSyncChangeSetsCoreDataFactory setPersistentStoreDataPath:[self.appliedSyncChangeSetsFileLocation path]];
    [_appliedSyncChangeSetsCoreDataFactory setDelegate:self];

    return _appliedSyncChangeSetsCoreDataFactory;
}

- (NSNumberFormatter *)uuidPrefixFormatter
{
    if (_uuidPrefixFormatter == nil) {
        _uuidPrefixFormatter = [[NSNumberFormatter alloc] init];
        [_uuidPrefixFormatter setPositiveFormat:@"0000000000.000000"];
    }

    return _uuidPrefixFormatter;
}

#pragma mark - Properties

@end
