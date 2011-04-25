//
//  TICDSFileManagerBasedWholeStoreUploadOperation.m
//  ShoppingListMac
//
//  Created by Tim Isted on 25/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICoreDataSync.h"


@implementation TICDSFileManagerBasedWholeStoreUploadOperation

#pragma mark -
#pragma mark Initialization and Deallocation
- (void)dealloc
{
    [_thisDocumentWholeStoreThisClientDirectoryPath release], _thisDocumentWholeStoreThisClientDirectoryPath = nil;
    [_thisDocumentWholeStoreThisClientDirectoryWholeStoreFilePath release], _thisDocumentWholeStoreThisClientDirectoryWholeStoreFilePath = nil;
    [_thisDocumentWholeStoreThisClientDirectoryAppliedSyncChangeSetsFilePath release], _thisDocumentWholeStoreThisClientDirectoryAppliedSyncChangeSetsFilePath = nil;

    [super dealloc];
}

#pragma mark -
#pragma mark Properties
@synthesize thisDocumentWholeStoreThisClientDirectoryPath = _thisDocumentWholeStoreThisClientDirectoryPath;
@synthesize thisDocumentWholeStoreThisClientDirectoryWholeStoreFilePath = _thisDocumentWholeStoreThisClientDirectoryWholeStoreFilePath;
@synthesize thisDocumentWholeStoreThisClientDirectoryAppliedSyncChangeSetsFilePath = _thisDocumentWholeStoreThisClientDirectoryAppliedSyncChangeSetsFilePath;

@end
