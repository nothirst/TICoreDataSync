//
//  TICDSFileManagerBasedDocumentSyncManager.h
//  ShoppingListMac
//
//  Created by Tim Isted on 22/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICDSDocumentSyncManager.h"


@interface TICDSFileManagerBasedDocumentSyncManager : TICDSDocumentSyncManager {
@private
    NSURL *_applicationDirectoryLocation;
}

@property (nonatomic, retain) NSURL *applicationDirectoryLocation;
@property (nonatomic, readonly) NSString *documentsDirectoryPath;
@property (nonatomic, readonly) NSString *thisDocumentDirectoryPath;
@property (nonatomic, readonly) NSString *thisDocumentSyncChangesThisClientDirectoryPath;

@end
