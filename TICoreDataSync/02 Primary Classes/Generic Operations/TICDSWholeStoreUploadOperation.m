//
//  TICDSWholeStoreUploadOperation.m
//  ShoppingListMac
//
//  Created by Tim Isted on 25/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICoreDataSync.h"

@interface TICDSWholeStoreUploadOperation ()

- (void)beginCheckForMissingSyncIDAttributes;
- (void)beginSettingMissingSyncIDAttributesForEntityDescriptions:(NSArray *)someEntityDescriptions;
- (void)beginCheckForThisClientTemporaryWholeStoreDirectory;
- (void)beginDeletingThisClientTemporaryWholeStoreDirectory;
- (void)beginCreatingThisClientTemporaryWholeStoreDirectory;
- (void)beginUploadingLocalWholeStoreFileToThisClientTemporaryWholeStoreDirectory;
- (void)beginUploadingLocalAppliedSyncChangeSetsFileToThisClientTemporaryWholeStoreDirectory;
- (void)beginCheckForThisClientWholeStoreDirectory;
- (void)beginDeletingThisClientWholeStoreDirectory;
- (void)beginCopyingThisClientTemporaryWholeStoreDirectoryToThisClientWholeStoreDirectory;
- (void)uploadingWholeStoreFileToThisClientTemporaryWholeStoreDirectoryMadeProgress;
- (void)uploadingLocalAppliedSyncChangeSetsFileToThisClientTemporaryWholeStoreDirectoryMadeProgress;

@end

@implementation TICDSWholeStoreUploadOperation

- (void)main
{
    [self beginCheckForMissingSyncIDAttributes];
}

#pragma mark - Check for Missing ticdsSyncID attributes
- (void)beginCheckForMissingSyncIDAttributes
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachOperationPhase, @"Checking whether there are any missing ticdsSyncIDs in any managed objects");

    NSMutableArray *problemEntities = [NSMutableArray array];

    [self.backgroundApplicationContext performBlockAndWait:^{
         NSArray *allEntities = [[[[self backgroundApplicationContext] persistentStoreCoordinator] managedObjectModel] entities];

         NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
         [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"%K == %@", TICDSSyncIDAttributeName, nil]];
         NSUInteger objectCount = 0;
         NSError *anyError = nil;
         BOOL syncIDAttributeFound = NO;

         for ( NSEntityDescription * eachEntity in allEntities ) {
             syncIDAttributeFound = NO;

             for ( NSString * eachKey in [eachEntity attributesByName] ) {
                 if ( [eachKey isEqualToString:TICDSSyncIDAttributeName] ) {
                     syncIDAttributeFound = YES;
                 }
             }

             if ( !syncIDAttributeFound ) {
                 continue;
             }

             [fetchRequest setEntity:eachEntity];

             objectCount = [[self backgroundApplicationContext] countForFetchRequest:fetchRequest error:&anyError];

             if ( objectCount == NSNotFound ) {
                 TICDSLog(TICDSLogVerbosityErrorsOnly, @"Unable to execute count for fetch request for entity %@: %@", [eachEntity name], anyError);
                 [self setError:[TICDSError errorWithCode:TICDSErrorCodeCoreDataFetchError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
                 [self operationDidFailToComplete];
                 return;
             }

             if ( objectCount > 0 ) {
                 [problemEntities addObject:eachEntity];
             }
         }

         if ( [problemEntities count] < 1 ) {
             TICDSLog(TICDSLogVerbosityStartAndEndOfEachOperationPhase, @"No missing ticdsSyncIDs need to be fixed");
             [self beginCheckForThisClientTemporaryWholeStoreDirectory];
         } else {
             TICDSLog(TICDSLogVerbosityStartAndEndOfEachOperationPhase, @"Missing ticdsSyncIDs need to be fixed before uploading the store");
             [self beginSettingMissingSyncIDAttributesForEntityDescriptions:problemEntities];
         }
     }];
}

- (void)beginSettingMissingSyncIDAttributesForEntityDescriptions:(NSArray *)someEntityDescriptions
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachOperationPhase, @"Starting to fix missing ticdsSyncIDs");
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"%K == %@", TICDSSyncIDAttributeName, nil]];
    [fetchRequest setIncludesPropertyValues:NO];
    __block NSError *anyError = nil;
    
    for( NSEntityDescription *eachEntity in someEntityDescriptions ) {
        TICDSLog(TICDSLogVerbosityEveryStep, @"Fixing missing ticdsSyncIDs in %@", [eachEntity name]);
        [fetchRequest setEntity:eachEntity];
        [self.backgroundApplicationContext performBlockAndWait:^{
            NSArray *results = [[self backgroundApplicationContext] executeFetchRequest:fetchRequest error:&anyError];
            
            if( !results ) {
                TICDSLog(TICDSLogVerbosityErrorsOnly, @"Unable to execute fetch request for entity %@: %@", [eachEntity name], anyError);
                [self setError:[TICDSError errorWithCode:TICDSErrorCodeCoreDataFetchError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
                [self operationDidFailToComplete];
                return;
            }
            
            for( TICDSSynchronizedManagedObject *eachObject in results ) {
                [eachObject setValue:[TICDSUtilities uuidString] forKey:TICDSSyncIDAttributeName];
            }
            
            TICDSLog(TICDSLogVerbosityEveryStep, @"Fixed missing ticdsSyncIDs in %@", [eachEntity name]);
        }];
    }


    __block BOOL success = NO;
    [self.backgroundApplicationContext performBlockAndWait:^{
        [self.backgroundApplicationContext.parentContext.undoManager disableUndoRegistration];
        success = [[self backgroundApplicationContext] save:&anyError];
        [self.backgroundApplicationContext.parentContext.undoManager enableUndoRegistration];
    }];


    if( !success ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Error saving background context during missing ticdsSyncID updates: %@", anyError);
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeCoreDataSaveError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
        [self operationDidFailToComplete];
        return;
    }
    
    // finish
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachOperationPhase, @"Finished fixing missing ticdsSyncIDs");
    [self beginCheckForThisClientTemporaryWholeStoreDirectory];
}

#pragma mark - Check for Temporary WholeStore Directory
- (void)beginCheckForThisClientTemporaryWholeStoreDirectory
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachOperationPhase, @"Checking whether this client's temporary WholeStore directory exists");
    
    [self checkWhetherThisClientTemporaryWholeStoreDirectoryExists];
}

- (void)discoveredStatusOfThisClientTemporaryWholeStoreDirectory:(TICDSRemoteFileStructureExistsResponseType)status
{
    switch( status ) {
        case TICDSRemoteFileStructureExistsResponseTypeError:
            TICDSLog(TICDSLogVerbosityErrorsOnly, @"Error checking whether this client's temporary WholeStore directory exists");
            [self operationDidFailToComplete];
            return;
        
        case TICDSRemoteFileStructureExistsResponseTypeDoesExist:
            TICDSLog(TICDSLogVerbosityEveryStep, @"Temporary WholeStore directory exists");
            
            [self beginDeletingThisClientTemporaryWholeStoreDirectory];
            return;
            
        case TICDSRemoteFileStructureExistsResponseTypeDoesNotExist:
            TICDSLog(TICDSLogVerbosityEveryStep, @"Temporary WholeStore directory does not exist");
            
            [self beginCreatingThisClientTemporaryWholeStoreDirectory];
            return;
    }
}

#pragma mark Overridden Method
- (void)checkWhetherThisClientTemporaryWholeStoreDirectoryExists
{
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeMethodNotOverriddenBySubclass classAndMethod:__PRETTY_FUNCTION__]];
    [self discoveredStatusOfThisClientTemporaryWholeStoreDirectory:TICDSRemoteFileStructureExistsResponseTypeError];
}

#pragma mark - Deleting Temporary WholeStore Directory
- (void)beginDeletingThisClientTemporaryWholeStoreDirectory
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachOperationPhase, @"Checking whether this client's temporary WholeStore directory exists");
    
    [self deleteThisClientTemporaryWholeStoreDirectory];
}

- (void)deletedThisClientTemporaryWholeStoreDirectoryWithSuccess:(BOOL)success
{
    if( !success ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Failed to delete this client's temporary WholeStore directory");
        [self operationDidFailToComplete];
        return;
    }
    
    TICDSLog(TICDSLogVerbosityEveryStep, @"Deleted this client's temporary WholeStore directory");
    [self beginCreatingThisClientTemporaryWholeStoreDirectory];
}

#pragma mark Overridden Method
- (void)deleteThisClientTemporaryWholeStoreDirectory
{
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeMethodNotOverriddenBySubclass classAndMethod:__PRETTY_FUNCTION__]];
    [self deletedThisClientTemporaryWholeStoreDirectoryWithSuccess:NO];
}

#pragma mark - Creating Temporary WholeStore Directory
- (void)beginCreatingThisClientTemporaryWholeStoreDirectory
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachOperationPhase, @"Creating this client's temporary WholeStore directory");
    
    [self createThisClientTemporaryWholeStoreDirectory];
}

#pragma mark Overridden Method
- (void)createThisClientTemporaryWholeStoreDirectory
{
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeMethodNotOverriddenBySubclass classAndMethod:__PRETTY_FUNCTION__]];
    [self createdThisClientTemporaryWholeStoreDirectoryWithSuccess:NO];
}

- (void)createdThisClientTemporaryWholeStoreDirectoryWithSuccess:(BOOL)success
{
    if( !success ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Failed to create this client's temporary WholeStore directory");
        [self operationDidFailToComplete];
        return;
    }
    
    [self beginUploadingLocalWholeStoreFileToThisClientTemporaryWholeStoreDirectory];
}

#pragma mark - Uploading WholeStore file to Temporary WholeStore directory
- (void)beginUploadingLocalWholeStoreFileToThisClientTemporaryWholeStoreDirectory
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachOperationPhase, @"Uploading the WholeStore file to this client's temporary WholeStore directory");
    
    [self uploadLocalWholeStoreFileToThisClientTemporaryWholeStoreDirectory];
}

-(void)uploadingWholeStoreFileToThisClientTemporaryWholeStoreDirectoryMadeProgress;
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachOperationPhase, @"Uploading the WholeStore file to this client's temporary WholeStore directory made progress %.2f",[self progress]);
    
    [self operationDidMakeProgress];
}

- (void)uploadedWholeStoreFileToThisClientTemporaryWholeStoreDirectoryWithSuccess:(BOOL)success
{
    if( !success ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Failed to upload this client's  WholeStore file");
        [self operationDidFailToComplete];
        return;
    }
    
    [self beginUploadingLocalAppliedSyncChangeSetsFileToThisClientTemporaryWholeStoreDirectory];
}

#pragma mark Overridden Method
- (void)uploadLocalWholeStoreFileToThisClientTemporaryWholeStoreDirectory
{
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeMethodNotOverriddenBySubclass classAndMethod:__PRETTY_FUNCTION__]];
    [self uploadedWholeStoreFileToThisClientTemporaryWholeStoreDirectoryWithSuccess:NO];
}

#pragma mark - Uploading AppliedSyncChanges file
- (void)beginUploadingLocalAppliedSyncChangeSetsFileToThisClientTemporaryWholeStoreDirectory
{
    if( ![[self fileManager] fileExistsAtPath:[[self localAppliedSyncChangeSetsFileLocation] path]] ) {
        TICDSLog(TICDSLogVerbosityEveryStep, @"Local applied sync change sets file doesn't exist locally");
        
        [self beginCheckForThisClientWholeStoreDirectory];
        return;
    }
    
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachOperationPhase, @"Uploading the AppliedSyncChanges file to this client's temporary WholeStore directory");
    
    [self uploadLocalAppliedSyncChangeSetsFileToThisClientTemporaryWholeStoreDirectory];
}

- (void)uploadingLocalAppliedSyncChangeSetsFileToThisClientTemporaryWholeStoreDirectoryMadeProgress;
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachOperationPhase, @"Uploading the AppliedSyncChanges file to this client's temporary WholeStore directory made progress %.2f",[self progress]);
    
    [self operationDidMakeProgress];
}

- (void)uploadedAppliedSyncChangeSetsFileToThisClientTemporaryWholeStoreDirectoryWithSuccess:(BOOL)success
{
    if( !success ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Failed to upload this client's  AppliedSyncChangeSets file");
        [self operationDidFailToComplete];
        return;
    }
    
    [self beginCheckForThisClientWholeStoreDirectory];
}

#pragma mark Overridden Method
- (void)uploadLocalAppliedSyncChangeSetsFileToThisClientTemporaryWholeStoreDirectory
{
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeMethodNotOverriddenBySubclass classAndMethod:__PRETTY_FUNCTION__]];
    [self uploadedAppliedSyncChangeSetsFileToThisClientTemporaryWholeStoreDirectoryWithSuccess:NO];
}

#pragma mark - Check for Non-Temporary Whole Store Directory
- (void)beginCheckForThisClientWholeStoreDirectory
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachOperationPhase, @"Checking whether this client's WholeStore directory exists");
    
    [self checkWhetherThisClientWholeStoreDirectoryExists];
}

- (void)discoveredStatusOfThisClientWholeStoreDirectory:(TICDSRemoteFileStructureExistsResponseType)status
{
    switch( status ) {
        case TICDSRemoteFileStructureExistsResponseTypeError:
            TICDSLog(TICDSLogVerbosityErrorsOnly, @"Error checking whether this client's temporary WholeStore directory exists");
            [self operationDidFailToComplete];
            return;
            
        case TICDSRemoteFileStructureExistsResponseTypeDoesExist:
            TICDSLog(TICDSLogVerbosityEveryStep, @"WholeStore directory does exist for this client");
            
            [self beginDeletingThisClientWholeStoreDirectory];
            return;
            
        case TICDSRemoteFileStructureExistsResponseTypeDoesNotExist:
            TICDSLog(TICDSLogVerbosityEveryStep, @"WholeStore directory does not exist for this client");
            
            [self beginCopyingThisClientTemporaryWholeStoreDirectoryToThisClientWholeStoreDirectory];
            return;
    }
}

#pragma mark Overridden Method
- (void)checkWhetherThisClientWholeStoreDirectoryExists
{
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeMethodNotOverriddenBySubclass classAndMethod:__PRETTY_FUNCTION__]];
    [self discoveredStatusOfThisClientWholeStoreDirectory:TICDSRemoteFileStructureExistsResponseTypeError];
}

#pragma mark - Deleting Non-Temporary WholeStore Directory
- (void)beginDeletingThisClientWholeStoreDirectory
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachOperationPhase, @"Checking whether this client's temporary WholeStore directory exists");
    
    [self deleteThisClientWholeStoreDirectory];
}

- (void)deletedThisClientWholeStoreDirectoryWithSuccess:(BOOL)success
{
    if( !success ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Failed to delete this client's  WholeStore directory");
        [self operationDidFailToComplete];
        return;
    }
    
    [self beginCopyingThisClientTemporaryWholeStoreDirectoryToThisClientWholeStoreDirectory];
}

#pragma mark Overridden Method
- (void)deleteThisClientWholeStoreDirectory
{
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeMethodNotOverriddenBySubclass classAndMethod:__PRETTY_FUNCTION__]];
    [self deletedThisClientWholeStoreDirectoryWithSuccess:NO];
}

#pragma mark - Copying Temporary WholeStore to WholeStore Directory
- (void)beginCopyingThisClientTemporaryWholeStoreDirectoryToThisClientWholeStoreDirectory
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachOperationPhase, @"Copying this client's temporary WholeStore directory to the non-temporary directory");
    
    [self copyThisClientTemporaryWholeStoreDirectoryToThisClientWholeStoreDirectory];
}

- (void)copiedThisClientTemporaryWholeStoreDirectoryToThisClientWholeStoreDirectoryWithSuccess:(BOOL)success
{
    if( !success ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Failed to copy this client's  WholeStore directory");
        [self operationDidFailToComplete];
        return;
    }
    
    TICDSLog(TICDSLogVerbosityStartAndEndOfMainOperationPhase, @"Finished copying WholeStore directory");
    
    [self operationDidCompleteSuccessfully];
}

#pragma mark Overridden Method
- (void)copyThisClientTemporaryWholeStoreDirectoryToThisClientWholeStoreDirectory
{
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeMethodNotOverriddenBySubclass classAndMethod:__PRETTY_FUNCTION__]];
    [self copiedThisClientTemporaryWholeStoreDirectoryToThisClientWholeStoreDirectoryWithSuccess:NO];
}

#pragma mark - Configuration
- (void)configureBackgroundApplicationContextForPrimaryManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
    self.primaryManagedObjectContext = managedObjectContext;
}

#pragma mark - Initialization and Deallocation
- (void)dealloc
{
    _localWholeStoreFileLocation = nil;
    _localAppliedSyncChangeSetsFileLocation = nil;
    _backgroundApplicationContext = nil;

}

- (NSManagedObjectContext *)backgroundApplicationContext
{
    if ( _backgroundApplicationContext ) {
        return _backgroundApplicationContext;
    }

    _backgroundApplicationContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    [_backgroundApplicationContext performBlockAndWait:^{
         _backgroundApplicationContext.parentContext = self.primaryManagedObjectContext;
         [_backgroundApplicationContext setUndoManager:nil];
     }];

    [[NSNotificationCenter defaultCenter] addObserver:[self delegate] selector:@selector(backgroundManagedObjectContextDidSave:) name:NSManagedObjectContextDidSaveNotification object:_backgroundApplicationContext];

    return _backgroundApplicationContext;
}

#pragma mark - Properties
@synthesize localWholeStoreFileLocation = _localWholeStoreFileLocation;
@synthesize localAppliedSyncChangeSetsFileLocation = _localAppliedSyncChangeSetsFileLocation;
//@synthesize primaryPersistentStoreCoordinator = _primaryPersistentStoreCoordinator;
@synthesize backgroundApplicationContext = _backgroundApplicationContext;

@end
