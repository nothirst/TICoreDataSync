//
//  TICDSSynchronizedManagedObjectContext.h
//  ShoppingListMac
//
//  Created by Tim Isted on 22/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICDSClassesAndProtocols.h"


@interface TICDSSynchronizedManagedObjectContext : NSManagedObjectContext {
@private
    TICDSDocumentSyncManager *_documentSyncManager;
}

@property (nonatomic, retain) TICDSDocumentSyncManager *documentSyncManager;

@end
