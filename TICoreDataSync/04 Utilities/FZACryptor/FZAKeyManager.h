//
// FZAKeyManager.h
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

#import <Foundation/Foundation.h>

/** `FZAKeyManager` is an abstract class for creating and managing encryption keys.
 
 This class should be inherited to provide cryptographic storage appropriate to the platform on which the library is running. */
@interface FZAKeyManager : NSObject {
@private
    
}

/** Report on whether the key manager already has a key to use. */
- (BOOL)hasKey;

/** Clear existing key chain items for password and salt. */
- (void)clearPasswordAndSalt;

/** Create some random data.
 
 @param length The number of bytes of randomness needed.
 
 @return The random data.
 
 @warning This method must be overridden by subclasses. */
- (NSData *)randomDataOfLength:(NSInteger)length;

/** Generate a key from a password. 
 
 This function is repeatable, in that the same password and salt always creates the same key. The key derived from the password is only stored on the local device, where the target data is already available in the clear - it never appears in the sync folder.
 
 @param password The string to use as the password.
 @param salt The salt data to use.
 
 @return A data key. */
- (NSData *)keyFromPassword:(NSString *)password salt:(NSData *)salt;

/** Set a new key derived from a password supplied by the user. 
 
 This key gets stored into whatever cryptographic storage is available on the target platform.
 
 @param password The string to use as the password.
 @param salt Some random data fed into the key derivation function.
 @param error Any error that occurs.
 
 @return `YES` if the key was stored succcessfully, `NO` if not (error will be set).
 
 @warning This method must be overridden by subclasses. */
- (BOOL)storeKeyDerivedFromPassword:(NSString *)password salt:(NSData *)salt error:(NSError **)error;

/** Retrieve and return the key from cryptographic storage.
 
 @warning This method must be overridden by subclasses. */
- (NSData *)key;

/** Return a new subclass of this class, appropriate to the current platform. */
+ (FZAKeyManager *)newKeyManager;

@end

typedef NS_ENUM(NSInteger, FZAKeyManagerKeyErrorCode) {
    FZAKeyManagerKeyStorageError
};
