//
// FZACryptor.h
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

@class FZAKeyManager;

/** `FZACryptor` is the public interface to the `TICoreDataSync` encryption module. */
@interface FZACryptor : NSObject {
@private
    FZAKeyManager *keyManager;
}

/** @name Configuration */

/** Reports whether this object has already got a key and can be used for crypto operations.
 
 If this method returns `NO`, the app should get a password from the user and call `setPassword:salt:`.
 
 @return `YES` if the object is ready to be used for crypto, otherwise `NO`. */
- (BOOL)isConfigured;

/** Set a new password to be used for protecting the encrypted content. 
 
 This can either be used to initially configure the cryptography, or unilaterally change the password (without doing any re-encryption of existing data) at a later time.
 
 @param password The password to use.
 @param salt Some random data to salt the password. If this is `nil`, the method will
             generate its own salt from a random oracle.
 @param outError A pointer to an `NSError` that will be set if the data cannot be generated.
 
 @return The data used for salting the password. If this object needed to create salt material and couldn't, it will return `nil`. In this case, the key used for encryption has not been set, and the object is not configured.
 
 @warning This class uses the keychain for secure storage, so it's possible for a newly-created instance not to need a password if the key material has already been created. Check `isConfigured` to see whether this is the case. */
- (NSData *)setPassword: (NSString *)password salt: (NSData *)salt error: (NSError **)outError;

/** Clears any previously-existing keychain password and salt. */
- (void)clearPasswordAndSalt;

/** @name Encryption and Decryption */

/** Encrypt the content of a file, storing the encrypted data in another file.
 
 The file format is like this, where the numbers are byte indices:
     0-15           An IV used to protect the first block of file key and IV.
     16-63          The file key and IV, which have been encrypted by the sync key.
     64-(end-32)    The file content, encrypted by the file key.
     (end-32)-end   A SHA-256 HMAC derived using the sync key.
 
 @param plainTextURL The URL of the file to be encrypted.
 @param cipherTextURL The URL of the file to write the encrypted file. Any existing content will be blindly truncated.
 @param error Possible errors include no password being configured or the keychain item being corrupted, or not being able to read from the source or  write to the destination. The error codes come from `CommonCrypto/CommonCryptor.h`.
 
 @return `YES` if the encryption succeeds, otherwise `NO` and the error is set.
 
 @warning Any exceptions encountered in dealing with the filesystem will be propagated to the calling code. It is therefore up to the calling code to make sure it's working with a reliable filesystem, or to handle exceptions occurring in here. */
- (BOOL)encryptFileAtLocation: (NSURL *)plainTextURL writingToLocation: (NSURL *)cipherTextURL error: (NSError **)error;

/** Decrypt the content of a file, storing the clear-text data in another file.
 
 @param cipherTextURL The file to be decrypted.
 @param plainTextURL The location to write the decrypted file. Any existing content will be blindly truncated.
 @param error Possible errors include no password being configured or the keychain item being corrupted, not being able to read from the source or write to the destination, or the cipher text file not being in the expected format. Errors come either from `CommonCrypto/CommonCryptor.h` or from the enumeration at the end of `TICDSTypesAndEnums.h`.
 
 @return `YES` if the decryption succeeds, otherwise `NO` and the error is set.
 
 @warning Any exceptions encountered in dealing with the filesystem will be propagated to the calling code. It is therefore up to the calling code to make sure it's working with a reliable filesystem, or to handle exceptions occurring in here. */
- (BOOL)decryptFileAtLocation: (NSURL *)cipherTextURL writingToLocation: (NSURL *)plainTextURL error: (NSError **)error;
@end