//
//  TICDSSyncTransaction.m
//  TICoreDataSync-Mac
//
//  Created by Michael Fey on 4/9/13.
//  Copyright (c) 2013 No Thirst Software LLC. All rights reserved.
//

#import "TICoreDataSync.h"

@interface TICDSSyncTransaction () <TICoreDataFactoryDelegate>

/** The document managed object context for the application. */
@property (strong) NSManagedObjectContext *documentManagedObjectContext;

/** The URL to the unsaved applied sync change sets file for this sync transaction. */
@property (readwrite) NSURL *unsavedAppliedSyncChangesFileURL;

/** The next managed object context in the chain between the document's context and the root context that needs to be saved before this sync transaction can be 'closed'. */
@property NSManagedObjectContext *nextManagedObjectContextToBeVerified;

/** A `TICoreDataFactory` to access the contents of the `*.unsavedticdsync` file. */
@property (nonatomic, strong) TICoreDataFactory *unsavedAppliedSyncChangeSetsCoreDataFactory;

/** The managed object context for the `*.unsavedticdsync` file. */
@property (nonatomic, strong) NSManagedObjectContext *unsavedAppliedSyncChangeSetsContext;

/** A `TICoreDataFactory` to access the contents of the `AppliedSyncChangeSets.ticdsync` file. */
@property (nonatomic, strong) TICoreDataFactory *appliedSyncChangeSetsCoreDataFactory;

/** The managed object context for the `AppliedSyncChangeSets.ticdsync` file. */
@property (nonatomic, strong) NSManagedObjectContext *appliedSyncChangeSetsContext;

@end

#pragma mark -

@implementation TICDSSyncTransaction

- (id)initWithDocumentManagedObjectContext:(NSManagedObjectContext *)managedObjectContext unsavedAppliedSyncChangesDirectoryPath:(NSString *)unsavedAppliedSyncChangesDirectoryPath
{
    self = [super init];
    if (self == nil) {
        return nil;
    }

    self.state = TICDSSyncTransactionStateNotYetOpen;
    [self setupUnsavedAppliedSyncChangesFileURLInDirectoryPath:unsavedAppliedSyncChangesDirectoryPath];
    self.documentManagedObjectContext = managedObjectContext;

    return self;
}

- (void)open
{
    TICDSLog(TICDSLogVerbosityEveryStep, @"Opening a sync transaction for unsaved applied sync changes located at %@", [self.unsavedAppliedSyncChangesFileURL.path lastPathComponent]);
    
    self.state = TICDSSyncTransactionStateOpen;
    [self registerForManagedObjectContextDidSaveNotificationsForDocumentManagedObjectContextAndAllItsForefathers:self.documentManagedObjectContext];
}

- (void)close
{
    TICDSLog(TICDSLogVerbosityEveryStep, @"Closing a sync transaction for unsaved applied sync changes located at %@", [self.unsavedAppliedSyncChangesFileURL.path lastPathComponent]);

    [self saveUnsavedAppliedSyncChanges];
}

#pragma mark - Local methods

- (void)setupUnsavedAppliedSyncChangesFileURLInDirectoryPath:(NSString *)unsavedAppliedSyncChangesDirectoryPath
{
    NSString *uniqueID = [TICDSUtilities uuidString];
    NSString *unsavedAppliedSyncChangesFileName = [uniqueID stringByAppendingPathExtension:TICDSUnsavedAppliedSyncChangeSetsFileExtension];
    self.unsavedAppliedSyncChangesFileURL = [NSURL fileURLWithPath:[unsavedAppliedSyncChangesDirectoryPath stringByAppendingPathComponent:unsavedAppliedSyncChangesFileName]];
}

- (void)registerForManagedObjectContextDidSaveNotificationsForDocumentManagedObjectContextAndAllItsForefathers:(NSManagedObjectContext *)documentManagedObjectContext
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(managedObjectContextDidSave:) name:NSManagedObjectContextDidSaveNotification object:documentManagedObjectContext];
    
    NSManagedObjectContext *parentContext = documentManagedObjectContext.parentContext;
    while (parentContext != nil) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(managedObjectContextDidSave:) name:NSManagedObjectContextDidSaveNotification object:parentContext];
        
        parentContext = parentContext.parentContext;
    }
    
    self.nextManagedObjectContextToBeVerified = documentManagedObjectContext;
}

- (void)managedObjectContextDidSave:(NSNotification *)notification
{
    NSManagedObjectContext *managedObjectContext = notification.object;
    if (managedObjectContext != self.nextManagedObjectContextToBeVerified) {
        TICDSLog(TICDSLogVerbosityEveryStep, @"Managed object context did save, but it wasn't the MOC we were looking for.");
        return;
    }
    
    TICDSLog(TICDSLogVerbosityEveryStep, @"Managed object context did save, and it was the MOC we were looking for.");

    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSManagedObjectContextDidSaveNotification object:managedObjectContext];
    
    self.nextManagedObjectContextToBeVerified = managedObjectContext.parentContext;
    
    if (self.nextManagedObjectContextToBeVerified == nil) {
        TICDSLog(TICDSLogVerbosityEveryStep, @"The root context saved, notifying the delegate that this sync transaction can be closed.");
        
        if ([self ti_delegateRespondsToSelector:@selector(syncTransactionIsReadyToBeClosed:)]) {
            [self notifyDelegateReadyToBeClosed];
        }
    }
}

- (void)notifyDelegateReadyToBeClosed
{
    [(id)self.delegate performSelectorOnMainThread:@selector(syncTransactionIsReadyToBeClosed:) withObject:self waitUntilDone:NO];
}

- (void)saveUnsavedAppliedSyncChanges
{
    TICDSLog(TICDSLogVerbosityEveryStep, @"Saving unsaved applied sync changes");
    
    NSError *anyError = nil;
    NSArray *sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:YES], [NSSortDescriptor sortDescriptorWithKey:@"syncChangeSetIdentifier" ascending:YES]];
    NSArray *unsavedAppliedSyncChangeSets = [TICDSSyncChangeSet ti_allObjectsInManagedObjectContext:self.unsavedAppliedSyncChangeSetsContext sortedWithDescriptors:sortDescriptors error:&anyError];
    
    if (unsavedAppliedSyncChangeSets == nil) {
        self.error = [TICDSError errorWithCode:TICDSErrorCodeCoreDataFetchError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__];
        [self closeTransactionWithSuccess:NO];
        return;
    }
    
    BOOL success = [self saveUnsavedAppliedSyncChangeSets:unsavedAppliedSyncChangeSets];
    if (success == NO) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Failed to save applied sync change sets context: %@", self.error);
        [self closeTransactionWithSuccess:NO];
        return;
    }

    success = [self.appliedSyncChangeSetsContext save:&anyError];
    if (success == NO) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Failed to save applied sync change sets context, after saving background context: %@", anyError);
        self.error = [TICDSError errorWithCode:TICDSErrorCodeCoreDataSaveError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__];
        [self closeTransactionWithSuccess:NO];
        return;
    }
    
    success = [self removeUnsavedAppliedSyncChangesFile];
    if (success == NO) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Failed to remove the unsaved applied sync changes file. %@", self.error);
        [self closeTransactionWithSuccess:YES];
    }

    TICDSLog(TICDSLogVerbosityEveryStep, @"Saved unsaved applied sync changes");
    [self closeTransactionWithSuccess:YES];
}

- (BOOL)saveUnsavedAppliedSyncChangeSets:(NSArray *)unsavedAppliedSyncChangeSets
{
    BOOL shouldContinue = YES;
    
    for (TICDSSyncChangeSet *unsavedAppliedSyncChangeSet in unsavedAppliedSyncChangeSets) {
        @autoreleasepool {
            shouldContinue = [self addSyncChangeSetToAppliedSyncChangeSets:unsavedAppliedSyncChangeSet];
            if (shouldContinue == NO) {
                break;
            }
        }
    }
    
    return shouldContinue;
}

- (BOOL)addSyncChangeSetToAppliedSyncChangeSets:(TICDSSyncChangeSet *)unsavedAppliedSyncChangeSet
{
    NSString *syncChangeSetIdentifier = unsavedAppliedSyncChangeSet.syncChangeSetIdentifier;
    NSString *clientIdentifier = unsavedAppliedSyncChangeSet.clientIdentifier;
    NSDate *creationDate = unsavedAppliedSyncChangeSet.creationDate;
    NSDate *localDateOfApplication = unsavedAppliedSyncChangeSet.localDateOfApplication;
    
    TICDSSyncChangeSet *savedAppliedSyncChangeSet = [TICDSSyncChangeSet changeSetWithIdentifier:syncChangeSetIdentifier inManagedObjectContext:self.appliedSyncChangeSetsContext];
    
    if (savedAppliedSyncChangeSet == nil) {
        savedAppliedSyncChangeSet = [TICDSSyncChangeSet syncChangeSetWithIdentifier:syncChangeSetIdentifier fromClient:clientIdentifier creationDate:creationDate inManagedObjectContext:self.appliedSyncChangeSetsContext];
    }
    
    if (savedAppliedSyncChangeSet == nil) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Unable to create sync change set in applied sync change sets context");
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeObjectCreationError classAndMethod:__PRETTY_FUNCTION__]];
        return NO;
    }
    
    savedAppliedSyncChangeSet.localDateOfApplication = localDateOfApplication;
    
    return YES;
}

- (BOOL)removeUnsavedAppliedSyncChangesFile
{
    self.unsavedAppliedSyncChangeSetsContext = nil;
    self.unsavedAppliedSyncChangeSetsCoreDataFactory = nil;
    
    NSError *error = nil;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL success = [fileManager removeItemAtPath:[self.unsavedAppliedSyncChangesFileURL path] error:&error];
    if (error != nil) {
        self.error = error;
    }
    
    return success;
}

- (void)closeTransactionWithSuccess:(BOOL)transactionClosedSuccessfully
{
    if (transactionClosedSuccessfully) {
        self.state = TICDSSyncTransactionStateClosed;
    } else {
        self.state = TICDSSyncTransactionStateUnableToClose;
    }
}

#pragma mark - Overridden getters/setters

- (NSManagedObjectContext *)unsavedAppliedSyncChangeSetsContext
{
    if (_unsavedAppliedSyncChangeSetsContext != nil) {
        return _unsavedAppliedSyncChangeSetsContext;
    }
    
    _unsavedAppliedSyncChangeSetsContext = [self.unsavedAppliedSyncChangeSetsCoreDataFactory managedObjectContext];
    _unsavedAppliedSyncChangeSetsContext.undoManager = nil;
    
    return _unsavedAppliedSyncChangeSetsContext;
}

- (TICoreDataFactory *)unsavedAppliedSyncChangeSetsCoreDataFactory
{
    if (_unsavedAppliedSyncChangeSetsCoreDataFactory != nil) {
        return _unsavedAppliedSyncChangeSetsCoreDataFactory;
    }
    
    TICDSLog(TICDSLogVerbosityEveryStep, @"Creating Core Data Factory (TICoreDataFactory)");
    _unsavedAppliedSyncChangeSetsCoreDataFactory = [[TICoreDataFactory alloc] initWithMomdName:TICDSSyncChangeSetDataModelName];
    _unsavedAppliedSyncChangeSetsCoreDataFactory.persistentStoreType = TICDSSyncChangeSetsCoreDataPersistentStoreType;
    _unsavedAppliedSyncChangeSetsCoreDataFactory.persistentStoreDataPath = [self.unsavedAppliedSyncChangesFileURL path];
    _unsavedAppliedSyncChangeSetsCoreDataFactory.delegate = self;
    
    return _unsavedAppliedSyncChangeSetsCoreDataFactory;
}

- (NSManagedObjectContext *)appliedSyncChangeSetsContext
{
    if (_appliedSyncChangeSetsContext != nil) {
        return _appliedSyncChangeSetsContext;
    }
    
    _appliedSyncChangeSetsContext = [self.appliedSyncChangeSetsCoreDataFactory managedObjectContext];
    _appliedSyncChangeSetsContext.undoManager = nil;
    
    return _appliedSyncChangeSetsContext;
}

- (TICoreDataFactory *)appliedSyncChangeSetsCoreDataFactory
{
    if (_appliedSyncChangeSetsCoreDataFactory != nil) {
        return _appliedSyncChangeSetsCoreDataFactory;
    }
    
    TICDSLog(TICDSLogVerbosityEveryStep, @"Creating Core Data Factory (TICoreDataFactory)");
    _appliedSyncChangeSetsCoreDataFactory = [[TICoreDataFactory alloc] initWithMomdName:TICDSSyncChangeSetDataModelName];
    _appliedSyncChangeSetsCoreDataFactory.persistentStoreType = TICDSSyncChangeSetsCoreDataPersistentStoreType;
    _appliedSyncChangeSetsCoreDataFactory.persistentStoreDataPath = [self.appliedSyncChangesFileURL path];
    _appliedSyncChangeSetsCoreDataFactory.delegate = self;
    
    return _appliedSyncChangeSetsCoreDataFactory;
}

#pragma mark - TICoreDataFactoryDelegate methods

- (void)coreDataFactory:(TICoreDataFactory *)aFactory encounteredError:(NSError *)anError;
{
    TICDSLog(TICDSLogVerbosityErrorsOnly, @"Applied Sync Change Sets Factory Error: %@", anError);
}

@end
