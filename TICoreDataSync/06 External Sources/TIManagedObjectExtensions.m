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
+ (NSString *)ti_entityNameInManagedObjectContext:(NSManagedObjectContext *)aContext
{
    return [[self ti_entityDescriptionInManagedObjectContext:aContext] name];
}

+ (NSEntityDescription *)ti_entityDescriptionInManagedObjectContext:(NSManagedObjectContext *)aContext
{
    return [self ti_entityForClassName:NSStringFromClass(self) inManagedObjectContext:aContext];
}

+ (NSEntityDescription *)ti_entityForClassName:(NSString *)aClassName inManagedObjectContext:(NSManagedObjectContext *)aContext
{
    NSArray *entityDescriptions = [[[aContext persistentStoreCoordinator] managedObjectModel] entities];
    
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
+ (id)ti_objectInManagedObjectContext:(NSManagedObjectContext *)aContext
{
    return [NSEntityDescription insertNewObjectForEntityForName:[self ti_entityNameInManagedObjectContext:aContext] inManagedObjectContext:aContext];
}

#pragma mark - Fetch Requests
+ (NSFetchRequest *)ti_fetchRequestInManagedObjectContext:(NSManagedObjectContext *)aContext
{
    return [self ti_fetchRequestWithPredicate:nil inManagedObjectContext:aContext];
}

+ (NSFetchRequest *)ti_fetchRequestWithPredicate:(NSPredicate *)aPredicate inManagedObjectContext:(NSManagedObjectContext *)aContext
{
    return [self ti_fetchRequestWithPredicate:aPredicate inManagedObjectContext:aContext sortedWithDescriptors:nil];
}

+ (NSFetchRequest *)ti_fetchRequestWithPredicate:(NSPredicate *)aPredicate inManagedObjectContext:(NSManagedObjectContext *)aContext sortedByKey:(NSString *)aKey ascending:(BOOL)yesOrNo
{
    NSSortDescriptor *sortDescriptor = nil;
    if( aKey ) sortDescriptor = [[NSSortDescriptor alloc] initWithKey:aKey ascending:yesOrNo];
    
    return [self ti_fetchRequestWithPredicate:aPredicate inManagedObjectContext:aContext sortedWithDescriptor:sortDescriptor];
}

+ (NSFetchRequest *)ti_fetchRequestWithPredicate:(NSPredicate *)aPredicate inManagedObjectContext:(NSManagedObjectContext *)aContext sortedWithDescriptor:(NSSortDescriptor *)aDescriptor
{
    NSArray *sortDescriptors = nil;
    if( aDescriptor ) sortDescriptors = [NSArray arrayWithObject:aDescriptor];
    
    return [self ti_fetchRequestWithPredicate:aPredicate inManagedObjectContext:aContext sortedWithDescriptors:sortDescriptors];
}

+ (NSFetchRequest *)ti_fetchRequestWithPredicate:(NSPredicate *)aPredicate inManagedObjectContext:(NSManagedObjectContext *)aContext sortedWithDescriptors:(NSArray *)someDescriptors
{
    NSFetchRequest *requestToReturn = [[NSFetchRequest alloc] init];
    [requestToReturn setEntity:[self ti_entityDescriptionInManagedObjectContext:aContext]];
    
    if( aPredicate ) [requestToReturn setPredicate:aPredicate];
    if( someDescriptors ) [requestToReturn setSortDescriptors:someDescriptors];
    
    return requestToReturn;
}

+ (NSFetchRequest *)ti_fetchRequestInManagedObjectContext:(NSManagedObjectContext *)aContext withPredicateWithFormat:(NSString *)aFormat, ...
{
    va_list args;
    va_start(args, aFormat);
    NSPredicate *predicate = [NSPredicate predicateWithFormat:aFormat arguments:args];
    va_end(args);
    
    return [self ti_fetchRequestWithPredicate:predicate inManagedObjectContext:aContext];
}
#pragma mark - Counting Objects
+ (NSUInteger)ti_numberOfObjectsInManagedObjectContext:(NSManagedObjectContext *)aContext error:(NSError **)outError
{
    return [self ti_numberOfObjectsMatchingPredicate:nil inManagedObjectContext:aContext error:outError];
}

+ (NSUInteger)ti_numberOfObjectsMatchingPredicate:(NSPredicate *)aPredicate inManagedObjectContext:(NSManagedObjectContext *)aContext error:(NSError **)outError
{
    NSFetchRequest *countRequest = [self ti_fetchRequestWithPredicate:aPredicate inManagedObjectContext:aContext];
    
    NSError *anyError = nil;
    NSUInteger count = [aContext countForFetchRequest:countRequest error:&anyError];
    
    if( outError && anyError ) *outError = anyError;
    
    return count;
}

+ (NSUInteger)ti_numberOfObjectsInManagedObjectContext:(NSManagedObjectContext *)aContext error:(NSError **)outError matchingPredicateWithFormat:(NSString *)format, ...
{
    va_list args;
    va_start(args, format);
    NSPredicate *thePredicate = [NSPredicate predicateWithFormat:format arguments:args];
    va_end(args);
    
    return [self ti_numberOfObjectsMatchingPredicate:thePredicate inManagedObjectContext:aContext error:outError];
}

#pragma mark - Fetching Objects
#pragma mark - All Objects
+ (NSArray *)ti_allObjectsInManagedObjectContext:(NSManagedObjectContext *)aContext sortedByKey:(NSString *)aKey ascending:(BOOL)yesOrNo error:(NSError **)outError
{
    return [self ti_objectsMatchingPredicate:nil inManagedObjectContext:aContext sortedByKey:aKey ascending:yesOrNo error:outError];
}

+ (NSArray *)ti_allObjectsInManagedObjectContext:(NSManagedObjectContext *)aContext sortedWithDescriptor:(NSSortDescriptor *)aDescriptor error:(NSError **)outError
{
    return [self ti_objectsMatchingPredicate:nil inManagedObjectContext:aContext sortedWithDescriptor:aDescriptor error:outError];
}

+ (NSArray *)ti_allObjectsInManagedObjectContext:(NSManagedObjectContext *)aContext sortedWithDescriptors:(NSArray *)someDescriptors error:(NSError **)outError
{
    return [self ti_objectsMatchingPredicate:nil inManagedObjectContext:aContext sortedWithDescriptors:someDescriptors error:outError];
}

+ (NSArray *)ti_allObjectsInManagedObjectContext:(NSManagedObjectContext *)aContext error:(NSError **)outError
{
    return [self ti_allObjectsInManagedObjectContext:aContext sortedWithDescriptor:nil error:outError];
}

#pragma mark - Matching Predicate
+ (NSArray *)ti_objectsMatchingPredicate:(NSPredicate *)aPredicate inManagedObjectContext:(NSManagedObjectContext *)aContext sortedWithDescriptors:(NSArray *)someDescriptors error:(NSError **)outError
{
    NSError *anyError = nil;
    
    NSFetchRequest *request = [self ti_fetchRequestWithPredicate:aPredicate inManagedObjectContext:aContext sortedWithDescriptors:someDescriptors];
    
    NSArray *results = [aContext executeFetchRequest:request error:&anyError];
    
    if( !results && outError )
        *outError = anyError;
    
    return results;
}

+ (NSArray *)ti_objectsMatchingPredicate:(NSPredicate *)aPredicate inManagedObjectContext:(NSManagedObjectContext *)aContext sortedWithDescriptor:(NSSortDescriptor *)aDescriptor error:(NSError **)outError
{
    NSArray *sortDescriptors = nil;
    if( aDescriptor ) sortDescriptors = [NSArray arrayWithObject:aDescriptor];
    
    return [self ti_objectsMatchingPredicate:aPredicate inManagedObjectContext:aContext sortedWithDescriptors:sortDescriptors error:outError];
}

+ (NSArray *)ti_objectsMatchingPredicate:(NSPredicate *)aPredicate inManagedObjectContext:(NSManagedObjectContext *)aContext sortedByKey:(NSString *)aKey ascending:(BOOL)yesOrNo error:(NSError **)outError
{
    NSSortDescriptor *sortDescriptor = nil;
    if( aKey ) sortDescriptor = [[NSSortDescriptor alloc] initWithKey:aKey ascending:yesOrNo];
    
    return [self ti_objectsMatchingPredicate:aPredicate inManagedObjectContext:aContext sortedWithDescriptor:sortDescriptor error:outError];
}

+ (NSArray *)ti_objectsMatchingPredicate:(NSPredicate *)aPredicate inManagedObjectContext:(NSManagedObjectContext *)aContext error:(NSError **)outError
{
    return [self ti_objectsMatchingPredicate:aPredicate inManagedObjectContext:aContext sortedWithDescriptors:nil error:outError];
}

+ (NSArray *)ti_objectsInManagedObjectContext:(NSManagedObjectContext *)aContext error:(NSError **)outError matchingPredicateWithFormat:(NSString *)aFormat, ...
{
    va_list args;
    va_start(args, aFormat);
    NSPredicate *thePredicate = [NSPredicate predicateWithFormat:aFormat arguments:args];
    va_end(args);
    
    return [self ti_objectsMatchingPredicate:thePredicate inManagedObjectContext:aContext error:outError];
}

+ (NSArray *)ti_objectsInManagedObjectContext:(NSManagedObjectContext *)aContext sortedWithDescriptor:(NSSortDescriptor *)aDescriptor error:(NSError **)outError matchingPredicateWithFormat:(NSString *)aFormat, ...
{
    va_list args;
    va_start(args, aFormat);
    NSPredicate *thePredicate = [NSPredicate predicateWithFormat:aFormat arguments:args];
    va_end(args);
    
    return [self ti_objectsMatchingPredicate:thePredicate inManagedObjectContext:aContext sortedWithDescriptor:aDescriptor error:outError];
}

+ (NSArray *)ti_objectsInManagedObjectContext:(NSManagedObjectContext *)aContext sortedByKey:(NSString *)aKey ascending:(BOOL)yesOrNo error:(NSError **)outError matchingPredicateWithFormat:(NSString *)aFormat, ...
{
    va_list args;
    va_start(args, aFormat);
    NSPredicate *thePredicate = [NSPredicate predicateWithFormat:aFormat arguments:args];
    va_end(args);
    
    return [self ti_objectsMatchingPredicate:thePredicate inManagedObjectContext:aContext sortedByKey:aKey ascending:yesOrNo error:outError];
}

+ (NSArray *)ti_objectsInManagedObjectContext:(NSManagedObjectContext *)aContext sortedWithDescriptors:(NSArray *)someDescriptors error:(NSError **)outError matchingPredicateWithFormat:(NSString *)aFormat, ...
{
    va_list args;
    va_start(args, aFormat);
    NSPredicate *thePredicate = [NSPredicate predicateWithFormat:aFormat arguments:args];
    va_end(args);
    
    return [self ti_objectsMatchingPredicate:thePredicate inManagedObjectContext:aContext sortedWithDescriptors:someDescriptors error:outError];
}

#pragma mark - First Object
+ (id)_ti_firstObjectInArrayIfExists:(NSArray *)anArray
{
    if( [anArray count] < 1 ) return nil;
    
    return [anArray objectAtIndex:0];
}

+ (id)ti_firstObjectMatchingPredicate:(NSPredicate *)aPredicate inManagedObjectContext:(NSManagedObjectContext *)aContext error:(NSError **)outError
{
    return [self _ti_firstObjectInArrayIfExists:[self ti_objectsMatchingPredicate:aPredicate inManagedObjectContext:aContext error:outError]];
}

+ (id)ti_firstObjectInManagedObjectContext:(NSManagedObjectContext *)aContext error:(NSError **)outError matchingPredicateWithFormat:(NSString *)aFormat, ...
{
    va_list args;
    va_start(args, aFormat);
    NSPredicate *thePredicate = [NSPredicate predicateWithFormat:aFormat arguments:args];
    va_end(args);
    
    return [self ti_firstObjectMatchingPredicate:thePredicate inManagedObjectContext:aContext error:outError];
}

@end
