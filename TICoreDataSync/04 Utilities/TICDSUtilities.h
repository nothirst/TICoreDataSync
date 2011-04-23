//
//  TICDSUtilities.h
//  ShoppingListMac
//
//  Created by Tim Isted on 21/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

@interface TICDSUtilities : NSObject {
@private
    
}

/** Returns a globally unique string */
+ (NSString *)uuidString;

/** Returns a dictionary containing the basic file structure for synchronization */
/** String Keys are names of sub-directories */
+ (NSDictionary *)remoteGlobalAppFileStructure;

/** Returns a dictionary containing the basic client device file structure for synchronization */
/** Keys etc as above, with exception of ClientDeviceUID etc keys */
+ (NSDictionary *)remoteGlobalAppClientDeviceFileStructure;

/** Returns a dictionary containing the basic file structure for a synchronized document */
+ (NSDictionary *)remoteDocumentFileStructure;

@end
