//
//  TICDSListOfApplicationRegisteredClientsOperation.h
//  Notebook
//
//  Created by Tim Isted on 23/05/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICDSOperation.h"

/** The `TICDSListOfApplicationRegisteredClientsOperation` class describes a generic operation used by the `TICoreDataSync` framework to fetch a list of the client devices that are registered to synchronize with the application.
 
 The operation carries out the following tasks:
 
 1. Fetch a list of UUID identifiers of all registered clients from the application's `ClientDevices` directory.
 2. Fetch the `deviceInfo.plist` file for each registered client.
 3. Optionally fetch a list of document UUID identifiers and add a `registeredDocuments` key to each device dictionary, with the value being an array of document identifiers, indicating the documents that the client has registered to synchronize.
 
 Operations are typically created automatically by the relevant sync manager.
 
 @warning You must use one of the subclasses of `TICDSListOfApplicationRegisteredClientsOperation`. */

@interface TICDSListOfApplicationRegisteredClientsOperation : TICDSOperation {
@private
    NSMutableArray *_synchronizedClientIdentifiers;
    NSMutableDictionary *_temporaryDeviceInfoDictionaries;
    NSDictionary *_deviceInfoDictionaries;
    NSMutableArray *_synchronizedDocumentIdentifiers;
    
    NSUInteger _numberOfDeviceInfoDictionariesToFetch;
    NSUInteger _numberOfDeviceInfoDictionariesFetched;
    NSUInteger _numberOfDeviceInfoDictionariesThatFailedToFetch;
    
    NSUInteger _numberOfDocumentClientArraysToFetch;
    NSUInteger _numberOfDocumentClientArraysFetched;
    NSUInteger _numberOfDocumentClientArraysThatFailedToFetch;

    BOOL _shouldIncludeRegisteredDocuments;
}

#pragma mark - Overridden Methods
/** @name Overridden Methods */

/** Fetch an array of UUID strings for each client registered to synchronize this application (the names of the directories inside the `ClientDevices` directory.
 
 This method must call `fetchedArrayOfClientUUIDStrings:` when finished. */
- (void)fetchArrayOfClientUUIDStrings;

/** Fetch the `deviceInfo.plist`, decrypting it if necessary, for the specified client.
 
 This method must call `fetchedDeviceInfoDictionary:forClientWithIdentifier:` when finished.
 
 @param anIdentifier The UUID synchronization identifier of the client. */
- (void)fetchDeviceInfoDictionaryForClientWithIdentifier:(NSString *)anIdentifier;

/** Fetch an array of UUID strings for each document registered for this application.
 
 This method must call `fetchedArrayOfDocumentUUIDStrings:` when finished. */
- (void)fetchArrayOfDocumentUUIDStrings;

/** Fetch an array of UUID strings for each client registered to synchronize with this document (the names of the directories inside the document's `SyncChanges` directory.
 
 This method must call `fetchedArrayOfClients:registeredForDocumentWithIdentifier:` when finished. */
- (void)fetchArrayOfClientsRegisteredForDocumentWithIdentifier:(NSString *)anIdentifier;

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

/** Pass back the assembled `NSArray` of `NSString` document identifiers.
 
 If an error occurred, call `setError:` first, then specify `nil` for `anArray`.
 
 @param anArray The array of identifiers, or `nil` if an error occurred. */
- (void)fetchedArrayOfDocumentUUIDStrings:(NSArray *)anArray;

/** Pass back the assembled `NSArray` of `NSString` client identifiers for this document.
 
 If an error occurred, call `setError:` first, then specify `nil` for `anArray`.
 
 @param anArray The array of identifiers, or `nil` if an error occurred.
 @param anIdentifier The identifier of the document. */
- (void)fetchedArrayOfClients:(NSArray *)anArray registeredForDocumentWithIdentifier:(NSString *)anIdentifier;

#pragma mark - Properties
/** @name Properties */

/** An array used to keep track of the client identifiers while the operation is executing. */
@property (nonatomic, strong) NSMutableArray *synchronizedClientIdentifiers;

/** A mutable dictionary used to keep track of the `deviceInfo.plist` dictionaries for each client while the operation is executing. */
@property (nonatomic, strong) NSMutableDictionary *temporaryDeviceInfoDictionaries;

/** The final dictionary of `deviceInfo.plist` dictionaries for each client once the operation has finished. */
@property (strong) NSDictionary *deviceInfoDictionaries;

/** An array used to keep track of the document identifiers while the operation is executing. */
@property (nonatomic, strong) NSMutableArray *synchronizedDocumentIdentifiers;

/** A Boolean indicating whether the operation should check which documents are synchronized by each client. */
@property (assign) BOOL shouldIncludeRegisteredDocuments;

@end
