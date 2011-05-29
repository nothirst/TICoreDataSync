//
//  TICDSFileManagerBasedDocumentDeletionOperation.h
//  Notebook
//
//  Created by Tim Isted on 29/05/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICDSDocumentDeletionOperation.h"


@interface TICDSFileManagerBasedDocumentDeletionOperation : TICDSDocumentDeletionOperation {
@private
    NSString *_documentDirectoryPath;
    NSString *_documentInfoPlistFilePath;
    NSString *_deletedDocumentsDirectoryIdentifierPlistFilePath;
}

@property (retain) NSString *documentDirectoryPath;
@property (retain) NSString *documentInfoPlistFilePath;
@property (retain) NSString *deletedDocumentsDirectoryIdentifierPlistFilePath;

@end
