//
// FZAKeyManageriPhone.m
//
// Created by Graham J Lee on 07/05/2011.
// Copyright 2011 Fuzzy Aliens Ltd. 
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#if TARGET_OS_IPHONE

#import "TICoreDataSync.h"
#import <Security/Security.h>

@interface FZAKeyManageriPhone ()

- (NSData *)applicationName;
- (NSDictionary *)searchAttributes;

@end

@implementation FZAKeyManageriPhone

- (NSDictionary *)searchAttributes {
    return [NSDictionary dictionaryWithObjectsAndKeys:
            [NSString stringWithFormat:@"%@-fza-sync", [self applicationName]], kSecAttrAccount,
            [NSString stringWithFormat:@"%@-fza-sync", [self applicationName]], kSecAttrService,
            kSecClassGenericPassword, kSecClass,
            kCFBooleanTrue, kSecReturnAttributes,
            nil];
}

- (NSData *)applicationName {
    return [[[NSBundle mainBundle] bundleIdentifier] dataUsingEncoding: NSUTF8StringEncoding];
}

- (NSData *)randomDataOfLength: (NSInteger)length {
    uint8_t *bytes = malloc(length);
    if (bytes == NULL) {
        return nil;
    }
    if (SecRandomCopyBytes(NULL, length, bytes) != 0) {
        free(bytes);
        return nil;
    }
    NSData *randomData = [NSData dataWithBytes: bytes length: length];
    free(bytes);
    return randomData;
}

- (BOOL)storeKeyDerivedFromPassword:(NSString *)password salt:(NSData *)salt error:(NSError **)error
{
    NSData *key = [self keyFromPassword:password salt:salt];
    NSDictionary *searchAttributes = [self searchAttributes];
    CFDictionaryRef localResult;
    OSStatus searchResult = SecItemCopyMatching((__bridge CFDictionaryRef)searchAttributes, (CFTypeRef *)&localResult);
    OSStatus storeResult = noErr;

    if (searchResult == noErr || searchResult == errSecDuplicateItem) {
        if (searchResult == errSecDuplicateItem) {
            TICDSLog(TICDSLogVerbosityErrorsOnly, @"A call to SecItemCopyMatching returned errSecDuplicateItem. This is not an error, but it's slightly unexpected. Either way, we've handled it so let's carry on.");
        }
        
        NSDictionary *foundAttributes = (__bridge NSDictionary *)localResult;
        TICDSLog(TICDSLogVerbosityEveryStep, @"FZACryptor iOS Key Manager updating %@", foundAttributes);
        NSMutableDictionary *updateAttributes = [[self searchAttributes] mutableCopy];
        [updateAttributes removeObjectForKey:(__bridge id)kSecReturnAttributes];

        // update an existing item
        NSDictionary *storeAttributes = @{(__bridge id)kSecValueData : key};
        storeResult = SecItemUpdate((__bridge CFDictionaryRef)updateAttributes,
                                    (__bridge CFDictionaryRef)storeAttributes);
    } else {
        TICDSLog(TICDSLogVerbosityEveryStep, @"FZACryptor iOS Key Manager creating key");
        // create a new item
        NSMutableDictionary *storeAttributes = [searchAttributes mutableCopy];
        [storeAttributes setObject:key forKey:(__bridge id)kSecValueData];
        [storeAttributes setObject:@"fza-sync" forKey:(__bridge id)kSecAttrLabel];
        
        [storeAttributes removeObjectForKey:(__bridge id)kSecReturnAttributes];
        storeResult = SecItemAdd((__bridge CFDictionaryRef)storeAttributes, NULL);
        if (storeResult == errSecDuplicateItem) {
            TICDSLog(TICDSLogVerbosityErrorsOnly, @"A call to SecItemAdd returned errSecDuplicateItem. This is not an error because we've handled it so let's carry on.");
            NSMutableDictionary *updateAttributes = [[self searchAttributes] mutableCopy];
            [updateAttributes removeObjectForKey:(__bridge id)kSecReturnAttributes];
            NSDictionary *updatedStoreAttributes = @{(__bridge id)kSecValueData : key};
            storeResult = SecItemUpdate((__bridge CFDictionaryRef)updateAttributes,
                                        (__bridge CFDictionaryRef)updatedStoreAttributes);
        }
    }
    
    if (storeResult != noErr) {
        if (error != nil) {
            *error = [NSError errorWithDomain:FZAKeyManagerErrorDomain
                                         code:storeResult
                                     userInfo:nil];
            TICDSLog(TICDSLogVerbosityErrorsOnly, @"FZACryptor iOS Key Manager store error: %@", *error);
        }
    } else {
        TICDSLog(TICDSLogVerbosityEveryStep, @"FZACryptor iOS Key Manager stored key successfully");
    }
    
    return storeResult == noErr;
}

- (NSData *)key
{
    NSMutableDictionary *searchAttributes = [[self searchAttributes] mutableCopy];
    [searchAttributes removeObjectForKey:(__bridge id)kSecReturnAttributes];
    [searchAttributes setObject:(id)kCFBooleanTrue forKey:(__bridge id)kSecReturnData];

    CFTypeRef secItem = NULL;
    OSStatus searchResult = SecItemCopyMatching((__bridge CFDictionaryRef)searchAttributes, &secItem);

    if (searchResult != noErr) {
        if (searchResult == errSecItemNotFound) {
            TICDSLog(TICDSLogVerbosityEveryStep, @"FZACryptor iOS Key Manager didn't find a stored key");
        } else {
            TICDSLog(TICDSLogVerbosityErrorsOnly, @"FZACryptor iOS Key Manager search error: %ld", searchResult);
        }

        return nil;
    }

    NSData *theKey = (__bridge NSData *)secItem;
    return theKey;
}

- (void)clearPasswordAndSalt {
    NSDictionary *searchAttributes = [self searchAttributes];
    OSStatus clearResult = SecItemDelete((__bridge CFDictionaryRef)searchAttributes);
    
    if( clearResult == errSecSuccess ) {
        TICDSLog(TICDSLogVerbosityEveryStep, @"FZACryptor iOS Key Manager deleted keychain items");
    } else {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"FZACryptor iOS Key Manager failed to delete keychain items: %ld", clearResult);
    }
}

@end

#endif