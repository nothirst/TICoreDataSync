//
//  TICDSSynchronizedManagedObject.h
//  ShoppingListMac
//
//  Created by Tim Isted on 23/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//


/**  
 Any managed objects you wish to synchronize must be instances of `TICDSSynchronizedManagedObject`.
 
 This means that you need to change any custom managed object subclasses to inherit from `TICDSSynchronizedManagedObject` rather than `NSManagedObject`, or simply specify `TICDSSynchronizedManagedObject` in the classname for the entity in the model editor. 
 
 @warning Your entity description *must* include a string attribute called `ticdsSyncID`, which the framework will use to identify each managed object instance uniquely.
 */

@interface TICDSSynchronizedManagedObject : NSManagedObject {
@private
    
}

@property (nonatomic, readonly) NSManagedObjectContext *syncChangesMOC;

@end
