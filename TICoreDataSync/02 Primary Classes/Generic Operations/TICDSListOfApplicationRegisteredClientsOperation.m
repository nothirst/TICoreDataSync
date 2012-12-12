//
//  TICDSListOfApplicationRegisteredClientsOperation.m
//  Notebook
//
//  Created by Tim Isted on 23/05/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICoreDataSync.h"

@interface TICDSListOfApplicationRegisteredClientsOperation ()

- (void)beginFetchingArrayOfClientUUIDStrings;
- (void)beginFetchingDeviceInfoDictionaries;
- (void)beginFetchingArrayOfDocumentUUIDStrings;
- (void)beginFetchingClientIdentifiersRegisteredForEachDocument;

@end

@implementation TICDSListOfApplicationRegisteredClientsOperation

- (void)main
{
    [self beginFetchingArrayOfClientUUIDStrings];
}

#pragma mark - Fetching UUIDs of Clients Registered for this Application
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
        if( [eachIdentifier length] < 5 || [[eachIdentifier substringToIndex:1] isEqualToString:@"."] ) {
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
    
    // TODO: Failure to fetch some clients should be a warning, not an operation failure.
    if( _numberOfDeviceInfoDictionariesFetched == _numberOfDeviceInfoDictionariesToFetch || ( _numberOfDeviceInfoDictionariesFetched + _numberOfDeviceInfoDictionariesThatFailedToFetch == _numberOfDeviceInfoDictionariesToFetch )) {
        TICDSLog(TICDSLogVerbosityStartAndEndOfEachOperationPhase, @"Finished fetching device info dictionaries");
        
        [self setDeviceInfoDictionaries:[self temporaryDeviceInfoDictionaries]];
        
        if( ![self shouldIncludeRegisteredDocuments] ) {
            [self operationDidCompleteSuccessfully];
            return;
        }
        
        [self beginFetchingArrayOfDocumentUUIDStrings];
        
//    } else if( _numberOfDeviceInfoDictionariesFetched + _numberOfDeviceInfoDictionariesThatFailedToFetch == _numberOfDeviceInfoDictionariesToFetch ) {
//        TICDSLog(TICDSLogVerbosityErrorsOnly, @"An error occurred fetching one or more device info dictionaries");
//        [self operationDidFailToComplete];
//        return;
    }
}

#pragma mark Overridden Method
- (void)fetchDeviceInfoDictionaryForClientWithIdentifier:(NSString *)anIdentifier
{
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeMethodNotOverriddenBySubclass classAndMethod:__PRETTY_FUNCTION__]];
    [self fetchedDeviceInfoDictionary:nil forClientWithIdentifier:anIdentifier];
}

#pragma mark - Fetching UUIDs of all Documents
- (void)beginFetchingArrayOfDocumentUUIDStrings
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachOperationPhase, @"Fetching array of registered document UUIDs");
    
    [self fetchArrayOfDocumentUUIDStrings];
}

- (void)fetchedArrayOfDocumentUUIDStrings:(NSArray *)anArray
{
    if( !anArray ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Error fetching array of registered document UUIDs");
        [self operationDidFailToComplete];
        return;
    }
    
    NSMutableArray *documentIdentifiers = [NSMutableArray arrayWithCapacity:[anArray count]];
    for( NSString *eachIdentifier in anArray ) {
        if( [[eachIdentifier substringToIndex:1] isEqualToString:@"."] ) {
            continue;
        }
        
        [documentIdentifiers addObject:eachIdentifier];
    }
    
    [self setSynchronizedDocumentIdentifiers:documentIdentifiers];
    
    
    if( [[self synchronizedDocumentIdentifiers] count] < 1 ) {
        TICDSLog(TICDSLogVerbosityStartAndEndOfMainOperationPhase, @"No documents were found");
        
        [self operationDidCompleteSuccessfully];
        return;
    }
    
    TICDSLog(TICDSLogVerbosityEveryStep, @"Fetched array of registered document UUIDs");
    [self beginFetchingClientIdentifiersRegisteredForEachDocument];
}

#pragma mark Overridden Method
- (void)fetchArrayOfDocumentUUIDStrings
{
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeMethodNotOverriddenBySubclass classAndMethod:__PRETTY_FUNCTION__]];
    [self fetchedArrayOfDocumentUUIDStrings:nil];
}

#pragma mark - Fetching Client Identifiers Registered for Each Document
- (void)beginFetchingClientIdentifiersRegisteredForEachDocument
{
    _numberOfDocumentClientArraysToFetch = [[self synchronizedDocumentIdentifiers] count];
    
    for( NSString *eachIdentifier in [self synchronizedDocumentIdentifiers] ) {
        [self fetchArrayOfClientsRegisteredForDocumentWithIdentifier:eachIdentifier];
    }
}

- (void)fetchedArrayOfClients:(NSArray *)anArray registeredForDocumentWithIdentifier:(NSString *)anIdentifier
{
    if( !anArray ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Failed to fetch an array of clients for document %@", anIdentifier);
        _numberOfDocumentClientArraysThatFailedToFetch++;
    } else {
        TICDSLog(TICDSLogVerbosityEveryStep, @"Fetched an array of clients");
        
        for( NSString *eachClientIdentifier in anArray ) {
            if( [eachClientIdentifier length] < 5 || [[eachClientIdentifier substringToIndex:1] isEqualToString:@"."] ) {
                continue;
            }
            
            NSMutableDictionary *deviceDictionary = [[self temporaryDeviceInfoDictionaries] valueForKey:eachClientIdentifier];
            
            NSMutableArray *documentIdentifiers = [deviceDictionary valueForKey:kTICDSRegisteredDocumentIdentifiers];
            if( !documentIdentifiers ) {
                documentIdentifiers = [NSMutableArray arrayWithCapacity:5];
                [deviceDictionary setValue:documentIdentifiers forKey:kTICDSRegisteredDocumentIdentifiers];
            }
            
            [documentIdentifiers addObject:anIdentifier];
        }
        
        _numberOfDocumentClientArraysFetched++;
    }
    
    if( _numberOfDocumentClientArraysFetched == _numberOfDocumentClientArraysToFetch ) {
        TICDSLog(TICDSLogVerbosityStartAndEndOfMainOperationPhase, @"Finished fetching client identifiers registered for each document");
        [self operationDidCompleteSuccessfully];
        return;
    }
    
    if( _numberOfDocumentClientArraysFetched + _numberOfDocumentClientArraysThatFailedToFetch == _numberOfDocumentClientArraysToFetch ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"One or more registered client arrays failed to fetch, but not fatal so continuing");
        [self operationDidCompleteSuccessfully];
        return;
    }
}

#pragma mark Overridden Method
- (void)fetchArrayOfClientsRegisteredForDocumentWithIdentifier:(NSString *)anIdentifier
{
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeMethodNotOverriddenBySubclass classAndMethod:__PRETTY_FUNCTION__]];
    [self fetchedArrayOfClients:nil registeredForDocumentWithIdentifier:anIdentifier];
}

#pragma mark - Initialization and Deallocation
- (void)dealloc
{
    _synchronizedClientIdentifiers = nil;
    _temporaryDeviceInfoDictionaries = nil;
    _deviceInfoDictionaries = nil;
    _synchronizedDocumentIdentifiers = nil;

}

#pragma mark - Properties
@synthesize synchronizedClientIdentifiers = _synchronizedClientIdentifiers;
@synthesize temporaryDeviceInfoDictionaries = _temporaryDeviceInfoDictionaries;
@synthesize deviceInfoDictionaries = _deviceInfoDictionaries;
@synthesize synchronizedDocumentIdentifiers = _synchronizedDocumentIdentifiers;
@synthesize shouldIncludeRegisteredDocuments = _shouldIncludeRegisteredDocuments;

@end
