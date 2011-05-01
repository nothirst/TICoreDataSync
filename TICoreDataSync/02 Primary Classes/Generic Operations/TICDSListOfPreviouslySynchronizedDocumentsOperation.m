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
- (void)beginFetchOfDocumentInfoDictionariesForSyncIDs:(NSArray *)syncIDs;
- (void)checkForCompletion;
- (void)increaseNumberOfInfoDictionariesToFetch;
- (void)increaseNumberOfInfoDictionariesFetched;
- (void)increaseNumberOfInfoDictionariesThatFailedToFetch;
- (void)increaseNumberOfLastSynchronizationDatesToFetch;
- (void)increaseNumberOfLastSynchronizationDatesFetched;
- (void)increaseNumberOfLastSynchronizationDatesThatFailedToFetch;

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
    TICDSLog(TICDSLogVerbosityStartAndEndOfMainOperationPhase, @"Starting to fetch list of document sync identifiers");
    
    [self buildArrayOfDocumentIdentifiers];
}

- (void)builtArrayOfDocumentIdentifiers:(NSArray *)anArray
{
    if( !anArray ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Error fetching list of document sync identifiers");
        [self setArrayOfDocumentIdentifiersStatus:TICDSOperationPhaseStatusFailure];
        [self setInfoDictionariesStatus:TICDSOperationPhaseStatusFailure];
        [self setLastSynchronizationDatesStatus:TICDSOperationPhaseStatusFailure];
    } else {
        TICDSLog(TICDSLogVerbosityEveryStep, @"Fetched list of document sync identifiers successfully");
        [self setArrayOfDocumentIdentifiersStatus:TICDSOperationPhaseStatusSuccess];
        [self beginFetchOfDocumentInfoDictionariesForSyncIDs:anArray];
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
#pragma mark Document Info Dictionaries
- (void)beginFetchOfDocumentInfoDictionariesForSyncIDs:(NSArray *)syncIDs
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachOperationPhase, @"Starting to fetch sync ids for each document sync identifier");
    
    [self setAvailableDocuments:[NSMutableArray arrayWithCapacity:[syncIDs count]]];
        
    if( [syncIDs count] < 1 ) {
        [self setInfoDictionariesStatus:TICDSOperationPhaseStatusSuccess];
        [self setLastSynchronizationDatesStatus:TICDSOperationPhaseStatusSuccess];
        TICDSLog(TICDSLogVerbosityStartAndEndOfMainOperationPhase, @"No documents available");
        [self checkForCompletion];
        return;
    }
    
    [self setNumberOfInfoDictionariesToFetch:[syncIDs count]];
    [self setNumberOfLastSynchronizationDatesToFetch:[syncIDs count]];
    [self fetchInfoDictionariesForDocumentsWithSyncIDs:syncIDs];
}

- (void)fetchedInfoDictionary:(NSDictionary *)anInfoDictionary forDocumentWithSyncID:(NSString *)aSyncID
{
    if( !anInfoDictionary ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Failed to fetch a document info dictionary");
        [self increaseNumberOfInfoDictionariesThatFailedToFetch];
        [self increaseNumberOfLastSynchronizationDatesThatFailedToFetch];
    } else {
        TICDSLog(TICDSLogVerbosityEveryStep, @"Fetched a document info dictionary");
        [self increaseNumberOfInfoDictionariesFetched];
        
        NSMutableDictionary *dictionary = [anInfoDictionary mutableCopy];
        [dictionary setValue:aSyncID forKey:kTICDSDocumentIdentifier];
        [[self availableDocuments] addObject:dictionary];
        [dictionary release];
        
        [self fetchLastSynchronizationDateForDocumentWithSyncID:aSyncID];
    }
    
    if( [self numberOfInfoDictionariesToFetch] == [self numberOfInfoDictionariesFetched] ) {
        [self setInfoDictionariesStatus:TICDSOperationPhaseStatusSuccess];
    } else if( [self numberOfInfoDictionariesFetched] + [self numberOfInfoDictionariesThatFailedToFetch] == [self numberOfInfoDictionariesToFetch] ) {
        [self setInfoDictionariesStatus:TICDSOperationPhaseStatusFailure];
        [self setLastSynchronizationDatesStatus:TICDSOperationPhaseStatusFailure];
    }
    
    [self checkForCompletion];
}

#pragma mark Overridden Methods
- (void)fetchInfoDictionariesForDocumentsWithSyncIDs:(NSArray *)syncIDs
{
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeMethodNotOverriddenBySubclass classAndMethod:__PRETTY_FUNCTION__]];
    
    for( NSString *eachSyncID in syncIDs ) {
        [self fetchedInfoDictionary:nil forDocumentWithSyncID:eachSyncID];
    }
}

#pragma mark -
#pragma mark Last Synchronization Date
- (void)fetchedLastSynchronizationDate:(NSDate *)aDate forDocumentWithSyncID:(NSString *)aSyncID
{
    if( !aDate ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Failed to fetch a last synchronization date");
        [self increaseNumberOfLastSynchronizationDatesThatFailedToFetch];
    } else {
        TICDSLog(TICDSLogVerbosityEveryStep, @"Fetched a last synchronization date");
        [self increaseNumberOfLastSynchronizationDatesFetched];
        
        for( NSMutableDictionary *eachDictionary in [self availableDocuments] ) {
            if( ![[eachDictionary valueForKey:kTICDSDocumentIdentifier] isEqualToString:aSyncID] ) {
                continue;
            }
            
            [eachDictionary setValue:aDate forKey:kTICDSLastSyncDate];
        }
    }
    
    if( [self numberOfLastSynchronizationDatesToFetch] == [self numberOfLastSynchronizationDatesFetched] ) {
        [self setLastSynchronizationDatesStatus:TICDSOperationPhaseStatusSuccess];
    } else if( [self numberOfLastSynchronizationDatesToFetch] == [self numberOfLastSynchronizationDatesFetched] + [self numberOfLastSynchronizationDatesThatFailedToFetch] ) {
        [self setLastSynchronizationDatesStatus:TICDSOperationPhaseStatusFailure];
    }
    
    [self checkForCompletion];
}

#pragma mark Overridden Methods
- (void)fetchLastSynchronizationDateForDocumentWithSyncID:(NSString *)aSyncID
{
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeMethodNotOverriddenBySubclass classAndMethod:__PRETTY_FUNCTION__]];
    
    [self fetchedLastSynchronizationDate:nil forDocumentWithSyncID:aSyncID];
}

#pragma mark -
#pragma mark Completion
- (void)checkForCompletion
{
    if( [self completionInProgress] ) {
        return;
    }
    
    if( [self arrayOfDocumentIdentifiersStatus] == TICDSOperationPhaseStatusInProgress || [self infoDictionariesStatus] == TICDSOperationPhaseStatusInProgress || [self lastSynchronizationDatesStatus] == TICDSOperationPhaseStatusInProgress ) {
        return;
    }
    
    if( [self arrayOfDocumentIdentifiersStatus] == TICDSOperationPhaseStatusSuccess && [self infoDictionariesStatus] == TICDSOperationPhaseStatusSuccess && [self lastSynchronizationDatesStatus] == TICDSOperationPhaseStatusSuccess ) {
        [self setCompletionInProgress:YES];
        
        [self operationDidCompleteSuccessfully];
        return;
    }
    
    if( [self arrayOfDocumentIdentifiersStatus] == TICDSOperationPhaseStatusFailure || [self infoDictionariesStatus] == TICDSOperationPhaseStatusFailure || [self lastSynchronizationDatesStatus] == TICDSOperationPhaseStatusFailure ) {
        [self setCompletionInProgress:YES];
        
        [self operationDidFailToComplete];
        return;
    }
}

- (void)increaseNumberOfInfoDictionariesToFetch
{
    [self setNumberOfInfoDictionariesToFetch:[self numberOfInfoDictionariesToFetch] + 1];
}

- (void)increaseNumberOfInfoDictionariesFetched
{
    [self setNumberOfInfoDictionariesFetched:[self numberOfInfoDictionariesFetched] + 1];
}

- (void)increaseNumberOfInfoDictionariesThatFailedToFetch
{
    [self setNumberOfInfoDictionariesThatFailedToFetch:[self numberOfInfoDictionariesThatFailedToFetch] + 1];
}

- (void)increaseNumberOfLastSynchronizationDatesToFetch
{
    [self setNumberOfLastSynchronizationDatesToFetch:[self numberOfLastSynchronizationDatesToFetch] + 1];
}

- (void)increaseNumberOfLastSynchronizationDatesFetched
{
    [self setNumberOfLastSynchronizationDatesFetched:[self numberOfLastSynchronizationDatesFetched] + 1];
}

- (void)increaseNumberOfLastSynchronizationDatesThatFailedToFetch
{
    [self setNumberOfLastSynchronizationDatesThatFailedToFetch:[self numberOfLastSynchronizationDatesThatFailedToFetch] + 1];
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
@synthesize numberOfInfoDictionariesToFetch = _numberOfInfoDictionariesToFetch;
@synthesize numberOfInfoDictionariesFetched = _numberOfInfoDictionariesFetched;
@synthesize numberOfInfoDictionariesThatFailedToFetch = _numberOfInfoDictionariesThatFailedToFetch;
@synthesize numberOfLastSynchronizationDatesToFetch = _numberOfLastSynchronizationDatesToFetch;
@synthesize numberOfLastSynchronizationDatesFetched = _numberOfLastSynchronizationDatesFetched;
@synthesize numberOfLastSynchronizationDatesThatFailedToFetch = _numberOfLastSynchronizationDatesThatFailedToFetch;
@synthesize lastSynchronizationDatesStatus = _lastSynchronizationDatesStatus;

@end
