//
// FZAKeyManagerMac.m
//
// Created by Graham J Lee on 05/05/2011.
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

#if !(TARGET_OS_IPHONE)

#import "TICoreDataSync.h"
#import <Security/Security.h>

FourCharCode FZACreatorCode = 'FZAL';

void FZAReportKeychainError(OSStatus keychainStatus, NSString *msg) {
    CFStringRef errorMsg = SecCopyErrorMessageString(keychainStatus, NULL);
    NSLog(@"%@: %@", msg, (id)errorMsg);
    CFRelease(errorMsg);
}

@interface FZAKeyManagerMac ()

- (NSData *)serviceName;

@end

@implementation FZAKeyManagerMac

- (NSData *)randomDataOfLength: (NSInteger)length {
    int fd = open("/dev/random", O_RDONLY);
    if (fd == -1) {
        return nil;
    }
    uint8_t *randomBytes = malloc(length);
    if (randomBytes == NULL) {
        return nil;
    }
    ssize_t bytesRead = read(fd, randomBytes, length);
    close(fd);
    if (bytesRead < length) {
        return nil;
    }
    NSData *randomData = [NSData dataWithBytes: randomBytes length: length];
    free(randomBytes);
    return randomData;
}

- (NSData *)serviceName {
    NSData *bundleID = [[[NSBundle mainBundle] bundleIdentifier]
                        dataUsingEncoding: NSUTF8StringEncoding];
    NSData *serviceName = [[NSString stringWithFormat: @"%@-fzasync", bundleID]
                           dataUsingEncoding: NSUTF8StringEncoding];
    return serviceName;
}

- (OSStatus)createKeychainItemForKey: (SecKeychainItemRef *)item {
    OSStatus keychainStatus = noErr;

    NSData *serviceName = [self serviceName];
    keychainStatus = SecKeychainFindGenericPassword(NULL,
                                                    (UInt32)[serviceName length],
                                                    [serviceName bytes], 
                                                    0,
                                                    NULL,
                                                    NULL,
                                                    NULL,
                                                    item);
    return keychainStatus;
}

- (NSData *)key {
    OSStatus keychainStatus = noErr;
    SecKeychainItemRef item;
    keychainStatus = [self createKeychainItemForKey: &item];
    if (keychainStatus != noErr) {
        return nil;
    }
    
    UInt32 keyLength;
    void *keyBytes;
    keychainStatus = SecKeychainItemCopyAttributesAndData(item, //itemRef
                                                          NULL, //info
                                                          NULL, //itemClass
                                                          NULL, //attrList
                                                          &keyLength, //length
                                                          &keyBytes); //data
    CFRelease(item);
    if (keychainStatus != noErr) {
        FZAReportKeychainError(keychainStatus, @"Couldn't fetch keychain content");
        return nil;
    }
    NSData *key = [NSData dataWithBytes: keyBytes length: keyLength];
    SecKeychainItemFreeContent(NULL, keyBytes);
    return key;
}

- (BOOL)storeKeyDerivedFromPassword:(NSString *)password salt: (NSData *)salt error:(NSError **)error {
    NSData *keyData = [self keyFromPassword: password salt: salt];
    SecKeychainItemRef item = NULL;
    //check whether the item already exists
    OSStatus keychainResult = [self createKeychainItemForKey: &item];
    if (keychainResult == noErr) {
        //yes it does, just update it
        keychainResult = SecKeychainItemModifyAttributesAndData(item,
                                                      NULL,
                                                      (UInt32)[keyData length],
                                                      [keyData bytes]);
        CFRelease(item);
        if (keychainResult != noErr) {
            FZAReportKeychainError(keychainResult, @"Couldn't update existing keychain item");
            if (error) {
                NSDictionary *userInfo = [NSDictionary dictionaryWithObject: [NSNumber numberWithInt: keychainResult]
                                                                     forKey: kFZAKeyManagerSecurityFrameworkError];
                *error = [NSError errorWithDomain: FZAKeyManagerErrorDomain
                                             code: FZAKeyManagerKeyStorageError
                                         userInfo: userInfo];
            }
            return NO;
        }
        else {
            return YES;
        }
    }
    else {
        //keychain item didn't already exist, create it.
        SecKeychainItemRef createdItem = NULL;
        
        NSData *serviceName = [self serviceName];
        
        keychainResult = SecKeychainAddGenericPassword(NULL,
                                                       (UInt32)[serviceName length],
                                                       [serviceName bytes],
                                                       0,
                                                       NULL,
                                                       (UInt32)[keyData length],
                                                       [keyData bytes],
                                                       &createdItem);
        if (keychainResult != noErr) {
            if (error) {
                NSDictionary *userInfo = [NSDictionary dictionaryWithObject: [NSNumber numberWithInt: keychainResult]
                                                                     forKey: kFZAKeyManagerSecurityFrameworkError];
                *error = [NSError errorWithDomain: FZAKeyManagerErrorDomain
                                             code: FZAKeyManagerKeyStorageError
                                         userInfo: userInfo];
            }
            return NO;
        }
        else {
            CFRelease(createdItem);
            return YES;
        }
    }
}

- (id)init {
    self = [super init];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)dealloc {
    [super dealloc];
}

@end

#endif