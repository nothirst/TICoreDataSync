//
//  TICDSListOfPreviouslySynchronizedDocumentsOperation.m
//  ShoppingListMac
//
//  Created by Tim Isted on 24/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICoreDataSync.h"

@interface TICDSListOfPreviouslySynchronizedDocumentsOperation ()

- (void)beginFetchOfListOfDocumentSyncIDs;
- (void)checkForCompletion;

@end

@implementation TICDSListOfPreviouslySynchronizedDocumentsOperation

- (void)main
{
    [self beginFetchOfListOfDocumentSyncIDs];
}

#pragma mark -
#pragma mark List of Document Sync IDs
- (void)beginFetchOfListOfDocumentSyncIDs
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachPhase, @"Starting to fetch list of document sync identifiers");
    
    [self buildArrayOfDocumentIdentifiers];
}

- (void)builtArrayOfDocumentIdentifiers:(NSArray *)anArray
{
    if( !anArray ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Error fetching list of document sync identifiers");
        [self setArrayOfDocumentIdentifiersStatus:TICDSOperationPhaseStatusFailure];
        [self setInfoDictionariesStatus:TICDSOperationPhaseStatusFailure];
    }
    
    [self checkForCompletion];
}

#pragma mark Overridden Methods
- (void)buildArrayOfDocumentIdentifiers
{
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeMethodNotOverriddenBySubclass classAndMethod:__PRETTY_FUNCTION__]];
    [self builtArrayOfDocumentIdentifiers:nil];
}

#pragma mark -
#pragma mark Completion
- (void)checkForCompletion
{
    if( [self completionInProgress] ) {
        return;
    }
    
    if( [self arrayOfDocumentIdentifiersStatus] == TICDSOperationPhaseStatusInProgress || [self infoDictionariesStatus] == TICDSOperationPhaseStatusInProgress ) {
        return;
    }
    
    if( [self arrayOfDocumentIdentifiersStatus] == TICDSOperationPhaseStatusSuccess && [self infoDictionariesStatus] == TICDSOperationPhaseStatusSuccess ) {
        [self setCompletionInProgress:YES];
        
        [self operationDidCompleteSuccessfully];
        return;
    }
    
    if( [self arrayOfDocumentIdentifiersStatus] == TICDSOperationPhaseStatusFailure || [self infoDictionariesStatus] == TICDSOperationPhaseStatusFailure ) {
        [self setCompletionInProgress:YES];
        
        [self operationDidFailToComplete];
        return;
    }
}

#pragma mark -
#pragma mark Initialization and Deallocation
- (void)dealloc
{
    [_availableDocuments release], _availableDocuments = nil;
    
    [super dealloc];
}

#pragma mark -
#pragma mark Properties
@synthesize availableDocuments = _availableDocuments;
@synthesize completionInProgress = _completionInProgress;
@synthesize arrayOfDocumentIdentifiersStatus = _arrayOfDocumentIdentifiersStatus;
@synthesize infoDictionariesStatus = _infoDictionariesStatus;

@end
