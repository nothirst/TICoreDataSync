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
 
 This class provides access to the `TICDSDocumentSyncManager` to handle synchronization of changes, and also overrides the `save:` method to alert the sync manager either side of calling the super implementation of `save:`. 
 
 In a future version of the framework, the `save:` overridden method will likely be removed in favor of Core Data notifications.
 */

@interface TICDSSynchronizedManagedObjectContext : NSManagedObjectContext {
@private
    TICDSDocumentSyncManager *_documentSyncManager;
}

/** The document sync manager responsible for this managed object context's underlying persistent store/document.
 
 This property will automatically be set when registering a document sync manager with this context. */
@property (nonatomic, assign) TICDSDocumentSyncManager *documentSyncManager;

@end
