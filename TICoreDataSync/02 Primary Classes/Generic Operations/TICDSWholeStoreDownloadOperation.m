//
//  TICDSWholeStoreDownloadOperation.m
//  ShoppingListMac
//
//  Created by Tim Isted on 25/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICoreDataSync.h"


@implementation TICDSWholeStoreDownloadOperation

#pragma mark -
#pragma mark Initialization and Deallocation
- (void)dealloc
{
    [_localWholeStoreFileLocation release], _localWholeStoreFileLocation = nil;
    [_localAppliedSyncChangeSetsFileLocation release], _localAppliedSyncChangeSetsFileLocation = nil;
    
    [super dealloc];
}

#pragma mark -
#pragma mark Properties
@synthesize localWholeStoreFileLocation = _localWholeStoreFileLocation;
@synthesize localAppliedSyncChangeSetsFileLocation = _localAppliedSyncChangeSetsFileLocation;
@synthesize completionInProgress = _completionInProgress;
@synthesize wholeStoreFileDownloadStatus = _wholeStoreFileDownloadStatus;
@synthesize appliedSyncChangeSetsFileDownloadStatus = _appliedSyncChangeSetsFileDownloadStatus;

@end
