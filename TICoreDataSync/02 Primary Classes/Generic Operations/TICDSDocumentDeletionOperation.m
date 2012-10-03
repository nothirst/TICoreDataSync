//
//  TICDSDocumentDeletionOperation.m
//  Notebook
//
//  Created by Tim Isted on 29/05/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICoreDataSync.h"

@interface TICDSDocumentDeletionOperation ()

- (void)beginCheckingForIdentifiedDocumentDirectory;
- (void)beginCheckingForExistingIdentifierPlistInDeletedDocumentsDirectory;
- (void)beginDeletingIdentifierPlistFromDeletedDocumentsDirectory;
- (void)beginCopyingDocumentInfoPlistToDeletedDocumentsDirectory;
- (void)beginAlertToDelegateThatDocumentWillBeDeleted;
- (void)beginDeletingDocumentDirectory;
- (void)beginAlertToDelegateThatDocumentWasDeleted;

@end

@implementation TICDSDocumentDeletionOperation

- (void)main
{
    [self beginCheckingForIdentifiedDocumentDirectory];
}

#pragma mark - Document Existence
- (void)beginCheckingForIdentifiedDocumentDirectory
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachOperationPhase, @"Checking whether the identified document directory (%@) exists", [self documentIdentifier]);
    
    [self checkWhetherIdentifiedDocumentDirectoryExists];
}

- (void)discoveredStatusOfIdentifiedDocumentDirectory:(TICDSRemoteFileStructureExistsResponseType)status
{
    switch( status ) {
        case TICDSRemoteFileStructureExistsResponseTypeError:
            TICDSLog(TICDSLogVerbosityErrorsOnly, @"Error checking whether the identified document directory exists");
            [self operationDidFailToComplete];
            return;
            
        case TICDSRemoteFileStructureExistsResponseTypeDoesExist:
            TICDSLog(TICDSLogVerbosityEveryStep, @"Document directory exists");
            
            [self beginCheckingForExistingIdentifierPlistInDeletedDocumentsDirectory];
            return;
            
        case TICDSRemoteFileStructureExistsResponseTypeDoesNotExist:
            TICDSLog(TICDSLogVerbosityEveryStep, @"Document directory does not exist");
            
            [self setDocumentWasFoundAndDeleted:NO];
            [self operationDidCompleteSuccessfully];
            return;
    }
}

#pragma mark Overridden Method
- (void)checkWhetherIdentifiedDocumentDirectoryExists
{
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeMethodNotOverriddenBySubclass classAndMethod:__PRETTY_FUNCTION__]];
    [self discoveredStatusOfIdentifiedDocumentDirectory:TICDSRemoteFileStructureExistsResponseTypeError];
}

#pragma mark - Checking for Existing UUID.plist in DeletedDocuments
- (void)beginCheckingForExistingIdentifierPlistInDeletedDocumentsDirectory
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachOperationPhase, @"Checking whether the %@.plist file already exists inside the DeletedDocuments directory", [self documentIdentifier]);
    
    [self checkForExistingIdentifierPlistInDeletedDocumentsDirectory];
}

- (void)discoveredStatusOfIdentifierPlistInDeletedDocumentsDirectory:(TICDSRemoteFileStructureExistsResponseType)status
{
    switch( status ) {
        case TICDSRemoteFileStructureExistsResponseTypeError:
            TICDSLog(TICDSLogVerbosityErrorsOnly, @"Error checking whether the plist file already exists");
            [self operationDidFailToComplete];
            return;
            
        case TICDSRemoteFileStructureExistsResponseTypeDoesExist:
            TICDSLog(TICDSLogVerbosityEveryStep, @"Plist file exists");
            
            [self beginDeletingIdentifierPlistFromDeletedDocumentsDirectory];
            return;
            
        case TICDSRemoteFileStructureExistsResponseTypeDoesNotExist:
            TICDSLog(TICDSLogVerbosityEveryStep, @"Plist file does not exist");
            
            [self beginCopyingDocumentInfoPlistToDeletedDocumentsDirectory];
            return;
    }
}

#pragma mark Overridden Method
- (void)checkForExistingIdentifierPlistInDeletedDocumentsDirectory
{
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeMethodNotOverriddenBySubclass classAndMethod:__PRETTY_FUNCTION__]];
    [self discoveredStatusOfIdentifierPlistInDeletedDocumentsDirectory:TICDSRemoteFileStructureExistsResponseTypeError];
}

#pragma mark - Deleting Existing UUID.plist file
- (void)beginDeletingIdentifierPlistFromDeletedDocumentsDirectory
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachOperationPhase, @"Deleting the %@.plist file  inside the DeletedDocuments directory", [self documentIdentifier]);
    
    [self deleteDocumentInfoPlistFromDeletedDocumentsDirectory];
}

- (void)deletedDocumentInfoPlistFromDeletedDocumentsDirectoryWithSuccess:(BOOL)success
{
    if( !success ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Failed to delete documentInfo.plist in the DeletedDocuments directory");
        [self operationDidFailToComplete];
        return;
    }
    
    TICDSLog(TICDSLogVerbosityEveryStep, @"Deleted documentInfo.plist from the DeletedDocuments directory");
    
    [self beginCopyingDocumentInfoPlistToDeletedDocumentsDirectory];
}

#pragma mark Overridden Method
- (void)deleteDocumentInfoPlistFromDeletedDocumentsDirectory
{
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeMethodNotOverriddenBySubclass classAndMethod:__PRETTY_FUNCTION__]];
    [self deletedDocumentDirectoryWithSuccess:NO];
}

#pragma mark - Copying documentInfo.plist to DeletedDocuments
- (void)beginCopyingDocumentInfoPlistToDeletedDocumentsDirectory
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachOperationPhase, @"Copying documentInfo.plist file to DeletedDocuments directory");
    
    [self copyDocumentInfoPlistToDeletedDocumentsDirectory];
}

- (void)copiedDocumentInfoPlistToDeletedDocumentsDirectoryWithSuccess:(BOOL)success
{
    if( !success ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Failed to copy documentInfo.plist file to the DeletedDocuments directory");
        [self operationDidFailToComplete];
        return;
    }
    
    TICDSLog(TICDSLogVerbosityEveryStep, @"Copied documentInfo.plist to the DeletedDocuments directory");
    
    [self beginAlertToDelegateThatDocumentWillBeDeleted];
}

#pragma mark Overridden Method
- (void)copyDocumentInfoPlistToDeletedDocumentsDirectory
{
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeMethodNotOverriddenBySubclass classAndMethod:__PRETTY_FUNCTION__]];
    [self copiedDocumentInfoPlistToDeletedDocumentsDirectoryWithSuccess:NO];
}

#pragma mark - Alerting the Delegate Before Deletion
- (void)beginAlertToDelegateThatDocumentWillBeDeleted
{
    if ([self ti_delegateRespondsToSelector:@selector(documentDeletionOperationWillDeleteDocument:)]) {
        [self runOnMainQueueWithoutDeadlocking:^{
            [(id)self.delegate documentDeletionOperationWillDeleteDocument:self];
        }];
    }
    
    [self beginDeletingDocumentDirectory];
}

#pragma mark - Deleting the Document
- (void)beginDeletingDocumentDirectory
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfMainOperationPhase, @"Deleting the document from the remote");
    
    [self deleteDocumentDirectory];
}

- (void)deletedDocumentDirectoryWithSuccess:(BOOL)success
{
    if( !success ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Failed to delete document directory");
        [self operationDidFailToComplete];
        return;
    }
    
    TICDSLog(TICDSLogVerbosityEveryStep, @"Deleted document directory");
    
    [self beginAlertToDelegateThatDocumentWasDeleted];
}

#pragma mark Overridden Method
- (void)deleteDocumentDirectory
{
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeMethodNotOverriddenBySubclass classAndMethod:__PRETTY_FUNCTION__]];
    [self deletedDocumentDirectoryWithSuccess:NO];
}

#pragma mark - Alerting the Delegate After Deletion
- (void)beginAlertToDelegateThatDocumentWasDeleted
{
    if ([self ti_delegateRespondsToSelector:@selector(documentDeletionOperationDidDeleteDocument:)]) {
        [self runOnMainQueueWithoutDeadlocking:^{
            [(id)self.delegate documentDeletionOperationDidDeleteDocument:self];
        }];
    }

    [self operationDidCompleteSuccessfully];
}

#pragma mark - Initialization and Deallocation
- (id)initWithDelegate:(NSObject<TICDSDocumentDeletionOperationDelegate> *)aDelegate
{
    return [super initWithDelegate:aDelegate];
}

- (void)dealloc
{
    _documentIdentifier = nil;
    
}

#pragma mark - Properties
@synthesize documentIdentifier = _documentIdentifier;
@synthesize documentWasFoundAndDeleted = _documentWasFoundAndDeleted;

@end
