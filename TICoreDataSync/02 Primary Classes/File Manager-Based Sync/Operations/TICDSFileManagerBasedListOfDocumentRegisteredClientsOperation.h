//
//  TICDSFileManagerBasedListOfDocumentRegisteredClientsOperation.h
//  Notebook
//
//  Created by Tim Isted on 23/05/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICDSListOfDocumentRegisteredClientsOperation.h"


@interface TICDSFileManagerBasedListOfDocumentRegisteredClientsOperation : TICDSListOfDocumentRegisteredClientsOperation {
@private
    NSString *_thisDocumentSyncChangesDirectoryPath;
    NSString *_clientDevicesDirectoryPath;
    NSString *_thisDocumentRecentSyncsDirectoryPath;
    NSString *_thisDocumentWholeStoreDirectoryPath;
}

@property (retain) NSString *thisDocumentSyncChangesDirectoryPath;
@property (retain) NSString *clientDevicesDirectoryPath;
@property (retain) NSString *thisDocumentRecentSyncsDirectoryPath;
@property (retain) NSString *thisDocumentWholeStoreDirectoryPath;

- (NSString *)pathToDeviceInfoPlistForDeviceWithIdentifier:(NSString *)anIdentifier;
- (NSString *)pathToWholeStoreFileForDeviceWithIdentifier:(NSString *)anIdentifier;

@end
