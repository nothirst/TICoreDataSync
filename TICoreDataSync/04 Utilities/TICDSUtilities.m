//
//  TICDSUtilities.m
//  ShoppingListMac
//
//  Created by Tim Isted on 21/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICDSUtilities.h"
#import "TICoreDataSync.h"

@implementation TICDSUtilities

#pragma mark -
#pragma mark UUIDs
+ (NSString *)uuidString
{
    return [[NSProcessInfo processInfo] globallyUniqueString];
}

#pragma mark -
#pragma mark File Structure
+ (NSDictionary *)remoteGlobalAppFileStructure
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    
    [dictionary setValue:[NSDictionary dictionary] forKey:@"ClientDevices"];
    
    [dictionary setValue:[NSDictionary dictionary] forKey:@"Documents"];
    
    return dictionary;
}

+ (NSDictionary *)remoteClientDeviceFileStructure
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    
    [dictionary setValue:[NSDictionary dictionary] forKey:kTICDSUtilitiesFileStructureClientDeviceUID];
    
    return dictionary;
}

@end
