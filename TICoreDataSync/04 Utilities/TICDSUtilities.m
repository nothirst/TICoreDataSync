//
//  TICDSUtilities.m
//  ShoppingListMac
//
//  Created by Tim Isted on 21/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

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
    
    [dictionary setValue:[NSDictionary dictionary] forKey:TICDSClientDevicesDirectoryName];
    
    [dictionary setValue:[NSDictionary dictionary] forKey:TICDSDocumentsDirectoryName];
    
    return dictionary;
}

+ (NSDictionary *)remoteGlobalAppClientDeviceFileStructure
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    
    [dictionary setValue:[NSDictionary dictionary] forKey:kTICDSUtilitiesFileStructureClientDeviceUID];
    
    return dictionary;
}

+ (NSDictionary *)remoteDocumentFileStructure
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    
    [dictionary setValue:[NSDictionary dictionaryWithObjectsAndKeys:
                          [NSDictionary dictionary], TICDSWholeStoreDirectoryName,
                          [NSDictionary dictionary], TICDSSyncChangesDirectoryName,
                          [NSDictionary dictionary], TICDSSyncCommandsDirectoryName,
                          [NSDictionary dictionary], TICDSRecentSyncsDirectoryName,
                          nil]
                  forKey:kTICDSUtilitiesFileStructureDocumentUID];
    
    return dictionary;
}

#pragma mark -
#pragma mark Sync Warnings
+ (NSDictionary *)syncWarningOfType:(TICDSSyncWarningType)aType entityName:(NSString *)entityName relatedObjectEntityName:(NSString *)relatedObjectEntityName attributes:(NSDictionary *)attributes
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    
    [dictionary setValue:[NSNumber numberWithInt:aType] forKey:kTICDSSyncWarningType];
    [dictionary setValue:TICDSSyncWarningTypeNames[aType] forKey:kTICDSSyncWarningDescription];
    
    if( entityName ) {
        [dictionary setValue:entityName forKey:kTICDSSyncWarningEntityName];
    }
    
    if( relatedObjectEntityName ) {
        [dictionary setValue:relatedObjectEntityName forKey:kTICDSSyncWarningRelatedObjectEntityName];
    }
    
    if( attributes ) {
        [dictionary setValue:attributes forKey:kTICDSSyncWarningAttributes];
    }
    
    return dictionary;
}

@end
