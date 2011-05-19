//
//  TINBStringsToTagsValueTransfomer.m
//  Notebook
//
//  Created by Tim Isted on 04/05/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TIManagedObjectsToStringsValueTransfomer.h"
#import "TINBTag.h"

@implementation TIManagedObjectsToStringsValueTransfomer

+ (BOOL)allowsReverseTransformation
{
    return YES;
}

#pragma mark -
#pragma mark Transformation
- (id)transformedValue:(id)setOfManagedObjects
{
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:[setOfManagedObjects count]];
    
    for( NSManagedObject *eachObject in setOfManagedObjects ) {
        [array addObject:[eachObject valueForKey:[self attributeName]]];
    }
    
    return array;
}

#pragma mark -
#pragma mark Reverse Transformation
- (NSArray *)objectsMatchingName:(NSString *)aName
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[NSEntityDescription entityForName:[self entityName] inManagedObjectContext:[self managedObjectContext]]];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"%K ==[cd] %@", [self attributeName], aName]];
    
    NSError *anyError = nil;
    NSArray *results = [[self managedObjectContext] executeFetchRequest:fetchRequest error:&anyError];
    [fetchRequest release];
    
    if( !results ) {
        NSLog(@"Error fetching Objects: %@", anyError);
    }
    
    return results;
}

- (id)reverseTransformedValue:(id)arrayOfStrings
{
    NSMutableSet *set = [NSMutableSet setWithCapacity:[arrayOfStrings count]];
    
    NSArray *results = nil;
    NSManagedObject *eachObject = nil;
    for( NSString *eachObjectName in arrayOfStrings ) {
        
        results = [self objectsMatchingName:eachObjectName];
        
        if( [results count] > 0 ) {
            eachObject = [results lastObject];
        } else {
            eachObject = [NSEntityDescription insertNewObjectForEntityForName:[self entityName] inManagedObjectContext:[self managedObjectContext]];
            [eachObject setValue:eachObjectName forKey:[self attributeName]]; 
        }
        
        [set addObject:eachObject];
    }
    
    return set;
}

#pragma mark -
#pragma mark Deallocation
- (void)dealloc
{
    [_entityName release], _entityName = nil;
    [_attributeName release], _attributeName = nil;
    
    [super dealloc];
}

#pragma mark -
#pragma mark Properties
@synthesize managedObjectContext = _managedObjectContext;
@synthesize entityName = _entityName;
@synthesize attributeName = _attributeName;

@end
