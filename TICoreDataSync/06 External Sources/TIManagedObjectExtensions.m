// Copyright (c) 2010 Tim Isted
// 
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "TIManagedObjectExtensions.h"

@implementation NSManagedObject (TIManagedObjectExtensions)

#pragma mark 
#pragma mark Entity Information
+ (NSString *)ti_entityNameInManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
    return [[self ti_entityDescriptionInManagedObjectContext:managedObjectContext] name];
}

+ (NSEntityDescription *)ti_entityDescriptionInManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
    return [self ti_entityForClassName:NSStringFromClass(self) inManagedObjectContext:managedObjectContext];
}

+ (NSEntityDescription *)ti_entityForClassName:(NSString *)aClassName inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
    NSArray *entityDescriptions = [[[managedObjectContext persistentStoreCoordinator] managedObjectModel] entities];
    
    NSEntityDescription *thisDescription = nil;
    for( NSEntityDescription *eachEntity in entityDescriptions ) {
        if( [[eachEntity managedObjectClassName] isEqualToString:aClassName] ) {
            thisDescription = eachEntity;
            break;
        }
    }
    
    return thisDescription;
}

#pragma mark - Creating Objects
+ (id)ti_objectInManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
    return [NSEntityDescription insertNewObjectForEntityForName:[self ti_entityNameInManagedObjectContext:managedObjectContext] inManagedObjectContext:managedObjectContext];
}

#pragma mark - Fetch Requests
+ (NSFetchRequest *)ti_fetchRequestInManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
    return [self ti_fetchRequestWithPredicate:nil inManagedObjectContext:managedObjectContext];
}

+ (NSFetchRequest *)ti_fetchRequestWithPredicate:(NSPredicate *)aPredicate inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
    return [self ti_fetchRequestWithPredicate:aPredicate inManagedObjectContext:managedObjectContext sortedWithDescriptors:nil];
}

+ (NSFetchRequest *)ti_fetchRequestWithPredicate:(NSPredicate *)aPredicate inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext sortedByKey:(NSString *)aKey ascending:(BOOL)yesOrNo
{
    NSSortDescriptor *sortDescriptor = nil;
    if( aKey ) sortDescriptor = [[NSSortDescriptor alloc] initWithKey:aKey ascending:yesOrNo];
    
    return [self ti_fetchRequestWithPredicate:aPredicate inManagedObjectContext:managedObjectContext sortedWithDescriptor:sortDescriptor];
}

+ (NSFetchRequest *)ti_fetchRequestWithPredicate:(NSPredicate *)aPredicate inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext sortedWithDescriptor:(NSSortDescriptor *)aDescriptor
{
    NSArray *sortDescriptors = nil;
    if( aDescriptor ) sortDescriptors = [NSArray arrayWithObject:aDescriptor];
    
    return [self ti_fetchRequestWithPredicate:aPredicate inManagedObjectContext:managedObjectContext sortedWithDescriptors:sortDescriptors];
}

+ (NSFetchRequest *)ti_fetchRequestWithPredicate:(NSPredicate *)aPredicate inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext sortedWithDescriptors:(NSArray *)someDescriptors
{
    NSFetchRequest *requestToReturn = [[NSFetchRequest alloc] init];
    [requestToReturn setEntity:[self ti_entityDescriptionInManagedObjectContext:managedObjectContext]];
    
    if( aPredicate ) [requestToReturn setPredicate:aPredicate];
    if( someDescriptors ) [requestToReturn setSortDescriptors:someDescriptors];
    
    return requestToReturn;
}

+ (NSFetchRequest *)ti_fetchRequestInManagedObjectContext:(NSManagedObjectContext *)managedObjectContext withPredicateWithFormat:(NSString *)aFormat, ...
{
    va_list args;
    va_start(args, aFormat);
    NSPredicate *predicate = [NSPredicate predicateWithFormat:aFormat arguments:args];
    va_end(args);
    
    return [self ti_fetchRequestWithPredicate:predicate inManagedObjectContext:managedObjectContext];
}
#pragma mark - Counting Objects
+ (NSUInteger)ti_numberOfObjectsInManagedObjectContext:(NSManagedObjectContext *)managedObjectContext error:(NSError **)outError
{
    return [self ti_numberOfObjectsMatchingPredicate:nil inManagedObjectContext:managedObjectContext error:outError];
}

+ (NSUInteger)ti_numberOfObjectsMatchingPredicate:(NSPredicate *)aPredicate inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext error:(NSError **)outError
{
    
    NSError *anyError = nil;
    NSUInteger count = 0;
    
    NSFetchRequest *countRequest = [self ti_fetchRequestWithPredicate:aPredicate inManagedObjectContext:managedObjectContext];
    count = [managedObjectContext countForFetchRequest:countRequest error:&anyError];
    
    if (outError && anyError) {
        *outError = anyError;
    }
    
    return count;
}

+ (NSUInteger)ti_numberOfObjectsInManagedObjectContext:(NSManagedObjectContext *)managedObjectContext error:(NSError **)outError matchingPredicateWithFormat:(NSString *)format, ...
{
    va_list args;
    va_start(args, format);
    NSPredicate *thePredicate = [NSPredicate predicateWithFormat:format arguments:args];
    va_end(args);
    
    return [self ti_numberOfObjectsMatchingPredicate:thePredicate inManagedObjectContext:managedObjectContext error:outError];
}

#pragma mark - Fetching Objects
#pragma mark - All Objects
+ (NSArray *)ti_allObjectsInManagedObjectContext:(NSManagedObjectContext *)managedObjectContext sortedByKey:(NSString *)aKey ascending:(BOOL)yesOrNo error:(NSError **)outError
{
    return [self ti_objectsMatchingPredicate:nil inManagedObjectContext:managedObjectContext sortedByKey:aKey ascending:yesOrNo error:outError];
}

+ (NSArray *)ti_allObjectsInManagedObjectContext:(NSManagedObjectContext *)managedObjectContext sortedWithDescriptor:(NSSortDescriptor *)aDescriptor error:(NSError **)outError
{
    return [self ti_objectsMatchingPredicate:nil inManagedObjectContext:managedObjectContext sortedWithDescriptor:aDescriptor error:outError];
}

+ (NSArray *)ti_allObjectsInManagedObjectContext:(NSManagedObjectContext *)managedObjectContext sortedWithDescriptors:(NSArray *)someDescriptors error:(NSError **)outError
{
    return [self ti_objectsMatchingPredicate:nil inManagedObjectContext:managedObjectContext sortedWithDescriptors:someDescriptors error:outError];
}

+ (NSArray *)ti_allObjectsInManagedObjectContext:(NSManagedObjectContext *)managedObjectContext error:(NSError **)outError
{
    return [self ti_allObjectsInManagedObjectContext:managedObjectContext sortedWithDescriptor:nil error:outError];
}

#pragma mark - Matching Predicate
+ (NSArray *)ti_objectsMatchingPredicate:(NSPredicate *)aPredicate inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext sortedWithDescriptors:(NSArray *)someDescriptors error:(NSError **)outError
{
    NSError *anyError = nil;
    NSArray *results = nil;
    
    NSFetchRequest *request = [self ti_fetchRequestWithPredicate:aPredicate inManagedObjectContext:managedObjectContext sortedWithDescriptors:someDescriptors];
    results = [managedObjectContext executeFetchRequest:request error:&anyError];
    
    if (!results && outError) {
        *outError = anyError;
    }
    
    return results;
}

+ (NSArray *)ti_objectsMatchingPredicate:(NSPredicate *)aPredicate inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext sortedWithDescriptor:(NSSortDescriptor *)aDescriptor error:(NSError **)outError
{
    NSArray *sortDescriptors = nil;
    if( aDescriptor ) sortDescriptors = [NSArray arrayWithObject:aDescriptor];
    
    return [self ti_objectsMatchingPredicate:aPredicate inManagedObjectContext:managedObjectContext sortedWithDescriptors:sortDescriptors error:outError];
}

+ (NSArray *)ti_objectsMatchingPredicate:(NSPredicate *)aPredicate inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext sortedByKey:(NSString *)aKey ascending:(BOOL)yesOrNo error:(NSError **)outError
{
    NSSortDescriptor *sortDescriptor = nil;
    if( aKey ) sortDescriptor = [[NSSortDescriptor alloc] initWithKey:aKey ascending:yesOrNo];
    
    return [self ti_objectsMatchingPredicate:aPredicate inManagedObjectContext:managedObjectContext sortedWithDescriptor:sortDescriptor error:outError];
}

+ (NSArray *)ti_objectsMatchingPredicate:(NSPredicate *)aPredicate inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext error:(NSError **)outError
{
    return [self ti_objectsMatchingPredicate:aPredicate inManagedObjectContext:managedObjectContext sortedWithDescriptors:nil error:outError];
}

+ (NSArray *)ti_objectsInManagedObjectContext:(NSManagedObjectContext *)managedObjectContext error:(NSError **)outError matchingPredicateWithFormat:(NSString *)aFormat, ...
{
    va_list args;
    va_start(args, aFormat);
    NSPredicate *thePredicate = [NSPredicate predicateWithFormat:aFormat arguments:args];
    va_end(args);
    
    return [self ti_objectsMatchingPredicate:thePredicate inManagedObjectContext:managedObjectContext error:outError];
}

+ (NSArray *)ti_objectsInManagedObjectContext:(NSManagedObjectContext *)managedObjectContext sortedWithDescriptor:(NSSortDescriptor *)aDescriptor error:(NSError **)outError matchingPredicateWithFormat:(NSString *)aFormat, ...
{
    va_list args;
    va_start(args, aFormat);
    NSPredicate *thePredicate = [NSPredicate predicateWithFormat:aFormat arguments:args];
    va_end(args);
    
    return [self ti_objectsMatchingPredicate:thePredicate inManagedObjectContext:managedObjectContext sortedWithDescriptor:aDescriptor error:outError];
}

+ (NSArray *)ti_objectsInManagedObjectContext:(NSManagedObjectContext *)managedObjectContext sortedByKey:(NSString *)aKey ascending:(BOOL)yesOrNo error:(NSError **)outError matchingPredicateWithFormat:(NSString *)aFormat, ...
{
    va_list args;
    va_start(args, aFormat);
    NSPredicate *thePredicate = [NSPredicate predicateWithFormat:aFormat arguments:args];
    va_end(args);
    
    return [self ti_objectsMatchingPredicate:thePredicate inManagedObjectContext:managedObjectContext sortedByKey:aKey ascending:yesOrNo error:outError];
}

+ (NSArray *)ti_objectsInManagedObjectContext:(NSManagedObjectContext *)managedObjectContext sortedWithDescriptors:(NSArray *)someDescriptors error:(NSError **)outError matchingPredicateWithFormat:(NSString *)aFormat, ...
{
    va_list args;
    va_start(args, aFormat);
    NSPredicate *thePredicate = [NSPredicate predicateWithFormat:aFormat arguments:args];
    va_end(args);
    
    return [self ti_objectsMatchingPredicate:thePredicate inManagedObjectContext:managedObjectContext sortedWithDescriptors:someDescriptors error:outError];
}

#pragma mark - First Object
+ (id)_ti_firstObjectInArrayIfExists:(NSArray *)anArray
{
    if( [anArray count] < 1 ) return nil;
    
    return [anArray objectAtIndex:0];
}

+ (id)ti_firstObjectMatchingPredicate:(NSPredicate *)aPredicate inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext error:(NSError **)outError
{
    return [self _ti_firstObjectInArrayIfExists:[self ti_objectsMatchingPredicate:aPredicate inManagedObjectContext:managedObjectContext error:outError]];
}

+ (id)ti_firstObjectInManagedObjectContext:(NSManagedObjectContext *)managedObjectContext error:(NSError **)outError matchingPredicateWithFormat:(NSString *)aFormat, ...
{
    va_list args;
    va_start(args, aFormat);
    NSPredicate *thePredicate = [NSPredicate predicateWithFormat:aFormat arguments:args];
    va_end(args);
    
    return [self ti_firstObjectMatchingPredicate:thePredicate inManagedObjectContext:managedObjectContext error:outError];
}

@end
