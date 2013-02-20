//
//  TICDSiCloudBasedApplicationSyncManager.m
//  ShoppingListMac
//
//  Created by Tim Isted on 22/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICoreDataSync.h"

NSString * const TICDSApplicationSyncManagerDidRefreshCloudTransferProgressNotification = @"TICDSApplicationSyncManagerDidRefreshCloudTransferProgressNotification";

@interface TICDSiCloudBasedApplicationSyncManager ()

@property (nonatomic, retain) NSMetadataQuery *cloudMetadataQuery;

@end

@implementation TICDSiCloudBasedApplicationSyncManager

#pragma mark -
#pragma mark Dropbox-Related Methods
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
    NSString *dropboxHostDbPath = @"~/.dropbox/host.db";
    
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

#pragma mark -
#pragma mark Monitoring cloud metadata changes

- (void)configureWithDelegate:(id <TICDSApplicationSyncManagerDelegate>)aDelegate globalAppIdentifier:(NSString *)anAppIdentifier uniqueClientIdentifier:(NSString *)aClientIdentifier description:(NSString *)aClientDescription userInfo:(NSDictionary *)someUserInfo
{
    [super configureWithDelegate:aDelegate globalAppIdentifier:anAppIdentifier uniqueClientIdentifier:aClientIdentifier description:aClientDescription userInfo:someUserInfo];
    [self refreshCloudMetadataQuery];
}

- (void)setCloudMetadataQuery:(NSMetadataQuery *)newQuery
{
    if ( newQuery != _cloudMetadataQuery ) {
        if ( _cloudMetadataQuery ) {
            [[NSNotificationCenter defaultCenter] removeObserver:self name:NSMetadataQueryDidUpdateNotification object:_cloudMetadataQuery];
            [[NSNotificationCenter defaultCenter] removeObserver:self name:NSMetadataQueryDidFinishGatheringNotification object:_cloudMetadataQuery];
            [_cloudMetadataQuery stopQuery];
        }
        _cloudMetadataQuery = newQuery;
        if ( newQuery ) {
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cloudFilesDidChange:) name:NSMetadataQueryDidFinishGatheringNotification object:newQuery];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cloudFilesDidChange:) name:NSMetadataQueryDidUpdateNotification object:newQuery];
            if ( ![_cloudMetadataQuery startQuery] ) NSLog(@"Failed to start cloud NSMetadataQuery");
        }
    }
}

- (void)refreshCloudMetadataQuery
{
    NSMetadataQuery *newQuery = [[NSMetadataQuery alloc] init];
    newQuery.searchScopes = [NSArray arrayWithObject:NSMetadataQueryUbiquitousDataScope];
    newQuery.predicate = [NSPredicate predicateWithFormat:@"%K like '*'", NSMetadataItemFSNameKey];
    newQuery.notificationBatchingInterval = 60.0;
    self.cloudMetadataQuery = newQuery;
}

- (void)initiateDownloadsForURLs:(NSArray *)urls
{
    NSFileManager *fm = [[NSFileManager alloc] init];
    for ( NSURL *url in urls ) {
        // Download files that are not yet downloaded
        NSNumber *downloaded = nil, *downloading = nil;
        NSError *error = nil;
        BOOL success = [url getResourceValue:&downloaded forKey:NSURLUbiquitousItemIsDownloadedKey error:&error];
        if ( success ) success = [url getResourceValue:&downloading forKey:NSURLUbiquitousItemIsDownloadingKey error:&error];
        if ( success && !downloaded.boolValue && !downloading.boolValue ) {
            [fm startDownloadingUbiquitousItemAtURL:url error:NULL];
        }
    }
}

- (void)checkUninitiatedUploadsForURLs:(NSArray *)urls
{
    NSFileManager *fm = [[NSFileManager alloc] init];
    
    // Create temporary directory for moved aside files
    NSString *tempFilename = [NSString stringWithFormat:@"MovedAsideCloudFiles_%@", [[NSProcessInfo processInfo] globallyUniqueString]];
    NSString *tempDirPath = [NSTemporaryDirectory() stringByAppendingPathComponent:tempFilename];
    if ( ![fm createDirectoryAtPath:tempDirPath withIntermediateDirectories:YES attributes:nil error:NULL] ) return;
    
    // Check for files that should be uploaded, but have gotten 'stuck'.
    const NSTimeInterval ReuploadTimeInterval = 30*60; // 30 minutes
    for ( NSURL *url in urls ) {
        @autoreleasepool {
            NSDictionary *fileAttributes = [fm attributesOfItemAtPath:url.path error:NULL];
            if ( [fileAttributes[NSFileType] isEqualToString:NSFileTypeDirectory] ) continue; // Ignore directories
            
            // Check if file is uploading or uploaded. If not, check how long it has been 'dormant'.
            // If it is taking too long, try to jolt by removing it from iCloud, and putting it back in.
            NSNumber *uploaded = nil, *uploading = nil;
            [url getResourceValue:&uploaded forKey:NSURLUbiquitousItemIsUploadedKey error:NULL];
            [url getResourceValue:&uploading forKey:NSURLUbiquitousItemIsUploadingKey error:NULL];
            if ( (uploaded && !uploaded.boolValue) && (uploading && !uploading.boolValue) ) {
                NSDate *modifiedDate = nil;
                BOOL success = [url getResourceValue:&modifiedDate forKey:NSURLContentModificationDateKey error:NULL];
                BOOL fileIsOverdue = [modifiedDate timeIntervalSinceNow] < -ReuploadTimeInterval;
                if ( !success || modifiedDate == nil || fileIsOverdue ) {
                    BOOL uploadStarted = [fm startDownloadingUbiquitousItemAtURL:url error:NULL]; // This triggers a sync with the server
                    if ( !uploadStarted || fileIsOverdue ) {
                        // Copy file out of container, and then back in
                        NSString *tempFilePath = [tempDirPath stringByAppendingPathComponent:url.lastPathComponent];
                        NSURL *tempURL = [NSURL fileURLWithPath:tempFilePath];
                        
                        __block NSError *anyError = nil;
                        __block BOOL success = NO;
                        NSFileCoordinator *fileCoordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
                        
                        void (^swapOutAndInBlock)(NSURL *, NSURL *) = ^(NSURL *newURL, NSURL *newTempURL) {
                            [fm removeItemAtURL:newTempURL error:NULL];
                            success = [fm copyItemAtURL:newURL toURL:newTempURL error:NULL];
                            if ( !success ) return;
                            
                            [fm removeItemAtURL:newURL error:NULL];
                            [fm moveItemAtURL:newTempURL toURL:newURL error:NULL];
                        };
                        
                        [fileCoordinator coordinateWritingItemAtURL:url options:NSFileCoordinatorWritingForReplacing writingItemAtURL:tempURL options:NSFileCoordinatorWritingForReplacing error:&anyError byAccessor:swapOutAndInBlock];
                        if ( anyError ) swapOutAndInBlock(url, tempURL); // Attempt to force it
                    }
                }
            }
        }
    }
    
    [fm removeItemAtPath:tempDirPath error:NULL];
}

- (void)cloudFilesDidChange:(NSNotification *)notif
{
    [self.cloudMetadataQuery disableUpdates];
    
    NSUInteger count = [self.cloudMetadataQuery resultCount];
    NSMutableArray *urls = [NSMutableArray arrayWithCapacity:count];
    for ( NSUInteger i = 0; i < count; i++ ) {
        NSURL *url = [self.cloudMetadataQuery valueOfAttribute:NSMetadataItemURLKey forResultAtIndex:i];
        [urls addObject:url];
    }
    
    // Process in background. Can be expensive
    dispatch_queue_t queue = dispatch_queue_create("startdownloads", DISPATCH_QUEUE_SERIAL);
    dispatch_async(queue, ^{
        [self initiateDownloadsForURLs:urls];
        [self checkUninitiatedUploadsForURLs:urls];

        dispatch_async(dispatch_get_main_queue(), ^{
            [self.cloudMetadataQuery enableUpdates];
        });
        
        dispatch_release(queue);
    });
}


#pragma mark -
#pragma mark Overridden Methods

- (TICDSApplicationRegistrationOperation *)applicationRegistrationOperation
{
    TICDSiCloudBasedApplicationRegistrationOperation *operation = [[TICDSiCloudBasedApplicationRegistrationOperation alloc] initWithDelegate:self];
    
    [operation setApplicationDirectoryPath:[self applicationDirectoryPath]];
    [operation setEncryptionDirectorySaltDataFilePath:[self encryptionDirectorySaltDataFilePath]];
    [operation setEncryptionDirectoryTestDataFilePath:[self encryptionDirectoryTestDataFilePath]];
    [operation setClientDevicesDirectoryPath:[self clientDevicesDirectoryPath]];
    [operation setClientDevicesThisClientDeviceDirectoryPath:[self clientDevicesThisClientDeviceDirectoryPath]];
    
    return operation;
}

- (TICDSListOfPreviouslySynchronizedDocumentsOperation *)listOfPreviouslySynchronizedDocumentsOperation
{
    TICDSiCloudBasedListOfPreviouslySynchronizedDocumentsOperation *operation = [[TICDSiCloudBasedListOfPreviouslySynchronizedDocumentsOperation alloc] initWithDelegate:self];
    
    [operation setDocumentsDirectoryPath:[self documentsDirectoryPath]];
    
    return operation;
}

- (TICDSWholeStoreDownloadOperation *)wholeStoreDownloadOperationForDocumentWithIdentifier:(NSString *)anIdentifier
{
    TICDSiCloudBasedWholeStoreDownloadOperation *operation = [[TICDSiCloudBasedWholeStoreDownloadOperation alloc] initWithDelegate:self];
    
    [operation setThisDocumentDirectoryPath:[[self documentsDirectoryPath] stringByAppendingPathComponent:anIdentifier]];
    [operation setThisDocumentWholeStoreDirectoryPath:[self pathToWholeStoreDirectoryForDocumentWithIdentifier:anIdentifier]];
    
    return operation;
}

- (TICDSListOfApplicationRegisteredClientsOperation *)listOfApplicationRegisteredClientsOperation
{
    TICDSiCloudBasedListOfApplicationRegisteredClientsOperation *operation = [[TICDSiCloudBasedListOfApplicationRegisteredClientsOperation alloc] initWithDelegate:self];
    
    [operation setClientDevicesDirectoryPath:[self clientDevicesDirectoryPath]];
    [operation setDocumentsDirectoryPath:[self documentsDirectoryPath]];
    return operation;
}

- (TICDSDocumentDeletionOperation *)documentDeletionOperationForDocumentWithIdentifier:(NSString *)anIdentifier
{
    TICDSiCloudBasedDocumentDeletionOperation *operation = [[TICDSiCloudBasedDocumentDeletionOperation alloc] initWithDelegate:self];
    
    [operation setDocumentDirectoryPath:[[self documentsDirectoryPath] stringByAppendingPathComponent:anIdentifier]];
    [operation setDeletedDocumentsDirectoryIdentifierPlistFilePath:[[self deletedDocumentsDirectoryPath] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.%@", anIdentifier, TICDSDocumentInfoPlistExtension]]];
    [operation setDocumentInfoPlistFilePath:[[[self documentsDirectoryPath] stringByAppendingPathComponent:anIdentifier] stringByAppendingPathComponent:TICDSDocumentInfoPlistFilenameWithExtension]];
    
    return operation;
}

- (TICDSRemoveAllRemoteSyncDataOperation *)removeAllSyncDataOperation
{
    TICDSiCloudBasedRemoveAllRemoteSyncDataOperation *operation = [[TICDSiCloudBasedRemoveAllRemoteSyncDataOperation alloc] initWithDelegate:self];
    
    [operation setApplicationDirectoryPath:[self applicationDirectoryPath]];
    
    return operation;
}

#pragma mark -
#pragma mark Paths
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

#pragma mark -
#pragma mark Initialization and Deallocation

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_cloudMetadataQuery disableUpdates];
    [_cloudMetadataQuery stopQuery];
    _cloudMetadataQuery = nil;
}

#pragma mark -
#pragma mark Properties
@synthesize applicationContainingDirectoryLocation = _applicationContainingDirectoryLocation;
@synthesize cloudMetadataQuery = _cloudMetadataQuery;

@end
