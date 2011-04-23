//
//  TICDSFileManagerBasedDocumentRegistrationOperation.h
//  ShoppingListMac
//
//  Created by Tim Isted on 23/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICDSDocumentRegistrationOperation.h"


@interface TICDSFileManagerBasedDocumentRegistrationOperation : TICDSDocumentRegistrationOperation {
@private
    NSString *_documentsDirectoryPath;
    NSString *_thisDocumentDirectoryPath;
    NSString *_thisDocumentSyncChangesThisClientDirectoryPath;
}

@property (retain) NSString *documentsDirectoryPath;
@property (retain) NSString *thisDocumentDirectoryPath;
@property (retain) NSString *thisDocumentSyncChangesThisClientDirectoryPath;

@end
