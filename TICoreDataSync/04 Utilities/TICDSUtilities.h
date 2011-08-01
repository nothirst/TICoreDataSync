//
//  TICDSUtilities.h
//  ShoppingListMac
//
//  Created by Tim Isted on 21/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

/** `TICDSUtilities` is a utility class providing various class methods for miscellaneous tasks. */

@interface TICDSUtilities : NSObject {
@private
    
}

/** @name Unique Strings */

/** Returns a globally unique string, currently created using `[[NSProcessInfo processInfo] globallyUniqueString]`. */
+ (NSString *)uuidString;

/** @name Directory Hierarchy */

/** Returns a dictionary containing the basic file structure for Global Application synchronization.
 
 The string keys are names of sub-directories, the values are dictionaries, which may contain further sub-directory keys. */
+ (NSDictionary *)remoteGlobalAppDirectoryHierarchy;

/** Returns a dictionary containing the basic file structure for a synchronized document. */
+ (NSDictionary *)remoteDocumentDirectoryHierarchy;

/** Returns a dictionary configured for a given synchronization warning. 
 
 @param aType The type of the sync warning.
 @param entityName The entity name for the affected object.
 @param attributes Any defining attributes for the object affected by the sync change.
 @param relatedObjectEntityName The entity name for any related object.
 
 @return A dictionary configured with the given information. */
+ (NSDictionary *)syncWarningOfType:(TICDSSyncWarningType)aType entityName:(NSString *)entityName relatedObjectEntityName:(NSString *)relatedObjectEntityName attributes:(NSDictionary *)attributes;

/** @name User Defaults Keys */

/** Returns a full path key using the TICDSync prefix for the given key. */
+ (NSString *)userDefaultsKeyForKey:(NSString *)aKey;

/** Returns a full path key using the TICDSync and integrityKey components for the given key. */
+ (NSString *)userDefaultsKeyForIntegrityKeyForDocumentWithIdentifier:(NSString *)anIdentifier;

@end
