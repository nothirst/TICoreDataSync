//
//  TICDSSynchronizedManagedObjectContext.h
//  ShoppingListMac
//
//  Created by Tim Isted on 22/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICDSClassesAndProtocols.h"

/**  
 Any changes you wish to synchronize for managed objects must take place within a synchronized managed object context.
 */

@interface TICDSSynchronizedManagedObjectContext : NSManagedObjectContext {
@private
    TICDSDocumentSyncManager *_documentSyncManager;
}

/** The document sync manager responsible for this managed object context's underlying persistent store/document.
 
 This property will automatically be set when registering a document sync manager with this context. */
@property (nonatomic, retain) TICDSDocumentSyncManager *documentSyncManager;

@end
