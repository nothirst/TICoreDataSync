//
//  TICDSListOfDocumentRegisteredClientsOperation.m
//  Notebook
//
//  Created by Tim Isted on 23/05/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICoreDataSync.h"

@interface TICDSListOfDocumentRegisteredClientsOperation ()

- (void)beginFetchingArrayOfClientUUIDStrings;
- (void)beginFetchingDeviceInfoDictionaries;
- (void)beginFetchingLastSynchronizationDates;
- (void)beginFetchingUploadedWholeStoreDates;

@end

@implementation TICDSListOfDocumentRegisteredClientsOperation

- (void)main
{
    [self beginFetchingArrayOfClientUUIDStrings];
}

#pragma mark - Fetching UUIDs of Clients Registered for this Document
- (void)beginFetchingArrayOfClientUUIDStrings
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfMainOperationPhase, @"Fetching array of registered client UUIDs");
    [self fetchArrayOfClientUUIDStrings];
}

- (void)fetchedArrayOfClientUUIDStrings:(NSArray *)anArray
{
    if( !anArray ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Error fetching array of registered client UUIDs");
        [self operationDidFailToComplete];
        return;
    }
    
    NSMutableArray *clientIdentifiers = [NSMutableArray arrayWithCapacity:[anArray count]];
    for( NSString *eachIdentifier in anArray ) {
        if( [eachIdentifier length] < 5 ) {
            continue;
        }
        
        [clientIdentifiers addObject:eachIdentifier];
    }
    [self setSynchronizedClientIdentifiers:clientIdentifiers];
    
    if( [[self synchronizedClientIdentifiers] count] < 1 ) {
        TICDSLog(TICDSLogVerbosityStartAndEndOfMainOperationPhase, @"No clients were found");
        
        [self setDeviceInfoDictionaries:[NSDictionary dictionary]];
        [self operationDidCompleteSuccessfully];
        return;
    }
    
    TICDSLog(TICDSLogVerbosityEveryStep, @"Fetched array of registered client UUIDs");
    
    [self beginFetchingDeviceInfoDictionaries];
}

#pragma mark Overridden Method
- (void)fetchArrayOfClientUUIDStrings
{
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeMethodNotOverriddenBySubclass classAndMethod:__PRETTY_FUNCTION__]];
    [self fetchedArrayOfClientUUIDStrings:nil];
}

#pragma mark - Fetching deviceInfo.plist Dictionaries
- (void)beginFetchingDeviceInfoDictionaries
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachOperationPhase, @"Starting to fetch all deviceInfo.plist dictionaries");
    
    _numberOfDeviceInfoDictionariesToFetch = [[self synchronizedClientIdentifiers] count];
    
    [self setTemporaryDeviceInfoDictionaries:[NSMutableDictionary dictionaryWithCapacity:_numberOfDeviceInfoDictionariesToFetch]];
    
    for( NSString *eachSyncID in [self synchronizedClientIdentifiers] ) {
        [self fetchDeviceInfoDictionaryForClientWithIdentifier:eachSyncID];
    }
}

- (void)fetchedDeviceInfoDictionary:(NSDictionary *)aDictionary forClientWithIdentifier:(NSString *)anIdentifier
{
    if( !aDictionary ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Failed to fetch a device info dictionary");
        _numberOfDeviceInfoDictionariesThatFailedToFetch++;
    } else {
        TICDSLog(TICDSLogVerbosityEveryStep, @"Fetched a device info dictionary");
        _numberOfDeviceInfoDictionariesFetched++;
        
        NSMutableDictionary *dictionary = [aDictionary mutableCopy];
        [[self temporaryDeviceInfoDictionaries] setValue:dictionary forKey:anIdentifier];
    }
    
    if( _numberOfDeviceInfoDictionariesFetched == _numberOfDeviceInfoDictionariesToFetch ) {
        TICDSLog(TICDSLogVerbosityStartAndEndOfEachOperationPhase, @"Finished fetching device info dictionaries");
        [self beginFetchingLastSynchronizationDates];
    } else if( _numberOfDeviceInfoDictionariesFetched + _numberOfDeviceInfoDictionariesThatFailedToFetch == _numberOfDeviceInfoDictionariesToFetch ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"An error occurred fetching one or more device info dictionaries");
        [self operationDidFailToComplete];
        return;
    }
}

#pragma mark Overridden Method
- (void)fetchDeviceInfoDictionaryForClientWithIdentifier:(NSString *)anIdentifier
{
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeMethodNotOverriddenBySubclass classAndMethod:__PRETTY_FUNCTION__]];
    [self fetchedDeviceInfoDictionary:nil forClientWithIdentifier:anIdentifier];
}

#pragma mark - Last Synchronization Dates
- (void)beginFetchingLastSynchronizationDates
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachOperationPhase, @"Fetching the last sync dates for all registered clients");
    _numberOfLastSynchronizationDatesToFetch = [[self synchronizedClientIdentifiers] count];
    [self fetchLastSynchronizationDates];
}

- (void)fetchedLastSynchronizationDate:(NSDate *)aDate forClientWithIdentifier:(NSString *)anIdentifier
{
    if( !aDate ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Failed to fetch a client's last sync date");
        _numberOfLastSynchronizationDatesThatFailedToFetch++;
    } else {
        TICDSLog(TICDSLogVerbosityEveryStep, @"Fetched a client's last sync date");
        [[[self temporaryDeviceInfoDictionaries] valueForKey:anIdentifier] setValue:aDate forKey:kTICDSLastSyncDate];
        _numberOfLastSynchronizationDatesFetched++;
    }
    
    if( _numberOfLastSynchronizationDatesFetched == _numberOfLastSynchronizationDatesToFetch ) {
        TICDSLog(TICDSLogVerbosityStartAndEndOfEachOperationPhase, @"Finished fetching last sync dates");
        [self beginFetchingUploadedWholeStoreDates];
    } else if( _numberOfLastSynchronizationDatesFetched + _numberOfLastSynchronizationDatesThatFailedToFetch == _numberOfLastSynchronizationDatesToFetch ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"One or more last sync dates failed to fetch, which isn't fatal, so continuing");
        [self beginFetchingUploadedWholeStoreDates];
    }
}

#pragma mark Overridden Method
- (void)fetchLastSynchronizationDates
{
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeMethodNotOverriddenBySubclass classAndMethod:__PRETTY_FUNCTION__]];
    for( NSString *eachIdentifier in [self synchronizedClientIdentifiers] ) {
        [self fetchedLastSynchronizationDate:nil forClientWithIdentifier:eachIdentifier];
    }
}

#pragma mark - Fetching Whole Store Dates
- (void)beginFetchingUploadedWholeStoreDates
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachOperationPhase, @"Fetching the modification dates of each client's uploaded whole store");
    
    _numberOfWholeStoreDatesToFetch = [[self synchronizedClientIdentifiers] count];
    for( NSString *eachIdentifier in [self synchronizedClientIdentifiers] ) {
        [self fetchModificationDateOfWholeStoreForClientWithIdentifier:eachIdentifier];
    }
}

- (void)fetchedModificationDate:(NSDate *)aDate ofWholeStoreForClientWithIdentifier:(NSString *)anIdentifier
{
    if( !aDate ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Failed to fetch a last modified date of a client's WholeStore file");
        _numberOfWholeStoreDatesThatFailedToFetch++;
    } else {
        TICDSLog(TICDSLogVerbosityEveryStep, @"Fetched a last modified date of a client's WholeStore file");
        _numberOfWholeStoreDatesFetched++;
        [[[self temporaryDeviceInfoDictionaries] valueForKey:anIdentifier] setValue:aDate forKey:kTICDSUploadedWholeStoreModificationDate];
    }
    
    if( _numberOfWholeStoreDatesFetched + _numberOfWholeStoreDatesThatFailedToFetch < _numberOfWholeStoreDatesToFetch ) {
        return;
    }
    
    if( _numberOfWholeStoreDatesFetched == _numberOfWholeStoreDatesToFetch ) {
        TICDSLog(TICDSLogVerbosityStartAndEndOfMainOperationPhase, @"Finished fetching last modified dates of WholeStore files");
    } else if( _numberOfWholeStoreDatesFetched + _numberOfWholeStoreDatesThatFailedToFetch == _numberOfWholeStoreDatesToFetch ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"One or more last modified dates failed to fetch, but not fatal so continuing");
    }
    
    [self setDeviceInfoDictionaries:[self temporaryDeviceInfoDictionaries]];
    [self operationDidCompleteSuccessfully];
}

#pragma mark Overridden Method
- (void)fetchModificationDateOfWholeStoreForClientWithIdentifier:(NSString *)anIdentifier
{
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeMethodNotOverriddenBySubclass classAndMethod:__PRETTY_FUNCTION__]];
    [self fetchedModificationDate:nil ofWholeStoreForClientWithIdentifier:anIdentifier];
}

#pragma mark - Initialization and Deallocation
- (void)dealloc
{
    _synchronizedClientIdentifiers = nil;
    _temporaryDeviceInfoDictionaries = nil;
    _deviceInfoDictionaries = nil;

}

#pragma mark - Properties
@synthesize synchronizedClientIdentifiers = _synchronizedClientIdentifiers;
@synthesize temporaryDeviceInfoDictionaries = _temporaryDeviceInfoDictionaries;
@synthesize deviceInfoDictionaries = _deviceInfoDictionaries;

@end
