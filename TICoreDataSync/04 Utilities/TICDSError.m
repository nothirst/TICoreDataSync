//
//  TICDSError.m
//  ShoppingListMac
//
//  Created by Tim Isted on 21/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICoreDataSync.h"

NSString *gTICDSErrorStrings[] = {
    @"No error",
    @"Method not overridden in subclass",
    @"File Manager error",
    @"Unexpected or incomplete directory structure",
    @"Helper File directory does not already exist",
    @"Failed to save Sync Changes managed object context",
    @"Failed to create Operation Object",
    @"File already exists at specified location",
    @"No previously uploaded store exists",
    @"Core Data Fetch error",
    @"Core Data Save error",
};


@implementation TICDSError

#pragma mark -
#pragma mark Error Generation
+ (NSError *)errorWithCode:(TICDSErrorCode)aCode userInfo:(id)someInfo
{
    return [self errorWithCode:aCode underlyingError:nil userInfo:someInfo classAndMethod:NULL];
}

+ (NSError *)errorWithCode:(TICDSErrorCode)aCode classAndMethod:(const char *)aClassAndMethod
{
    return [self errorWithCode:aCode underlyingError:nil userInfo:nil classAndMethod:aClassAndMethod];
}

+ (NSError *)errorWithCode:(TICDSErrorCode)aCode underlyingError:(NSError *)anUnderlyingError classAndMethod:(const char *)aClassAndMethod
{
    return [self errorWithCode:aCode underlyingError:anUnderlyingError userInfo:nil classAndMethod:aClassAndMethod];
}

+ (NSError *)errorWithCode:(TICDSErrorCode)aCode underlyingError:(NSError *)anUnderlyingError userInfo:(id)someInfo classAndMethod:(const char *)aClassAndMethod
{
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithObject:gTICDSErrorStrings[aCode] forKey:NSLocalizedDescriptionKey];
    
    if( someInfo ) {
        [userInfo setValue:someInfo forKey:TICDSErrorUserInfoKey];
    }
    
    if( anUnderlyingError ) {
        [userInfo setValue:anUnderlyingError forKey:TICDSErrorUnderlyingErrorKey];
    }
    
    if( aClassAndMethod != NULL ) {
        [userInfo setValue:[NSString stringWithUTF8String:aClassAndMethod] forKey:TICDSErrorClassAndMethod];
    }
    
    return [NSError errorWithDomain:TICDSErrorDomain code:aCode userInfo:userInfo];    
}

@end
