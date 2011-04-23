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
    NSString *_applicationDirectoryPath;
}

@property (nonatomic, retain) NSString *applicationDirectoryPath;
@property (nonatomic, readonly) NSString *documentsDirectoryPath;
@property (nonatomic, readonly) NSString *thisDocumentDirectoryPath;
@property (nonatomic, readonly) NSString *thisDocumentSyncChangesThisClientDirectoryPath;

@end
