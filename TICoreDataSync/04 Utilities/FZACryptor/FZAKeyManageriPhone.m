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

- (BOOL)storeKeyDerivedFromPassword: (NSString *)password salt: (NSData *)salt error: (NSError **)error {
    NSData *key = [self keyFromPassword: password salt: salt];
    NSDictionary *searchAttributes = [self searchAttributes];
    NSDictionary *foundAttributes = nil;
    OSStatus searchResult = SecItemCopyMatching((CFDictionaryRef)searchAttributes,
                                                (CFTypeRef *)&foundAttributes);
    OSStatus storeResult = noErr;
    if (noErr == searchResult) {
        NSLog(@"Updating %@", foundAttributes);
        NSMutableDictionary *updateAttributes = [[self searchAttributes] mutableCopy];
        [updateAttributes removeObjectForKey: (id)kSecReturnAttributes];
        //update an existing item
        NSDictionary *storeAttributes = [NSDictionary 
                                                dictionaryWithObject: key 
                                                forKey: (id)kSecValueData];
        storeResult = SecItemUpdate((CFDictionaryRef)updateAttributes,
                                    (CFDictionaryRef)storeAttributes);
        [updateAttributes release];
    }
    else {
        NSLog(@"creation");
        //create a new item
        NSMutableDictionary *storeAttributes = [searchAttributes mutableCopy];
        [storeAttributes setObject: key forKey: (id)kSecValueData];
        [storeAttributes setObject: @"fza-sync" forKey: (id)kSecAttrLabel];
        //[storeAttributes setObject: (id)kCFBooleanTrue forKey: (id)kSecReturnPersistentRef];
        [storeAttributes removeObjectForKey: (id)kSecReturnAttributes];
        storeResult = SecItemAdd((CFDictionaryRef)storeAttributes, NULL);
        [storeAttributes release];
    }
    [foundAttributes release];
    if (noErr != storeResult) {
        if (error) {
            *error = [NSError errorWithDomain: FZAKeyManagerErrorDomain
                                         code: storeResult
                                     userInfo: nil];
            NSLog(@"store error: %@", *error);
        }
    } else {
        NSLog(@"succeeded");
    }
    return storeResult == noErr;
}

- (NSData *)key {
    NSMutableDictionary *searchAttributes = [[self searchAttributes] mutableCopy];
    [searchAttributes removeObjectForKey: (id)kSecReturnAttributes];
    [searchAttributes setObject: (id)kCFBooleanTrue forKey: (id)kSecReturnData];
    NSData *theKey = nil;
    OSStatus searchResult = SecItemCopyMatching((CFDictionaryRef)searchAttributes,
                                                (CFTypeRef *)&theKey);
    [searchAttributes release];
    if (noErr != searchResult) {
        if( searchResult == errSecItemNotFound ) {
            NSLog(@"Keychain item not found");
        } else {
            NSLog(@"Search error: %ld", searchResult);
        }
    }
    return [theKey autorelease];
}

- (void)clearPasswordAndSalt {
    NSDictionary *searchAttributes = [self searchAttributes];
    OSStatus clearResult = SecItemDelete((CFDictionaryRef)searchAttributes);
    
    if( clearResult == errSecSuccess ) {
        NSLog(@"Deleted keychain items");
    } else {
        NSLog(@"Failed to delete keychain items: %ld", clearResult);
    }
}

@end

#endif