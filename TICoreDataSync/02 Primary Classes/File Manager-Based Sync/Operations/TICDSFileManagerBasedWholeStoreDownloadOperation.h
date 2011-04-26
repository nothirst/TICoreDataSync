//
//  TICDSFileManagerBasedWholeStoreDownloadOperation.h
//  ShoppingListMac
//
//  Created by Tim Isted on 26/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICDSWholeStoreDownloadOperation.h"


@interface TICDSFileManagerBasedWholeStoreDownloadOperation : TICDSWholeStoreDownloadOperation {
@private
    NSString *_thisDocumentWholeStoreDirectoryPath;
}

- (NSString *)pathToWholeStoreFileForClientWithIdentifier:(NSString *)anIdentifier;
- (NSString *)pathToAppliedSyncChangesFileForClientWithIdentifier:(NSString *)anIdentifier;

@property (retain) NSString *thisDocumentWholeStoreDirectoryPath;

@end
