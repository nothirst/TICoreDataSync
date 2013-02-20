// Copyright (c) 2013 Drew McCormack
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

#import "TIUbiquityMonitor.h"

@implementation TIUbiquityMonitor {
    NSMetadataQuery *metadataQuery;
    void (^progressCallbackBlock)(long long toDownload, long long toUpload);
}

@synthesize ubiquitousBytesToDownload = ubiquitousBytesToDownload;
@synthesize ubiquitousBytesToUpload = ubiquitousBytesToUpload;
@synthesize predicate = predictate;
@synthesize initiateTransfers = initiateTransfers;
@synthesize isMonitoring = isMonitoring;

#pragma mark Initialization and Deallocation

- (id)initWithPredicate:(NSPredicate *)newPredicate
{
    self = [super init];
    if ( self ) {
        predictate = newPredicate;
        progressCallbackBlock = NULL;
        isMonitoring = NO;
        initiateTransfers = NO;
        metadataQuery = nil;
        ubiquitousBytesToUpload = ubiquitousBytesToDownload = 0;
    }
    return self;
}

- (id)init
{
    NSPredicate *newPredicate = [NSPredicate predicateWithFormat:@"%K = FALSE OR %K = FALSE", NSMetadataUbiquitousItemIsDownloadedKey, NSMetadataUbiquitousItemIsUploadedKey];
    return [self initWithPredicate:newPredicate];
}

- (void)dealloc
{
    [self stopMonitoring];
}

#pragma mark Controlling Monitoring

- (void)startMonitoringWithProgressBlock:(void(^)(long long toDownload, long long toUpload))block
{
    if ( isMonitoring ) @throw [NSException exceptionWithName:@"TIException" reason:@"Attempt to start monitoring in a TIUbiquityMonitor that is already monitoring" userInfo:nil];
    
    isMonitoring = YES;
    
    progressCallbackBlock = [block copy];

    metadataQuery = [[NSMetadataQuery alloc] init];
    metadataQuery.notificationBatchingInterval = 1.0;
    metadataQuery.searchScopes = [NSArray arrayWithObject:NSMetadataQueryUbiquitousDataScope];
    metadataQuery.predicate = predictate;
    
    NSNotificationCenter *notifationCenter = [NSNotificationCenter defaultCenter];
    [notifationCenter addObserver:self selector:@selector(update:) name:NSMetadataQueryDidFinishGatheringNotification object:metadataQuery];
    [notifationCenter addObserver:self selector:@selector(update:) name:NSMetadataQueryDidUpdateNotification object:metadataQuery];
    
    [metadataQuery startQuery];
}

- (void)scheduleRefresh
{
    [self.class cancelPreviousPerformRequestsWithTarget:self selector:@selector(refreshIfStale) object:nil];
    [self performSelector:@selector(refreshIfStale) withObject:nil afterDelay:5.0];
}

- (void)refreshIfStale
{
    id block = progressCallbackBlock;
    [self stopMonitoring];
    [self startMonitoringWithProgressBlock:block];
}

- (void)stopMonitoring
{
    [metadataQuery disableUpdates];
    
    [self.class cancelPreviousPerformRequestsWithTarget:self selector:@selector(refreshIfStale) object:nil];

    isMonitoring = NO;
        
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSMetadataQueryDidFinishGatheringNotification object:metadataQuery];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSMetadataQueryDidUpdateNotification object:metadataQuery];
    
    [metadataQuery stopQuery];
    metadataQuery = nil;
    
    // Release callback last, because it could be retaining objects
    progressCallbackBlock = NULL;
}

- (void)update:(NSNotification *)notif
{
    [metadataQuery disableUpdates];
    
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    NSUInteger count = [metadataQuery resultCount];
    long long toDownload = 0, toUpload = 0;
    for ( NSUInteger i = 0; i < count; i++ ) {
        NSURL *url = [metadataQuery valueOfAttribute:NSMetadataItemURLKey forResultAtIndex:i];
        
        NSNumber *percentDownloaded = [metadataQuery valueOfAttribute:NSMetadataUbiquitousItemPercentDownloadedKey forResultAtIndex:i];
        NSNumber *percentUploaded = [metadataQuery valueOfAttribute:NSMetadataUbiquitousItemPercentUploadedKey forResultAtIndex:i];;
        NSNumber *downloaded = [metadataQuery valueOfAttribute:NSMetadataUbiquitousItemIsDownloadedKey forResultAtIndex:i];
        NSNumber *uploaded = [metadataQuery valueOfAttribute:NSMetadataUbiquitousItemIsUploadedKey forResultAtIndex:i];
        NSNumber *fileSizeNumber = [metadataQuery valueOfAttribute:NSMetadataItemFSSizeKey forResultAtIndex:i];

        unsigned long long fileSize = fileSizeNumber ? fileSizeNumber.unsignedLongLongValue : 0;
        if ( downloaded && !downloaded.boolValue ) {
            double percentage = percentDownloaded ? percentDownloaded.doubleValue : 0.0;
            long long fileDownloadSize = (1.0 - percentage / 100.0) * fileSize;
            toDownload += fileDownloadSize;
            
            // Start download
            NSError *error = nil;
            if ( initiateTransfers && percentage < 1.e-6 && ![fileManager startDownloadingUbiquitousItemAtURL:url error:&error] ) NSLog(@"Failed to initiate download with error: %@", error);
        }
        else if ( uploaded && !uploaded.boolValue ) {
            double percentage = percentUploaded ? percentUploaded.doubleValue : 0.0;
            long long fileDownloadSize = (1.0 - percentage / 100.0) * fileSize;
            toUpload += fileDownloadSize;
            
            // Force upload
            NSError *error = nil;
            if ( initiateTransfers && percentage < 1.e-6 && ![fileManager startDownloadingUbiquitousItemAtURL:url error:&error] ) NSLog(@"Failed to initiate upload with error: %@", error);
        }
    }
    
    ubiquitousBytesToDownload = toDownload;
    ubiquitousBytesToUpload = toUpload;
    
    if ( progressCallbackBlock ) progressCallbackBlock(ubiquitousBytesToDownload, ubiquitousBytesToUpload);
    
    [metadataQuery enableUpdates];
    
    [self scheduleRefresh];
}

@end

