//
//  TICDSDocumentDeletionOperation.h
//  Notebook
//
//  Created by Tim Isted on 29/05/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICDSOperation.h"


@interface TICDSDocumentDeletionOperation : TICDSOperation {
@private
    NSString *_documentIdentifier;
    BOOL _documentWasFoundAndDeleted;
}

@property (retain) NSString *documentIdentifier;
@property (assign) BOOL documentWasFoundAndDeleted;

@end
