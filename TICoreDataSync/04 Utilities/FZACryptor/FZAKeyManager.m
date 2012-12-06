//
// FZAKeyManager.m
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

#import "FZAKeyManager.h"
#import "TICoreDataSync.h"

#import <CommonCrypto/CommonDigest.h>

@implementation FZAKeyManager

- (NSData *)keyFromPassword:(NSString *)password salt:(NSData *)salt
{
    NSData *passwordBytes = [password dataUsingEncoding:NSUTF16LittleEndianStringEncoding];
    NSMutableData *saltedPW = [passwordBytes mutableCopy];
    [saltedPW appendData:salt];
    uint8_t hashBuffer[CC_SHA256_DIGEST_LENGTH] = {
        0
    };

    CC_SHA256([saltedPW bytes], (CC_LONG)[saltedPW length], hashBuffer);
    for (int i = 0; i < 7499; i++) {
        CC_SHA256(hashBuffer, CC_SHA256_DIGEST_LENGTH, hashBuffer);
    }
    
    return [NSData dataWithBytes:hashBuffer length:CC_SHA256_DIGEST_LENGTH];
}

- (BOOL)hasKey {
    return [self key] != nil;
}

- (NSData *)key {
    [[NSException exceptionWithName: @"FZAKeyManagerAbstractClassException"
                            reason: @"Use +[FZAKeyManager newKeyManager] to get an appropriate subclass"
                          userInfo: nil] raise];
    //never reached
    return nil;
}

- (NSData *)randomDataOfLength:(NSInteger)length {
    [[NSException exceptionWithName: @"FZAKeyManagerAbstractClassException"
                             reason: @"Use +[FZAKeyManager newKeyManager] to get an appropriate subclass"
                           userInfo: nil] raise];
    //never reached
    return nil;
}

- (BOOL)storeKeyDerivedFromPassword:(NSString *)password salt: (NSData *)salt error:(NSError **)error {
    [[NSException exceptionWithName: @"FZAKeyManagerAbstractClassException"
                             reason: @"Use +[FZAKeyManager newKeyManager] to get an appropriate subclass"
                           userInfo: nil] raise];
    //never reached
    return NO;
    
}

- (void)clearPasswordAndSalt {
    [[NSException exceptionWithName:@"FZAKeyManagerAbstractClassException" reason:@"Use +[FZAKeyManager newKeyManager] to get an appropriate subclass" userInfo:nil] raise];
}

+ (FZAKeyManager *)newKeyManager {
    id keyManager = nil;
#if TARGET_OS_IPHONE
    keyManager = [[FZAKeyManageriPhone alloc] init];
#else
    keyManager = [[FZAKeyManagerMac alloc] init];
#endif
    return keyManager;
}

- (id)init {
    self = [super init];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}


@end