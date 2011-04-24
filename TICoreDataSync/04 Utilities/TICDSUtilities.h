//
//  TICDSUtilities.h
//  ShoppingListMac
//
//  Created by Tim Isted on 21/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

/** `TICDSUtilities` is a utility class providing various class methods for miscellaneous tasks */

@interface TICDSUtilities : NSObject {
@private
    
}

/** @name Unique Strings */

/** Returns a globally unique string, currently created using `[[NSProcessInfo processInfo] globallyUniqueString]`. */
+ (NSString *)uuidString;

/** @name File Structure */

/** Returns a dictionary containing the basic file structure for Global Application synchronization.
 
 The string keys are names of sub-directories. */
+ (NSDictionary *)remoteGlobalAppFileStructure;

/** Returns a dictionary containing the basic client device file structure for Global Application synchronization.
 
 The string keys etc are names of sub-directories, with exception of certain keys to be substitued with ClientDeviceUID, etc. */
+ (NSDictionary *)remoteGlobalAppClientDeviceFileStructure;

/** Returns a dictionary containing the basic file structure for a synchronized document. */
+ (NSDictionary *)remoteDocumentFileStructure;

@end
