//
//  TICDSApplicationRegistrationOperation.h
//  ShoppingListMac
//
//  Created by Tim Isted on 21/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICDSOperation.h"

/** The `TICDSApplicationRegistrationOperation` class describes a generic operation used by the `TICoreDataSync` framework to register an application for future synchronization of documents.
 
 The operation carries out the following tasks:
 
 1. Subclass checks whether the `appIdentifier` directory exists on the remote.
 
    1. If not, blitz any existing keychain items, then ask the application sync manager whether to use encryption (get a password, if so), then:
 
       1. Subclass creates the `appIdentifier` directory on the remote, and general file structure (directories only).
       
       2. Subclass saves the `ReadMe.txt` file at the root.
 
       3. If encryption is enabled, create the `FZACryptor` and set its password.
    
       4. If encryption is enabled, subclass saves the generated salt file in the remote `Encryption` directory.
 
       5. If encryption is enabled, subclass saves a suitable file for password testing in the remote `Encryption` directory.
 
       6. Continue by creating the client's directory (main step 3) inside `ClientDevices`.
 
    2. If app has been registered before, subclass checks whether the salt file exists on the remote, and `shouldUseEncryption` is set accordingly, then:
 
       1. Subclass checks whether the client's directory exists inside `ClientDevices`.
 
       2. If not, any existing keychain items are blitzed, then:
 
          1. If encryption is disabled, continue by creating the client's directory (main step 3) inside `ClientDevices`.
 
          2. If encryption is enabled, subclass downloads the salt file and sets the `saltData` operation property.
 
          3. The application sync manager is asked for the password.
 
          4. The `FZACryptor` is configured with password and salt, and the test file is downloaded.
 
       3. If the directory exists, and encryption is disabled, then operation is complete.
 
     2. If app has been registered before, subclass checks whether the salt file exists on the remote.
 
       1. If not, encryption is disabled, so continue by checking whether the client has registered before.
 
       2. If salt file exists, encryption is enabled, so check whether the `FZACryptor` has a password and salt.
 
          1. If not, subclass downloads the salt, the application sync manager is asked to get the password from the user, then the `FZACryptor` is configured.
 
          2. Once downloaded, or if `FZACryptor` already has the password, continue by subclass checking whether the client's directory exists inside `ClientDevices`.
  
 2. Subclass checks whether the client's directory exists inside `ClientDevices`.
 
 3. If not, subclass creates client's directory inside `ClientDevices`, then:

     1. `documentInfo.plist` is created, and encrypted, if necessary.
 
     2. Subclass uploads the `documentInfo.plist` file to the remote.
 
 Operations are typically created automatically by the relevant sync manager.
 
 @warning You must use one of the subclasses of `TICDSApplicationRegistrationOperation`.
 */
 
@interface TICDSApplicationRegistrationOperation : TICDSOperation {
@private
    NSString *_appIdentifier;
    NSString *_clientDescription;
    NSDictionary *_applicationUserInfo;
    
    BOOL _paused;
    NSString *_password;
    NSData *_saltData;
    BOOL _shouldCreateClientDirectory;
}

#pragma mark Designated Initializer
/** @name Designated Initializer */

/** Initialize an application registration operation using a delegate that supports the `TICDSApplicationRegistrationOperationDelegate` protocol.
 
 @param aDelegate The delegate to use for this operation.
 
 @return An initialized document registration operation. */
- (id)initWithDelegate:(NSObject<TICDSApplicationRegistrationOperationDelegate> *)aDelegate;

#pragma mark Methods Overridden by Subclasses
/** @name Methods Overridden by Subclasses */

/** Check whether a directory exists for this application.
 
 This method must call `discoveredStatusOfGlobalAppDirectory:` to indicate the status. */
- (void)checkWhetherRemoteGlobalAppDirectoryExists;

/** Create global application directory structure.
 
 This method must call `createdGlobalAppDirectoryStructureWithSuccess:` to indicate whether the creation was successful. */
- (void)createRemoteGlobalAppDirectoryStructure;

/** Copy the `ReadMe.txt` file from the bundle to the root of this application's remote directory. 
 
 This method must call `copiedReadMeTxtFileToRootOfGlobalAppDirectoryWithSuccess:` to indicate whether the copy was successful.
 
 @param aPath The local path to the `ReadMe.txt` file. */
- (void)copyReadMeTxtFileToRootOfGlobalAppDirectoryFromPath:(NSString *)aPath;

/** Check whether the `salt.ticdsync` file exists at the root of the application's remote directory.
 
 This method must call `discoveredStatusOfSaltFile:` to indicate the status. */
- (void)checkWhetherSaltFileExists;

/** Fetch the data from the `salt.ticdsync` file.
 
 This method must call `` when the data has been fetched. */
- (void)fetchSaltData;

/** Save the salt data to a `salt.ticdsync` file at the root of the application's remote directory.
 
 This method must call `savedSaltDataToRootOfGlobalAppDirectoryWithSuccess:` to indicate whether the save was successful.
 
 @param saltData The data to be saved. */
- (void)saveSaltDataToRemote:(NSData *)saltData;

/** Save the test data to a `test.ticdsync` file in the `Encryption` directory at the root of the application's remote directory.
 
 This method must call `savedTestDataWithSuccess:` to indicate whether the save was successful.
 
 @param testData The data to be saved. */
- (void)savePasswordTestData:(NSData *)testData;

/** Fetch the test data from the `test.ticdsync` file in the `Encryption` directory.
 
 This method must call `fetchedPasswordTestData:` when done. */
- (void)fetchPasswordTestData;

/** Check whether the client's directory already exists in `ClientDevices`.
 
 This method must call `discoveredStatusOfRemoteClientDeviceDirectory:` to indicate the status. */
- (void)checkWhetherRemoteClientDeviceDirectoryExists;

/** Create the client's directory in `ClientDevices`.
 
 This method must call `createdRemoteClientDeviceDirectoryWithSuccess:` to indicate whether the creation was successful. */
- (void)createRemoteClientDeviceDirectory;

/** Save the dictionary to a `deviceInfo.plist` file in this client's directory inside the `ClientDevices` directory.
 
 This method must call `savedRemoteClientDeviceInfoPlistWithSuccess:` to indicate whether the save was successful.
 
 @param aDictionary The dictionary to save as the `deviceInfo.plist`. */
- (void)saveRemoteClientDeviceInfoPlistFromDictionary:(NSDictionary *)aDictionary;

#pragma mark Callbacks
/** @name Callbacks */

/** Indicate the status of the global application directory.
 
 If an error occurred, call `setError:` first, then specify `TICDSRemoteFileStructureExistsResponseTypeError` for `status`.
 
 @param status The status of the directory: does exist, does not exist, or error (see `TICDSTypesAndEnums.h` for possible values). */
- (void)discoveredStatusOfRemoteGlobalAppDirectory:(TICDSRemoteFileStructureExistsResponseType)status;

/** Indicate whether the creation of the global app directory structure was successful.
 
 If not, call `setError:` first, then specify `NO` for `success`.
 
 @param success `YES` if the directory structure was created, otherwise `NO`. */
- (void)createdRemoteGlobalAppDirectoryStructureWithSuccess:(BOOL)success;

/** Indicate whether the `ReadMe.txt` file was copied from the bundle. 
 
 If not, call `setError:` first, then specify `NO` for `success`.
 
 @param success `YES` if the `ReadMe.txt` file was copied, otherwise `NO`. */
- (void)copiedReadMeTxtFileToRootOfGlobalAppDirectoryWithSuccess:(BOOL)success;

/** Indicate the status of the `salt.ticdsync` file.
 
 If an error occurred, call `setError:` first, then specify `TICDSRemoteFileStructureExistsResponseTypeError` for `status`.
 
 @param status The status of the file: does exist, does not exist, or error (see `TICDSTypesAndEnums.h` for possible values). */
- (void)discoveredStatusOfSaltFile:(TICDSRemoteFileStructureExistsResponseType)status;

/** Provide the data from the `salt.ticdsync` file.
 
 If an error occurred, call `setError:` first, then specify `nil` for `saltData`.
 
 @param saltData The `NSData` contents of the `salt.ticdsync` file, or `nil` if an error occurred. */
- (void)fetchedSaltData:(NSData *)saltData;

/** Indicate whether the salt data was saved successfully.
 
 If not, call `setError:` first, then specify `NO` for `success`.
 
 @param success `YES` if the `salt.ticdsync` file was saved, otherwise `NO`. */
- (void)savedSaltDataToRootOfGlobalAppDirectoryWithSuccess:(BOOL)success;

/** Indicate whether the test data was saved successfuly.
 
 If not, call `setError:` first, then specify `NO` for `success`.
 
 @param success `YES` if the `test.ticdsync` file was saved, otherwise `NO`. */
- (void)savedPasswordTestDataWithSuccess:(BOOL)success;

/** Provide the test data from the `test.ticdsync` file.
 
 If an error occurred, call `setError:` first, then specify `nil` for `testData`.
 
 @param testData The `NSData` contents of the `test.ticdsync` file, or `nil` if an error occurred. */
- (void)fetchedPasswordTestData:(NSData *)testData;

/* Indicate the status of the client's directory in `ClientDevices`.
 
 If an error occurred, call `setError:` first, then specify `TICDSRemoteFileStructureExistsResponseTypeError` for `status`.
 
 @param status The status of the directory: does exist, does not exist, or error (see `TICDSTypesAndEnums.h` for possible values). */
- (void)discoveredStatusOfRemoteClientDeviceDirectory:(TICDSRemoteFileStructureExistsResponseType)status;

/** Indicate whether the client's directory was created successful in `ClientDevices`.
 
 If not, call `setError:` first, then specify `NO` for `success`.
 
 @param success `YES` if the client's directory was created, otherwise `NO`. */
- (void)createdRemoteClientDeviceDirectoryWithSuccess:(BOOL)success;

/** Indicate whether the `deviceInfo.plist` file was saved successfully.
 
 If not, call `setError:` first, then specify `NO` for `success`.
 
 @param success `YES` if the `deviceInfo.plist` file was saved, otherwise `NO`. */
- (void)savedRemoteClientDeviceInfoPlistWithSuccess:(BOOL)success;

#pragma mark Properties
/** @name Properties */

/** The application identifier. */
@property (nonatomic, copy) NSString *appIdentifier;

/** The client description. */
@property (nonatomic, copy) NSString *clientDescription;

/** The user info. */
@property (nonatomic, strong) NSDictionary *applicationUserInfo;

/** Used to indicate whether the operation is currently paused awaiting input from the operation delegate, or in turn the application sync manager delegate. */
@property (assign, getter = isPaused) BOOL paused;

/** The password to use for encryption at initial global app registration, if `shouldUseEncryption` is `YES`. */
@property (copy) NSString *password;

/** The cached salt data, set only after fetching from the remote. */
@property (nonatomic, strong) NSData *saltData;

/** Used mid-operation to indicate whether the client directory needs to be created after configuring encryption. */
@property (nonatomic, assign) BOOL shouldCreateClientDirectory;

@end
