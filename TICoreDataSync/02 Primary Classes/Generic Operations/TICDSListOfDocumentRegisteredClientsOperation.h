//
//  TICDSListOfDocumentRegisteredClientsOperation.h
//  Notebook
//
//  Created by Tim Isted on 23/05/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICDSOperation.h"

/** The `TICDSListOfDocumentRegisteredClientsOperation` class describes a generic operation used by the `TICoreDataSync` framework to fetch a list of the client devices that are registered to synchronize a given document.
 
 The operation carries out the following tasks:
 
 1. Fetch a list of UUID identifiers of client directories inside the document's `SyncChanges` directory.
 2. Fetch the `deviceInfo.plist` file for each registered client.
 3. Fetch the last modified date of each client's `RecentSync` file, if it exists.
 3. Fetch the last modified date of each client's `WholeStore` upload, if it exists.
 
 Operations are typically created automatically by the relevant sync manager.
 
 @warning You must use one of the subclasses of `TICDSListOfDocumentRegisteredClientsOperation`. */

@interface TICDSListOfDocumentRegisteredClientsOperation : TICDSOperation {
@private
    NSArray *_synchronizedClientIdentifiers;
    NSMutableDictionary *_temporaryDeviceInfoDictionaries;
    NSDictionary *_deviceInfoDictionaries;
    
    NSUInteger _numberOfDeviceInfoDictionariesToFetch;
    NSUInteger _numberOfDeviceInfoDictionariesFetched;
    NSUInteger _numberOfDeviceInfoDictionariesThatFailedToFetch;
    
    NSUInteger _numberOfLastSynchronizationDatesToFetch;
    NSUInteger _numberOfLastSynchronizationDatesFetched;
    NSUInteger _numberOfLastSynchronizationDatesThatFailedToFetch;
    
    NSUInteger _numberOfWholeStoreDatesToFetch;
    NSUInteger _numberOfWholeStoreDatesFetched;
    NSUInteger _numberOfWholeStoreDatesThatFailedToFetch;
}

#pragma mark - Overridden Methods
/** @name Overridden Methods */

/** Fetch an array of UUID strings for each client registered to synchronize this document (the names of the directories inside the document's `SyncChanges` directory.
 
 This method must call `fetchedArrayOfClientUUIDStrings:` when finished. */
- (void)fetchArrayOfClientUUIDStrings;

/** Fetch the `deviceInfo.plist`, decrypting it if necessary, for the specified client.
 
 This method must call `fetchedDeviceInfoDictionary:forClientWithIdentifier:` when finished.
 
 @param anIdentifier The UUID synchronization identifier of the client. */
- (void)fetchDeviceInfoDictionaryForClientWithIdentifier:(NSString *)anIdentifier;

/** Fetch the last modified dates of each client's `RecentSync` file.
 
 This method must call `fetchedLastSynchronizationDate:forClientWithIdentifier:` once per client in `synchronizedClientIdentifiers` to provide the information. */
- (void)fetchLastSynchronizationDates;

/** Fetch the last modified dates for the specified client's `WholeStore` file.
 
 This method must call `fetchedModificationDate:ofWholeStoreForClientWithIdentifier:` when finished.
 
 @param anIdentifier The UUID synchronization identifier of the client. */
- (void)fetchModificationDateOfWholeStoreForClientWithIdentifier:(NSString *)anIdentifier;

#pragma mark - Callbacks
/** Pass back the assembled `NSArray` of `NSString` client identifiers.
 
 If an error occurred, call `setError:` first, then specify `nil` for `anArray`.
 
 @param anArray The array of identifiers, or `nil` if an error occurred. */
- (void)fetchedArrayOfClientUUIDStrings:(NSArray *)anArray;

/** Pass back the `NSDictionary` built from the contents of the `deviceInfo.plist` for the specified client.
 
 If an error occurred, call `setError:` first, then specify `nil` for `aDictionary`.
 
 @param aDictionary The assembled dictionary of device information.
 @param anIdentifier The UUID synchronization identifier of the client. */
- (void)fetchedDeviceInfoDictionary:(NSDictionary *)aDictionary forClientWithIdentifier:(NSString *)anIdentifier;

/** Pass back the last modified date of the specified client's `RecentSync` file.
 
 If an error occurred, call `setError:` first, then specify `nil` for `aDate`.
 
 @param aDate The last modified date of the `RecentSync` file.
 @param anIdentifier The UUID synchronization identifier of the client. */
- (void)fetchedLastSynchronizationDate:(NSDate *)aDate forClientWithIdentifier:(NSString *)anIdentifier;

/** Pass back the last modified date of the specified client's WholeStore file.
 
 If an error occurred, call `setError:` first, then specify `nil` for `aDate`.
 
 @param aDate The last modified date of the client's `WholeStore` file.
 @param anIdentifier The UUID synchronization identifier of the client. */
- (void)fetchedModificationDate:(NSDate *)aDate ofWholeStoreForClientWithIdentifier:(NSString *)anIdentifier;

#pragma mark - Properties
/** @name Properties */

/** An array used to keep track of the client identifiers while the operation is executing. */
@property (nonatomic, strong) NSArray *synchronizedClientIdentifiers;

/** A mutable dictionary used to keep track of the `deviceInfo.plist` dictionaries for each client while the operation is executing. */
@property (nonatomic, strong) NSMutableDictionary *temporaryDeviceInfoDictionaries;

/** The final dictionary of `deviceInfo.plist` dictionaries for each client once the operation has finished. */
@property (strong) NSDictionary *deviceInfoDictionaries;

@end
