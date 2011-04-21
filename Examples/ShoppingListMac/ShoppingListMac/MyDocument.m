//
//  MyDocument.m
//  ShoppingListMac
//
//  Created by Tim Isted on 14/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "MyDocument.h"

@implementation MyDocument

- (id)managedObjectModel {
    static id sSharedModel = nil;
    if( sSharedModel ) {
        return sSharedModel;
    }
    
    sSharedModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"ShoppingList" ofType:@"momd"]]];
    
    return sSharedModel;
}

- (NSString *)windowNibName
{
    return @"MyDocument";
}

@end
