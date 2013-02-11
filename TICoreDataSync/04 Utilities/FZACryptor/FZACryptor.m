//
// FZACryptor.m
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

#import "TICoreDataSync.h"
#import <CommonCrypto/CommonCryptor.h>
#import <CommonCrypto/CommonHMAC.h>

const NSInteger FZASaltLength = 16;
const NSInteger FZAFileBlockLength = 4096;

@implementation FZACryptor

#pragma mark Configuration of key material

- (BOOL)isConfigured
{
    return [keyManager hasKey];
}

- (void)clearPasswordAndSalt
{
    [keyManager clearPasswordAndSalt];
}

- (NSData *)setPassword:(NSString *)password salt:(NSData *)salt error:(NSError **)outError
{
    if (salt == nil) {
        salt = [keyManager randomDataOfLength:FZASaltLength];
        if (salt == nil) {
            return nil;
        }
    }

    NSError *error = nil;
    BOOL success = [keyManager storeKeyDerivedFromPassword:password salt:salt error:&error];

    if ( !success && outError ) {
        *outError = error;
        return nil;
    }

    return salt;
}

#pragma mark Crypto

- (BOOL)encryptFileAtLocation:(NSURL *)plainTextURL writingToLocation:(NSURL *)cipherTextURL error:(NSError **)error
{
    NSParameterAssert([plainTextURL isFileURL]);
    NSParameterAssert([cipherTextURL isFileURL]);
    if ([self isConfigured] == NO) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Our sync key was nil");
        if (error) {
            *error = [NSError errorWithDomain:FZACryptorErrorDomain
                                         code:FZACryptorErrorCodeFailedIntegrityCheck
                                     userInfo:nil];
        }
        return NO;
    }
    
    // set up the files
    NSFileHandle *readHandle = [NSFileHandle fileHandleForReadingAtPath:[plainTextURL path]];
    if (!readHandle) {
        return NO;
    }
    // unilaterally destroy anything already at the target location
    NSFileManager *mgr = [[NSFileManager alloc] init];
    BOOL fileCreated = [mgr createFileAtPath:[cipherTextURL path]
                                    contents:nil
                                  attributes:nil];
    NSDictionary *inputFileAttributes = [mgr attributesOfItemAtPath:[plainTextURL path]
                                                              error:error];
    if (inputFileAttributes == nil) {
        return NO;
    }
    unsigned long long inputFileLength = [inputFileAttributes fileSize];

    if (!fileCreated) {
        return NO;
    }
    NSFileHandle *writeHandle = [NSFileHandle fileHandleForWritingAtPath:[cipherTextURL path]];
    if (!writeHandle) {
        return NO;
    }
    uint8_t *bytesToWrite = malloc(FZAFileBlockLength);
    if (!bytesToWrite) {
        if (error) {
            *error = [NSError errorWithDomain:NSPOSIXErrorDomain code:errno userInfo:nil];
        }
        return NO;
    }

    // set up the crypto
    NSData *syncKey = [keyManager key];
    if (syncKey == nil || [syncKey bytes] == nil) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Our sync key was nil");
        if (error) {
            *error = [NSError errorWithDomain:FZACryptorErrorDomain
                                         code:FZACryptorErrorCodeFailedIntegrityCheck
                                     userInfo:nil];
        }
        return NO;
    }

    NSData *topLevelIV = [keyManager randomDataOfLength:kCCBlockSizeAES128];
    CCHmacContext hmacContext;
    CCHmacInit(&hmacContext, kCCHmacAlgSHA256, [syncKey bytes], [syncKey length]);
    CCHmacUpdate(&hmacContext, [topLevelIV bytes], [topLevelIV length]);
    [writeHandle writeData:topLevelIV];
    NSData *fileKeyAndIV = [keyManager randomDataOfLength:kCCKeySizeAES256 + kCCBlockSizeAES128];
    uint8_t cryptedKeyIV[kCCKeySizeAES256 + kCCBlockSizeAES128] = {
        0
    };
    size_t cryptedLength = 0;
    CCCryptorStatus status = CCCrypt(kCCEncrypt,
                                     kCCAlgorithmAES128,
                                     0,
                                     [syncKey bytes],
                                     [syncKey length],
                                     [topLevelIV bytes],
                                     [fileKeyAndIV bytes],
                                     [fileKeyAndIV length],
                                     cryptedKeyIV,
                                     kCCKeySizeAES256 + kCCBlockSizeAES128,
                                     &cryptedLength);
    if (status != kCCSuccess) {
        if (error) {
            *error = [NSError errorWithDomain:FZACryptorErrorDomain
                                         code:status
                                     userInfo:nil];
        }
        free(bytesToWrite);
        return NO;
    }
    NSData *outgoingData = [NSData dataWithBytesNoCopy:cryptedKeyIV
                                                length:cryptedLength
                                          freeWhenDone:NO];
    [writeHandle writeData:outgoingData];

    CCHmacUpdate(&hmacContext, [outgoingData bytes], [outgoingData length]);

    NSData *key = [NSData dataWithBytes:[fileKeyAndIV bytes] length:kCCKeySizeAES256];
    NSData *iv = [NSData dataWithBytes:[fileKeyAndIV bytes] + kCCKeySizeAES256
                                length:kCCBlockSizeAES128];
    CCCryptorRef cryptor = NULL;
    status = CCCryptorCreate(kCCEncrypt,
                             kCCAlgorithmAES128,
                             kCCOptionPKCS7Padding,
                             [key bytes],
                             [key length],
                             [iv bytes],
                             &cryptor);
    if (status != kCCSuccess) {
        if (error) {
            *error = [NSError errorWithDomain:FZACryptorErrorDomain code:status userInfo:nil];
        }
        free(bytesToWrite);
        return NO;
    }

    // do it!
    do {
        @autoreleasepool {
            NSData *dataRead = [readHandle readDataOfLength:FZAFileBlockLength];
            size_t bytesOut = 0;
            status = CCCryptorUpdate(cryptor,
                                     [dataRead bytes],
                                     [dataRead length],
                                     bytesToWrite,
                                     FZAFileBlockLength,
                                     &bytesOut);
            if (status != kCCSuccess) {
                if (error) {
                    *error = [NSError errorWithDomain:FZACryptorErrorDomain
                                                 code:status
                                             userInfo:nil];
                }
                free(bytesToWrite);
                return NO;
            }
            NSData *outData = [NSData dataWithBytesNoCopy:bytesToWrite
                                                   length:bytesOut
                                             freeWhenDone:NO];
            [writeHandle writeData:outData];
            CCHmacUpdate(&hmacContext, [outData bytes], [outData length]);
        }
    } while ([readHandle offsetInFile] < inputFileLength);

    size_t finalBlockSize = 0;
    status = CCCryptorFinal(cryptor,
                            bytesToWrite,
                            FZAFileBlockLength,
                            &finalBlockSize);
    if (status != kCCSuccess) {
        if (error) {
            *error = [NSError errorWithDomain:FZACryptorErrorDomain
                                         code:status
                                     userInfo:nil];
        }
        free(bytesToWrite);
        return NO;
    }
    CCCryptorRelease(cryptor);

    NSData *finalBlock = [NSData dataWithBytesNoCopy:bytesToWrite
                                              length:finalBlockSize
                                        freeWhenDone:NO];
    [writeHandle writeData:finalBlock];

    CCHmacUpdate(&hmacContext, [finalBlock bytes], [finalBlock length]);
    uint8_t hmac[CC_SHA256_DIGEST_LENGTH];
    CCHmacFinal(&hmacContext, hmac);
    NSData *hmacData = [NSData dataWithBytesNoCopy:hmac
                                            length:CC_SHA256_DIGEST_LENGTH
                                      freeWhenDone:NO];
    [writeHandle writeData:hmacData];

    free(bytesToWrite);
    [writeHandle closeFile];

    return YES;
}

- (BOOL)decryptFileAtLocation:(NSURL *)cipherTextURL writingToLocation:(NSURL *)plainTextURL error:(NSError **)error
{
    NSParameterAssert([cipherTextURL isFileURL]);
    NSParameterAssert([plainTextURL isFileURL]);

    // set up the files
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    NSFileHandle *readHandle = [NSFileHandle fileHandleForReadingAtPath:[cipherTextURL path]];
    if (readHandle == nil) {
        return NO;
    }

    NSDictionary *cipherFileAttributes = [fileManager attributesOfItemAtPath:[cipherTextURL path] error:error];
    if (cipherFileAttributes == nil) {
        return NO;
    }
    unsigned long long cipherSize = [cipherFileAttributes fileSize];

    // unilaterally destroy anything already at the target location
    BOOL fileCreated = [fileManager createFileAtPath:[plainTextURL path] contents:nil attributes:nil];
    if (fileCreated == NO) {
        return NO;
    }

    NSFileHandle *writeHandle = [NSFileHandle fileHandleForWritingAtPath:[plainTextURL path]];
    if (writeHandle == nil) {
        return NO;
    }

    /* first things first - we verify the HMAC. If that doesn't work, the file is
     * corrupt or has been tampered with: either way we can't use it. Note this means
     * we're going to have to read in the file's contents twice: that's just the way
     * it goes.
     */
    NSData *syncKey = [keyManager key];
    if (syncKey == nil || [syncKey bytes] == nil) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Our sync key was nil");
        if (error) {
            *error = [NSError errorWithDomain:FZACryptorErrorDomain
                                         code:FZACryptorErrorCodeFailedIntegrityCheck
                                     userInfo:nil];
        }
        return NO;
    }

    CCHmacContext hmacContext;
    CCHmacInit(&hmacContext, kCCHmacAlgSHA256, [syncKey bytes], [syncKey length]);
    do {
        @autoreleasepool {
            unsigned long long bytesRemaining = cipherSize - CC_SHA256_DIGEST_LENGTH - [readHandle offsetInFile];
            size_t bytesToRead = (bytesRemaining > FZAFileBlockLength) ?
                FZAFileBlockLength : (size_t)bytesRemaining;

            NSData *readData = nil;
            @try {
                readData = [readHandle readDataOfLength:bytesToRead];
            }
            @catch (NSException *exception) {
                TICDSLog(TICDSLogVerbosityErrorsOnly, @"Caught an exception while trying to read a file %@ %@, %@", [cipherTextURL path], exception.name, exception.reason);
                return NO;
            }
            @finally {}

            if ([readData bytes] == nil) {
                TICDSLog(TICDSLogVerbosityErrorsOnly, @"Read no bytes from the data");
                return NO;
            }

            CCHmacUpdate(&hmacContext, [readData bytes], [readData length]);
        }
    } while ([readHandle offsetInFile] < cipherSize - CC_SHA256_DIGEST_LENGTH);

    uint8_t hmac[CC_SHA256_DIGEST_LENGTH];
    CCHmacFinal(&hmacContext, hmac);
    NSData *calculatedHmac = [NSData dataWithBytesNoCopy:hmac
                                                  length:CC_SHA256_DIGEST_LENGTH
                                            freeWhenDone:NO];

    [readHandle seekToFileOffset:cipherSize - CC_SHA256_DIGEST_LENGTH];
    NSData *storedHmac = [readHandle readDataToEndOfFile];

    if (![storedHmac isEqualToData:calculatedHmac]) {
        if (error) {
            *error = [NSError errorWithDomain:FZACryptorErrorDomain
                                         code:FZACryptorErrorCodeFailedIntegrityCheck
                                     userInfo:nil];
        }
        return NO;
    }

    // decrypt the file key and IV
    [readHandle seekToFileOffset:0];
    NSData *topLevelIV = [readHandle readDataOfLength:kCCBlockSizeAES128];
    NSData *fileKeyAndIV = [readHandle readDataOfLength:kCCKeySizeAES256 + kCCBlockSizeAES128];
    uint8_t decryptedKeyAndIV[kCCKeySizeAES256 + kCCBlockSizeAES128] = {
        0
    };
    size_t plainLength = 0;
    CCCryptorStatus cryptResult = CCCrypt(kCCDecrypt,
                                          kCCAlgorithmAES128,
                                          0,
                                          [syncKey bytes],
                                          [syncKey length],
                                          [topLevelIV bytes],
                                          [fileKeyAndIV bytes],
                                          [fileKeyAndIV length],
                                          decryptedKeyAndIV,
                                          kCCKeySizeAES256 + kCCBlockSizeAES128,
                                          &plainLength);
    if (cryptResult != kCCSuccess) {
        if (error) {
            *error = [NSError errorWithDomain:FZACryptorErrorDomain
                                         code:cryptResult
                                     userInfo:nil];
        }
        return NO;
    }

    NSData *key = [NSData dataWithBytesNoCopy:decryptedKeyAndIV
                                       length:kCCKeySizeAES256
                                 freeWhenDone:NO];
    NSData *iv = [NSData dataWithBytesNoCopy:decryptedKeyAndIV + kCCKeySizeAES256
                                      length:kCCBlockSizeAES128
                                freeWhenDone:NO];

    // decrypt the file content.
    uint8_t *bytesToWrite = malloc(FZAFileBlockLength);
    CCCryptorRef cryptor = NULL;
    cryptResult = CCCryptorCreate(kCCDecrypt,
                                  kCCAlgorithmAES128,
                                  kCCOptionPKCS7Padding,
                                  [key bytes],
                                  [key length],
                                  [iv bytes],
                                  &cryptor);
    if (cryptResult != kCCSuccess) {
        if (error) {
            *error = [NSError errorWithDomain:FZACryptorErrorDomain
                                         code:cryptResult
                                     userInfo:nil];
        }
        free(bytesToWrite);
        return NO;
    }

    do {
        @autoreleasepool {
            unsigned long long bytesRemaining = cipherSize - CC_SHA256_DIGEST_LENGTH - [readHandle offsetInFile];
            size_t bytesToRead = (bytesRemaining > FZAFileBlockLength) ?
                FZAFileBlockLength : (size_t)bytesRemaining;
            size_t sizeToWrite = 0;
            NSData *readData = [readHandle readDataOfLength:bytesToRead];
            cryptResult = CCCryptorUpdate(cryptor,
                                          [readData bytes],
                                          [readData length],
                                          bytesToWrite,
                                          FZAFileBlockLength,
                                          &sizeToWrite);
            if (cryptResult != kCCSuccess) {
                if (error) {
                    *error = [NSError errorWithDomain:FZACryptorErrorDomain
                                                 code:cryptResult
                                             userInfo:nil];
                }
                free(bytesToWrite);
                return NO;
            }
            NSData *plainData = [NSData dataWithBytesNoCopy:bytesToWrite
                                                     length:sizeToWrite
                                               freeWhenDone:NO];
            [writeHandle writeData:plainData];
        }
    } while ([readHandle offsetInFile] < cipherSize - CC_SHA256_DIGEST_LENGTH);

    size_t finalBlockSize = 0;
    cryptResult = CCCryptorFinal(cryptor,
                                 bytesToWrite,
                                 FZAFileBlockLength,
                                 &finalBlockSize);
    if (cryptResult != kCCSuccess) {
        if (error) {
            *error = [NSError errorWithDomain:FZACryptorErrorDomain
                                         code:cryptResult
                                     userInfo:nil];
        }
        free(bytesToWrite);
        return NO;
    }
    NSData *finalData = [NSData dataWithBytesNoCopy:bytesToWrite
                                             length:finalBlockSize
                                       freeWhenDone:NO];
    free(bytesToWrite);
    [writeHandle writeData:finalData];
    [writeHandle closeFile];

    return YES;
}

#pragma mark Memory management
- (id)init
{
    self = [super init];
    if (self) {
        keyManager = [FZAKeyManager newKeyManager];
    }

    return self;
}

@end