//
//  TICDSSynchronizedManagedObject.h
//  ShoppingListMac
//
//  Created by Tim Isted on 23/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//


@interface TICDSSynchronizedManagedObject : NSManagedObject {
@private
    
}

@property (nonatomic, readonly) NSManagedObjectContext *syncChangesMOC;

@end
