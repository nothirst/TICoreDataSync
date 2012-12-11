//
//  NSManagedObjectContext+TICDSAdditions.h
//  TICoreDataSync-iOS
//
//  Created by Michael Fey on 11/28/12.
//  Copyright (c) 2012 No Thirst Software LLC. All rights reserved.
//

#import "TICDSClassesAndProtocols.h"

/**
 Any changes you wish to synchronize for managed objects must take place within a managed object context that is synchronized and has a document sync manager.
 */
@interface NSManagedObjectContext (TICDSAdditions)

/** The document sync manager responsible for this managed object context's underlying persistent store/document.
 
 This property will automatically be set when registering a document sync manager with this context. */
@property (nonatomic, weak) TICDSDocumentSyncManager *documentSyncManager;

/**
 In order for the changes that take place in a managed object context to be recorded as sync changes the managed object context must be marked as synchronized.
 */
@property (nonatomic, assign, getter = isSynchronized) BOOL synchronized;

@end
