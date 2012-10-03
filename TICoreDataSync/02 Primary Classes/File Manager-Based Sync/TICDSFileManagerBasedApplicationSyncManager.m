//
//  TICDSFileManagerBasedApplicationSyncManager.m
//  ShoppingListMac
//
//  Created by Tim Isted on 22/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICoreDataSync.h"

#ifdef __MAC_OS_X_VERSION_MIN_REQUIRED
#import <pwd.h>
#endif

@implementation TICDSFileManagerBasedApplicationSyncManager

#pragma mark - Dropbox-Related Methods
+ (NSString *)stringByDecodingBase64EncodedString:(NSString *)encodedString {
    if( !encodedString ) {
        return nil;
    }
    
    NSMutableData *data = nil;
    unsigned long indexInText = 0, textLength = 0;
    unsigned char character = 0, inBuffer[4] = {0,0,0,0}, outBuffer[3] = {0,0,0};
    short i = 0, indexInBuffer = 0;
    BOOL isEndOfText = NO;
    NSData *base64Data = nil;
    const unsigned char *base64Bytes = nil;
    
    base64Data = [encodedString dataUsingEncoding:NSASCIIStringEncoding];
    base64Bytes = [base64Data bytes];
    textLength = [base64Data length];
    data = [NSMutableData dataWithCapacity:textLength];
    
    while( YES ) {
        if( indexInText >= textLength ) {
            break;
        }
        
        character = base64Bytes[indexInText++];
        
        if( ( character >= 'A' ) && ( character <= 'Z' ) ) { character = character - 'A'; }
        else if( ( character >= 'a' ) && ( character <= 'z' ) ) { character = character - 'a' + 26; }
        else if( ( character >= '0' ) && ( character <= '9' ) ) { character = character - '0' + 52; }
        else if( character == '+' ) { character = 62; }
        else if( character == '=' ) { isEndOfText = YES; }
        else if( character == '/' ) { character = 63; }
        else { // ignore everything else
            continue; 
        }
        
        short numberOfCharactersInBuffer = 3;
        BOOL isFinished = NO;

        if( isEndOfText ) {
            if( !indexInBuffer ) { break; }
            if( ( indexInBuffer == 1 ) || ( indexInBuffer == 2 ) ) { numberOfCharactersInBuffer = 1; }
            else { numberOfCharactersInBuffer = 2; }
            indexInBuffer = 3;
            isFinished = YES;
        }

        inBuffer[indexInBuffer++] = character;

        if( indexInBuffer == 4 ) {
            indexInBuffer = 0;
            outBuffer [0] = ( inBuffer[0] << 2 ) | ( ( inBuffer[1] & 0x30) >> 4 );
            outBuffer [1] = ( ( inBuffer[1] & 0x0F ) << 4 ) | ( ( inBuffer[2] & 0x3C ) >> 2 );
            outBuffer [2] = ( ( inBuffer[2] & 0x03 ) << 6 ) | ( inBuffer[3] & 0x3F );

            for( i = 0; i < numberOfCharactersInBuffer; i++ ) {
                [data appendBytes:&outBuffer[i] length:1];
            }
        }

        if( isFinished ) { break; }
    }
    
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

+ (NSURL *)localDropboxDirectoryLocation
{
    char *homeDirectory = nil;
    
#ifdef __MAC_OS_X_VERSION_MIN_REQUIRED
    homeDirectory = getpwuid(getuid())->pw_dir;
#endif
    NSString *actualHomeDirectory = [NSString stringWithCString:homeDirectory encoding:NSUTF8StringEncoding];
    NSString *dropboxHostDbPath = [actualHomeDirectory stringByAppendingFormat:@"/.dropbox/host.db"];
    
    dropboxHostDbPath = [dropboxHostDbPath stringByExpandingTildeInPath];
    
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    
    if( ![fileManager fileExistsAtPath:dropboxHostDbPath] ) {
        return nil;
    }
    
    NSData *hostDbData = [NSData dataWithContentsOfFile:dropboxHostDbPath];
    
    if( !hostDbData ) {
        return nil;
    }
    
    NSString *hostDbContents = [[NSString alloc] initWithData:hostDbData encoding:NSUTF8StringEncoding];
    
    NSScanner *scanner = [[NSScanner alloc] initWithString:hostDbContents];
    
    [scanner scanUpToCharactersFromSet:[NSCharacterSet newlineCharacterSet] intoString:nil];
    
    NSString *dropboxLocation = nil;
    [scanner scanUpToCharactersFromSet:[NSCharacterSet newlineCharacterSet] intoString:&dropboxLocation];
    
    
    dropboxLocation = [self stringByDecodingBase64EncodedString:dropboxLocation];
    
    if( !dropboxLocation ) {
        return nil;
    }
    
    return [NSURL fileURLWithPath:dropboxLocation];
}

#pragma mark - Overridden Methods

- (TICDSApplicationRegistrationOperation *)applicationRegistrationOperation
{
    TICDSFileManagerBasedApplicationRegistrationOperation *operation = [[TICDSFileManagerBasedApplicationRegistrationOperation alloc] initWithDelegate:self];
    
    [operation setApplicationDirectoryPath:[self applicationDirectoryPath]];
    [operation setEncryptionDirectorySaltDataFilePath:[self encryptionDirectorySaltDataFilePath]];
    [operation setEncryptionDirectoryTestDataFilePath:[self encryptionDirectoryTestDataFilePath]];
    [operation setClientDevicesDirectoryPath:[self clientDevicesDirectoryPath]];
    [operation setClientDevicesThisClientDeviceDirectoryPath:[self clientDevicesThisClientDeviceDirectoryPath]];
    
    return operation;
}

- (TICDSListOfPreviouslySynchronizedDocumentsOperation *)listOfPreviouslySynchronizedDocumentsOperation
{
    TICDSFileManagerBasedListOfPreviouslySynchronizedDocumentsOperation *operation = [[TICDSFileManagerBasedListOfPreviouslySynchronizedDocumentsOperation alloc] initWithDelegate:self];
    
    [operation setDocumentsDirectoryPath:[self documentsDirectoryPath]];
    
    return operation;
}

- (TICDSWholeStoreDownloadOperation *)wholeStoreDownloadOperationForDocumentWithIdentifier:(NSString *)anIdentifier
{
    TICDSFileManagerBasedWholeStoreDownloadOperation *operation = [[TICDSFileManagerBasedWholeStoreDownloadOperation alloc] initWithDelegate:self];
    
    [operation setThisDocumentDirectoryPath:[[self documentsDirectoryPath] stringByAppendingPathComponent:anIdentifier]];
    [operation setThisDocumentWholeStoreDirectoryPath:[self pathToWholeStoreDirectoryForDocumentWithIdentifier:anIdentifier]];
    
    return operation;
}

- (TICDSListOfApplicationRegisteredClientsOperation *)listOfApplicationRegisteredClientsOperation
{
    TICDSFileManagerBasedListOfApplicationRegisteredClientsOperation *operation = [[TICDSFileManagerBasedListOfApplicationRegisteredClientsOperation alloc] initWithDelegate:self];
    
    [operation setClientDevicesDirectoryPath:[self clientDevicesDirectoryPath]];
    [operation setDocumentsDirectoryPath:[self documentsDirectoryPath]];
    return operation;
}

- (TICDSDocumentDeletionOperation *)documentDeletionOperationForDocumentWithIdentifier:(NSString *)anIdentifier
{
    TICDSFileManagerBasedDocumentDeletionOperation *operation = [[TICDSFileManagerBasedDocumentDeletionOperation alloc] initWithDelegate:self];
    
    [operation setDocumentDirectoryPath:[[self documentsDirectoryPath] stringByAppendingPathComponent:anIdentifier]];
    [operation setDeletedDocumentsDirectoryIdentifierPlistFilePath:[[self deletedDocumentsDirectoryPath] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.%@", anIdentifier, TICDSDocumentInfoPlistExtension]]];
    [operation setDocumentInfoPlistFilePath:[[[self documentsDirectoryPath] stringByAppendingPathComponent:anIdentifier] stringByAppendingPathComponent:TICDSDocumentInfoPlistFilenameWithExtension]];
    
    return operation;
}

- (TICDSRemoveAllRemoteSyncDataOperation *)removeAllSyncDataOperation
{
    TICDSFileManagerBasedRemoveAllRemoteSyncDataOperation *operation = [[TICDSFileManagerBasedRemoveAllRemoteSyncDataOperation alloc] initWithDelegate:self];
    
    [operation setApplicationDirectoryPath:[self applicationDirectoryPath]];
    
    return operation;
}

#pragma mark - Paths
- (NSString *)applicationDirectoryPath
{
    return [[[self applicationContainingDirectoryLocation] path] stringByAppendingPathComponent:[self appIdentifier]];
}

- (NSString *)deletedDocumentsDirectoryPath
{
    return [[self applicationDirectoryPath] stringByAppendingPathComponent:[self relativePathToInformationDeletedDocumentsDirectory]];
}

- (NSString *)encryptionDirectorySaltDataFilePath
{
    return [[self applicationDirectoryPath] stringByAppendingPathComponent:[self relativePathToEncryptionDirectorySaltDataFilePath]];
}

- (NSString *)encryptionDirectoryTestDataFilePath
{
    return [[self applicationDirectoryPath] stringByAppendingPathComponent:[self relativePathToEncryptionDirectoryTestDataFilePath]];
}

- (NSString *)documentsDirectoryPath
{
    return [[self applicationDirectoryPath] stringByAppendingPathComponent:[self relativePathToDocumentsDirectory]];
}

- (NSString *)clientDevicesDirectoryPath
{
    return [[self applicationDirectoryPath] stringByAppendingPathComponent:[self relativePathToClientDevicesDirectory]];
}

- (NSString *)clientDevicesThisClientDeviceDirectoryPath
{
    return [[self applicationDirectoryPath] stringByAppendingPathComponent:[self relativePathToClientDevicesThisClientDeviceDirectory]];
}

- (NSString *)pathToWholeStoreDirectoryForDocumentWithIdentifier:(NSString *)anIdentifier
{
    return [[self applicationDirectoryPath] stringByAppendingPathComponent:[self relativePathToWholeStoreDirectoryForDocumentWithIdentifier:anIdentifier]];
}

#pragma mark - Initialization and Deallocation
- (void)dealloc
{
    _applicationContainingDirectoryLocation = nil;

}

#pragma mark - Properties
@synthesize applicationContainingDirectoryLocation = _applicationContainingDirectoryLocation;

@end
