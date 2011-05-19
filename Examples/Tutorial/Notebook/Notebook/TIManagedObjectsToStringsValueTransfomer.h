//
//  TINBStringsToTagsValueTransfomer.h
//  Notebook
//
//  Created by Tim Isted on 04/05/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

@interface TIManagedObjectsToStringsValueTransfomer : NSValueTransformer {
@private
    NSManagedObjectContext *_managedObjectContext;
    NSString *_entityName;
    NSString *_attributeName;
}

@property (assign) NSManagedObjectContext *managedObjectContext;
@property (retain) NSString *entityName;
@property (retain) NSString *attributeName;

@end
