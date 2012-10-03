//
//  TICDSUtilities.m
//  ShoppingListMac
//
//  Created by Tim Isted on 21/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICoreDataSync.h"

@implementation TICDSUtilities

#pragma mark - UUIDs
+ (NSString *)uuidString
{
    return [[NSProcessInfo processInfo] globallyUniqueString];
}

#pragma mark - File Structure
+ (NSDictionary *)remoteGlobalAppDirectoryHierarchy
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    
    [dictionary setValue:[NSDictionary dictionary] forKey:TICDSClientDevicesDirectoryName];
    [dictionary setValue:[NSDictionary dictionary] forKey:TICDSDocumentsDirectoryName];
    [dictionary setValue:[NSDictionary dictionary] forKey:TICDSEncryptionDirectoryName];
    
    NSMutableDictionary *informationDirectories = [NSMutableDictionary dictionaryWithCapacity:2];
    [informationDirectories setValue:[NSDictionary dictionary] forKey:TICDSDeletedDocumentsDirectoryName];
    [informationDirectories setValue:[NSDictionary dictionary] forKey:TICDSDeletedClientsDirectoryName];
    [dictionary setValue:informationDirectories forKey:TICDSInformationDirectoryName];
    
    return dictionary;
}

+ (NSDictionary *)remoteDocumentDirectoryHierarchy
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    
    [dictionary setValue:[NSDictionary dictionary] forKey:TICDSWholeStoreDirectoryName];
    [dictionary setValue:[NSDictionary dictionary] forKey:TICDSSyncChangesDirectoryName];
    [dictionary setValue:[NSDictionary dictionary] forKey:TICDSSyncCommandsDirectoryName];
    [dictionary setValue:[NSDictionary dictionary] forKey:TICDSRecentSyncsDirectoryName];
    [dictionary setValue:[NSDictionary dictionary] forKey:TICDSDeletedClientsDirectoryName];
    [dictionary setValue:[NSDictionary dictionary] forKey:TICDSIntegrityKeyDirectoryName];
    
    NSMutableDictionary *tempFilesDictionary = [NSMutableDictionary dictionary];
    [tempFilesDictionary setValue:[NSDictionary dictionary] forKey:TICDSWholeStoreDirectoryName];
    [dictionary setValue:tempFilesDictionary forKey:TICDSTemporaryFilesDirectoryName];
    
    return dictionary;
}

#pragma mark - Sync Warnings
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

#pragma mark - User Defaults Keys
+ (NSString *)userDefaultsKeyForKey:(NSString *)aKey
{
    return [NSString stringWithFormat:@"%@%@", TICDSUserDefaultsPrefix, aKey];
}

+ (NSString *)userDefaultsKeyForIntegrityKeyForDocumentWithIdentifier:(NSString *)anIdentifier
{
    return [self userDefaultsKeyForKey:[NSString stringWithFormat:@"%@%@", TICDSUserDefaultsIntegrityKeyComponent, anIdentifier]];
}

@end
