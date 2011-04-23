//
//  TICDSyncChange.h
//  ShoppingListMac
//
//  Created by Tim Isted on 23/04/2011.
//  Copyright (c) 2011 Tim Isted. All rights reserved.
//


@interface TICDSyncChange : NSManagedObject {
@private
}
@property (nonatomic, retain) NSNumber * changeType;
@property (nonatomic, retain) NSString * objectEntityName;
@property (nonatomic, retain) NSString * objectSyncID;
@property (nonatomic, retain) NSString * relevantKey;
@property (nonatomic, retain) NSData * changedValue;
@property (nonatomic, retain) NSString * relatedObjectEntityName;
@property (nonatomic, retain) NSString * relatedObjectSyncID;
@property (nonatomic, retain) NSDate * localTimeStamp;

@end
