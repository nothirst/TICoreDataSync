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
            
            [self beginCopyingDocumentInfoPlistToDeletedDocumentsDirectory];
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
    [self ti_alertDelegateOnMainThreadWithSelector:@selector(documentDeletionOperationWillDeleteDocument:) waitUntilDone:YES];
    
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
    [self ti_alertDelegateOnMainThreadWithSelector:@selector(documentDeletionOperationDidDeleteDocument:) waitUntilDone:YES];
    
    [self operationDidCompleteSuccessfully];
}

#pragma mark -
#pragma mark Initialization and Deallocation
- (void)dealloc
{
    [_documentIdentifier release], _documentIdentifier = nil;
    
    [super dealloc];
}

#pragma mark -
#pragma mark Properties
@synthesize documentIdentifier = _documentIdentifier;
@synthesize documentWasFoundAndDeleted = _documentWasFoundAndDeleted;

@end
