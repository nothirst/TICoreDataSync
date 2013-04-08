//
//  TICDSyncChange.m
//  ShoppingListMac
//
//  Created by Tim Isted on 23/04/2011.
//  Copyright (c) 2011 Tim Isted. All rights reserved.
//

#import "TICoreDataSync.h"

static const NSInteger kTICDSDataMaximumLogLength = 512;

@implementation TICDSSyncChange

static NSString *bigDataDirectory = nil;

+ (void)initialize
{
    if ( bigDataDirectory == nil ) {
        bigDataDirectory = [NSTemporaryDirectory() stringByAppendingPathComponent:@"TICDSSyncChangeData"];
        if ( [[NSFileManager defaultManager] fileExistsAtPath:bigDataDirectory] ) {
            
            // Try to move aside the old directory, and delete it in the background
            NSString *oldBigDataDirectory = [bigDataDirectory stringByAppendingPathExtension:@"old"];
            [[NSFileManager defaultManager] removeItemAtPath:oldBigDataDirectory error:NULL]; // Remove in odd case that this folder already exists
            
            // Remove in background, because it can be expensive and lock up the main thread
            if ( [[NSFileManager defaultManager] moveItemAtPath:bigDataDirectory toPath:oldBigDataDirectory error:NULL] ) {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
                    NSFileManager *fm = [NSFileManager new];
                    NSError *error;
                    BOOL success = [fm removeItemAtPath:oldBigDataDirectory error:&error];
                    if ( !success ) NSLog(@"Failed to remove big data directory: %@", error);
                });
            }
            else {
                // Move failed, so just remove directly on main thread
                [[NSFileManager defaultManager] removeItemAtPath:bigDataDirectory error:NULL];
            }
            
        }
        [[NSFileManager defaultManager] createDirectoryAtPath:bigDataDirectory withIntermediateDirectories:NO attributes:nil error:NULL];
    }
}

#pragma mark - Helper Methods
+ (id)syncChangeOfType:(TICDSSyncChangeType)aType inManagedObjectContext:(NSManagedObjectContext *)aMoc
{
    TICDSSyncChange *syncChange = [self ti_objectInManagedObjectContext:aMoc];
    
    [syncChange setLocalTimeStamp:[NSDate date]];
    [syncChange setChangeType:[NSNumber numberWithInt:aType]];
    
    return syncChange;
}

#pragma mark - Inspection
- (NSString *)shortDescription
{
    return [NSString stringWithFormat:@"%@ %@", TICDSSyncChangeTypeNames[ [[self changeType] unsignedIntValue] ], [self objectEntityName]];
}

- (NSString *) description
{
    return [NSString stringWithFormat:@"\n<%@: %p> (entity: %@; id: %@; changeType: %@; "
            "\nCHANGED ATTRIBUTES\n%@\nCHANGED RELATIONSHIPS\n%@)",
            NSStringFromClass([self class]), self, [[self entity] name], self.objectID, self.changeType,
            [self changedAttributesDescription], [self changedRelationships]];
}

- (NSString *) changedAttributesDescription
{
    NSMutableString *result = [NSMutableString string];
    
    id changedAttributes = self.changedAttributes;
    
    if ([changedAttributes isKindOfClass:[NSData class]]) {
        if ([changedAttributes length] > kTICDSDataMaximumLogLength) {
            [result appendFormat:@"    %@ (... %ld bytes)", [changedAttributes subdataWithRange:NSMakeRange(0, kTICDSDataMaximumLogLength)], (unsigned long)[changedAttributes length]];
        } else {
            [result appendFormat:@"    %@", changedAttributes];
        }
        
    } else if ([changedAttributes isKindOfClass:[NSDictionary class]]) {
        [result appendString:@"{\n"];
        
        for (id key in self.changedAttributes) {
            id value = [changedAttributes valueForKey:key];
            
            [result appendFormat:@"    %@ = ", key];
            
            if ([value isKindOfClass:[NSData class]] && [value  length] > kTICDSDataMaximumLogLength) {
                [result appendFormat:@"%@ (... %ld bytes);\n", [value  subdataWithRange:NSMakeRange(0, kTICDSDataMaximumLogLength)], (unsigned long)[value length]];
            } else {
                [result appendFormat:@"%@;\n", value ];
            }
        }
    }
    
    [result appendString:@"}"];
    
    return result;
}

#pragma mark - TIManagedObjectExtensions
+ (NSString *)ti_entityName
{
    return NSStringFromClass([self class]);
}

#pragma mark -
#pragma mark Low Memory

- (NSData *)mappedDataFromData:(NSData *)data withFilename:(NSString *)filename
{
    NSString *path = [bigDataDirectory stringByAppendingPathComponent:filename];
    [data writeToFile:path atomically:NO];
    id newData = [NSData dataWithContentsOfFile:path options:NSDataReadingMappedAlways error:NULL];
    return newData ? : data;
}

- (id)lowMemoryChangedAttributesFromAttributes:(id)changedAttributes
{
    id result = changedAttributes;
    
    if ( [changedAttributes isKindOfClass:[NSData class]] && [changedAttributes length] > 10000 ) {
        NSString *uniqueString = [[NSProcessInfo processInfo] globallyUniqueString];
        result = [self mappedDataFromData:changedAttributes withFilename:uniqueString];
    }
    else if ( [changedAttributes isKindOfClass:[NSDictionary class]] ) {
        NSMutableDictionary *newResult = [NSMutableDictionary dictionaryWithDictionary:changedAttributes];
        for ( id key in changedAttributes ) {
            id value = [changedAttributes valueForKey:key];
            if ( [value isKindOfClass:[NSData class]] && [value length] > 10000 ) {
                NSString *uniqueString = [[NSProcessInfo processInfo] globallyUniqueString];
                id newValue = [self mappedDataFromData:value withFilename:uniqueString];
                [newResult setValue:newValue forKey:key];
            }
        }
        result = newResult;
    }
    
    return result;
}

- (void)setChangedAttributes:(id)changedAttributes
{
    [self willChangeValueForKey:@"changedAttributes"];
    id lowMemAttributes = [self lowMemoryChangedAttributesFromAttributes:changedAttributes];
    [self setPrimitiveValue:lowMemAttributes forKey:@"changedAttributes"];
    [self didChangeValueForKey:@"changedAttributes"];
}

- (id)changedAttributes
{
    [self willAccessValueForKey:@"changedAttributes"];
    id result = [self primitiveValueForKey:@"changedAttributes"];
    result = [self lowMemoryChangedAttributesFromAttributes:result];
    [self didAccessValueForKey:@"changedAttributes"];
    return result;
}

@dynamic changeType;
@synthesize relevantManagedObject = _relevantManagedObject;
@dynamic objectEntityName;
@dynamic objectSyncID;
@dynamic changedAttributes;
@dynamic changedRelationships;
@dynamic relevantKey;
@dynamic localTimeStamp;
@dynamic relatedObjectEntityName;

@end
