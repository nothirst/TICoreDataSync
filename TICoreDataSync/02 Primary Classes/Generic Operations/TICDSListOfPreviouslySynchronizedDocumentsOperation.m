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
- (void)beginFetchOfDocumentInfoDictionaries;
- (void)beginFetchOfLastSynchronizationDates;
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

#pragma mark - List of Document Sync IDs
- (void)beginFetchOfListOfDocumentSyncIDs
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfMainOperationPhase, @"Starting to fetch list of document sync identifiers");
    
    [self buildArrayOfDocumentIdentifiers];
}

- (void)builtArrayOfDocumentIdentifiers:(NSArray *)anArray
{
    if( !anArray ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Error fetching list of document sync identifiers");
        [self operationDidFailToComplete];
        return;
    }
    
    if( [anArray count] < 1 ) {
        TICDSLog(TICDSLogVerbosityStartAndEndOfMainOperationPhase, @"No documents were found");
        [self setAvailableDocuments:[NSArray array]];
        [self operationDidCompleteSuccessfully];
        return;
    }
    
    TICDSLog(TICDSLogVerbosityEveryStep, @"Fetched list of document sync identifiers successfully");
    
    [self setAvailableDocumentSyncIDs:anArray];
    [self beginFetchOfDocumentInfoDictionaries];
}

#pragma mark Overridden Method
- (void)buildArrayOfDocumentIdentifiers
{
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeMethodNotOverriddenBySubclass classAndMethod:__PRETTY_FUNCTION__]];
    [self builtArrayOfDocumentIdentifiers:nil];
}

#pragma mark - Document Info Dictionaries
- (void)beginFetchOfDocumentInfoDictionaries
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachOperationPhase, @"Starting to fetch sync ids for each document sync identifier");
    
    [self setAvailableDocuments:[NSMutableArray arrayWithCapacity:[[self availableDocumentSyncIDs] count]]];
        
    [self setNumberOfInfoDictionariesToFetch:[[self availableDocumentSyncIDs] count]];
    
    for( NSString *eachSyncID in [self availableDocumentSyncIDs] ) {
        [self fetchInfoDictionaryForDocumentWithSyncID:eachSyncID];
    }
}

- (void)fetchedInfoDictionary:(NSDictionary *)anInfoDictionary forDocumentWithSyncID:(NSString *)aSyncID
{
    if( !anInfoDictionary ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Failed to fetch a document info dictionary");
        [self increaseNumberOfInfoDictionariesThatFailedToFetch];
    } else {
        TICDSLog(TICDSLogVerbosityEveryStep, @"Fetched a document info dictionary");
        [self increaseNumberOfInfoDictionariesFetched];
        
        NSMutableDictionary *dictionary = [anInfoDictionary mutableCopy];
        [dictionary setValue:aSyncID forKey:kTICDSDocumentIdentifier];
        [[self availableDocuments] addObject:dictionary];
    }
    
    if( [self numberOfInfoDictionariesToFetch] == [self numberOfInfoDictionariesFetched] ) {
        TICDSLog(TICDSLogVerbosityStartAndEndOfEachOperationPhase, @"Finished fetching info dictionaries");
        [self beginFetchOfLastSynchronizationDates];
    } else if( [self numberOfInfoDictionariesFetched] + [self numberOfInfoDictionariesThatFailedToFetch] == [self numberOfInfoDictionariesToFetch] ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"An error occurred fetching one or more info dictionaries");
        [self operationDidFailToComplete];
        return;
    }
}

#pragma mark Overridden Method
- (void)fetchInfoDictionaryForDocumentWithSyncID:(NSString *)aSyncID
{
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeMethodNotOverriddenBySubclass classAndMethod:__PRETTY_FUNCTION__]];
    
    [self fetchedInfoDictionary:nil forDocumentWithSyncID:aSyncID];
}

#pragma mark - Last Synchronization Date
- (void)beginFetchOfLastSynchronizationDates
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachOperationPhase, @"Starting to fetch last sync dates for each document sync identifier");
    
    [self setNumberOfLastSynchronizationDatesToFetch:[[self availableDocumentSyncIDs] count]];
    
    for( NSString *eachSyncID in [self availableDocumentSyncIDs] ) {
        [self fetchLastSynchronizationDateForDocumentWithSyncID:eachSyncID];
    }
}

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
        TICDSLog(TICDSLogVerbosityStartAndEndOfMainOperationPhase, @"Fetched all last synchronization dates, so operation complete");
        [self operationDidCompleteSuccessfully];
        return;
    } else if( [self numberOfLastSynchronizationDatesToFetch] == [self numberOfLastSynchronizationDatesFetched] + [self numberOfLastSynchronizationDatesThatFailedToFetch] ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"An error occurred fetching one or more last synchronization dates, but last sync dates aren't essential, so continuing...");
        [self operationDidCompleteSuccessfully];
        return;
    }
}

#pragma mark Overridden Method
- (void)fetchLastSynchronizationDateForDocumentWithSyncID:(NSString *)aSyncID
{
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeMethodNotOverriddenBySubclass classAndMethod:__PRETTY_FUNCTION__]];
    
    [self fetchedLastSynchronizationDate:nil forDocumentWithSyncID:aSyncID];
}

#pragma mark - Completion
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

#pragma mark - Initialization and Deallocation
- (void)dealloc
{
    _availableDocuments = nil;
    _availableDocumentSyncIDs = nil;
    
}

#pragma mark - Properties
@synthesize availableDocuments = _availableDocuments;
@synthesize availableDocumentSyncIDs = _availableDocumentSyncIDs;
@synthesize numberOfInfoDictionariesToFetch = _numberOfInfoDictionariesToFetch;
@synthesize numberOfInfoDictionariesFetched = _numberOfInfoDictionariesFetched;
@synthesize numberOfInfoDictionariesThatFailedToFetch = _numberOfInfoDictionariesThatFailedToFetch;
@synthesize numberOfLastSynchronizationDatesToFetch = _numberOfLastSynchronizationDatesToFetch;
@synthesize numberOfLastSynchronizationDatesFetched = _numberOfLastSynchronizationDatesFetched;
@synthesize numberOfLastSynchronizationDatesThatFailedToFetch = _numberOfLastSynchronizationDatesThatFailedToFetch;

@end
