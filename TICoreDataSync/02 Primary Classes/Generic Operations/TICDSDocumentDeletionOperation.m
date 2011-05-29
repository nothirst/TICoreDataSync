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
    
    [self checkWhetherIdentifiedDocumentDirectoryExists:[self documentIdentifier]];
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
            
            //[self beginCopyingDocumentInfoPlistFileToDeletedDocumentsDirectory];
            return;
            
        case TICDSRemoteFileStructureExistsResponseTypeDoesNotExist:
            TICDSLog(TICDSLogVerbosityEveryStep, @"Document directory does not exist");
            
            [self setDocumentWasFoundAndDeleted:NO];
            [self operationDidCompleteSuccessfully];
            return;
    }
}

#pragma mark Overridden Method
- (void)checkWhetherIdentifiedDocumentDirectoryExists:(NSString *)anIdentifier
{
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeMethodNotOverriddenBySubclass classAndMethod:__PRETTY_FUNCTION__]];
    [self discoveredStatusOfIdentifiedDocumentDirectory:TICDSRemoteFileStructureExistsResponseTypeError];
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
