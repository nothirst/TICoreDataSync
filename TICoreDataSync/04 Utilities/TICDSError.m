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
    @"Unexpected or incomplete file location or directory structure",
    @"Helper File directory does not already exist",
    @"Failed to create Sync Changes managed object context",
    @"Failed to save Sync Changes managed object context",
    @"Failed to create Operation Object",
    @"File already exists at specified location",
    @"No previously uploaded store exists",
    @"Core Data Fetch error",
    @"Core Data Save error",
    @"Failed to create Core Data object",
    @"Whole Store file cannot be uploaded while there are still unsynchronized local sync changes",
    @"Task was cancelled",
    @"DropboxSDK Rest Client error",
    @"Encryption error",
    @"Unable to register a sync manager using delayed registration because the sync manager hasn't been configured properly",
    @"FZACryptor returned salt data when asked, but responded that it wasn't correctly configured to encrypt",
    @"Synchronization failed because integrity keys do not match",
    @"Synchronization failed because remote integrity key directory is missing; was the entire remote directory removed?",
};

#include <execinfo.h>

@implementation TICDSError

#ifdef __MAC_OS_X_VERSION_MAX_ALLOWED
#pragma mark - Inspection
- (NSString *)description
{
    return [NSString stringWithFormat:@"%@\nUser Info:%@", [super description], [self userInfo]];
}
#endif

#pragma mark - Error Generation
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
        [userInfo setValue:someInfo forKey:kTICDSErrorUserInfo];
    }
    
    if( anUnderlyingError ) {
        [userInfo setValue:anUnderlyingError forKey:NSUnderlyingErrorKey];
    }
    
    if( aClassAndMethod != NULL ) {
        [userInfo setValue:[NSString stringWithUTF8String:aClassAndMethod] forKey:kTICDSErrorClassAndMethod];
    }
    
    if( [self includeStackTraceInErrors] ) {
        void *buffer[100]; 
        int numberOfStackSymbols = backtrace(buffer, 100);
        
        char **strings = backtrace_symbols(buffer, numberOfStackSymbols);
        
        NSMutableArray *stackTraceArray = [NSMutableArray arrayWithCapacity:numberOfStackSymbols];
        
        for( int currentString = 0; currentString < numberOfStackSymbols; currentString++ ) {
            [stackTraceArray addObject:[NSString stringWithCString:strings[currentString] encoding:NSASCIIStringEncoding]];
        }
        
        [userInfo setValue:stackTraceArray forKey:kTICDSStackTrace];
        
        free(strings);
    }
    
    return [self errorWithDomain:kTICDSErrorDomain code:aCode userInfo:userInfo];    
}

#pragma mark - Stack Trace
static BOOL gTICDSIncludeStackTraceInErrors = NO;

+ (void)setIncludeStackTraceInErrors:(BOOL)aValue
{
    gTICDSIncludeStackTraceInErrors = aValue;
}

+ (BOOL)includeStackTraceInErrors
{
    return gTICDSIncludeStackTraceInErrors;
}


@end
