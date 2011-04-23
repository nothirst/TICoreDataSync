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

#import <CoreData/CoreData.h>

@interface NSManagedObject (TIManagedObjectExtensions) 

+ (NSString *)ti_entityNameInManagedObjectContext:(NSManagedObjectContext *)aContext;
+ (NSEntityDescription *)ti_entityDescriptionInManagedObjectContext:(NSManagedObjectContext *)aContext;
+ (NSEntityDescription *)ti_entityForClassName:(NSString *)aClassName inManagedObjectContext:(NSManagedObjectContext *)aContext;

+ (id)ti_objectInManagedObjectContext:(NSManagedObjectContext *)aContext;

+ (NSFetchRequest *)ti_fetchRequestInManagedObjectContext:(NSManagedObjectContext *)aContext;
+ (NSFetchRequest *)ti_fetchRequestWithPredicate:(NSPredicate *)aPredicate inManagedObjectContext:(NSManagedObjectContext *)aContext;
+ (NSFetchRequest *)ti_fetchRequestWithPredicate:(NSPredicate *)aPredicate inManagedObjectContext:(NSManagedObjectContext *)aContext sortedWithDescriptor:(NSSortDescriptor *)aDescriptor;
+ (NSFetchRequest *)ti_fetchRequestWithPredicate:(NSPredicate *)aPredicate inManagedObjectContext:(NSManagedObjectContext *)aContext sortedByKey:(NSString *)aKey ascending:(BOOL)yesOrNo;
+ (NSFetchRequest *)ti_fetchRequestWithPredicate:(NSPredicate *)aPredicate inManagedObjectContext:(NSManagedObjectContext *)aContext sortedWithDescriptors:(NSArray *)someDescriptors;
+ (NSFetchRequest *)ti_fetchRequestInManagedObjectContext:(NSManagedObjectContext *)aContext withPredicateWithFormat:(NSString *)aFormat, ...;

+ (NSUInteger)ti_numberOfObjectsInManagedObjectContext:(NSManagedObjectContext *)aContext error:(NSError **)outError;
+ (NSUInteger)ti_numberOfObjectsMatchingPredicate:(NSPredicate *)aPredicate inManagedObjectContext:(NSManagedObjectContext *)aContext error:(NSError **)outError;
+ (NSUInteger)ti_numberOfObjectsInManagedObjectContext:(NSManagedObjectContext *)aContext error:(NSError **)outError matchingPredicateWithFormat:(NSString *)aFormat, ...;

+ (NSArray *)ti_allObjectsInManagedObjectContext:(NSManagedObjectContext *)aContext error:(NSError **)outError;
+ (NSArray *)ti_allObjectsInManagedObjectContext:(NSManagedObjectContext *)aContext sortedWithDescriptor:(NSSortDescriptor *)aDescriptor error:(NSError **)outError;
+ (NSArray *)ti_allObjectsInManagedObjectContext:(NSManagedObjectContext *)aContext sortedByKey:(NSString *)aKey ascending:(BOOL)yesOrNo error:(NSError **)outError;
+ (NSArray *)ti_allObjectsInManagedObjectContext:(NSManagedObjectContext *)aContext sortedWithDescriptors:(NSArray *)someDescriptors error:(NSError **)outError;

+ (NSArray *)ti_objectsMatchingPredicate:(NSPredicate *)aPredicate inManagedObjectContext:(NSManagedObjectContext *)aContext error:(NSError **)outError;
+ (NSArray *)ti_objectsMatchingPredicate:(NSPredicate *)aPredicate inManagedObjectContext:(NSManagedObjectContext *)aContext sortedWithDescriptor:(NSSortDescriptor *)aDescriptor error:(NSError **)outError;
+ (NSArray *)ti_objectsMatchingPredicate:(NSPredicate *)aPredicate inManagedObjectContext:(NSManagedObjectContext *)aContext sortedByKey:(NSString *)aKey ascending:(BOOL)yesOrNo error:(NSError **)outError;
+ (NSArray *)ti_objectsMatchingPredicate:(NSPredicate *)aPredicate inManagedObjectContext:(NSManagedObjectContext *)aContext sortedWithDescriptors:(NSArray *)someDescriptors error:(NSError **)outError;

+ (NSArray *)ti_objectsInManagedObjectContext:(NSManagedObjectContext *)aContext error:(NSError **)outError matchingPredicateWithFormat:(NSString *)aFormat, ...;
+ (NSArray *)ti_objectsInManagedObjectContext:(NSManagedObjectContext *)aContext sortedWithDescriptor:(NSSortDescriptor *)aDescriptor error:(NSError **)outError matchingPredicateWithFormat:(NSString *)aFormat, ...;
+ (NSArray *)ti_objectsInManagedObjectContext:(NSManagedObjectContext *)aContext sortedByKey:(NSString *)aKey ascending:(BOOL)yesOrNo error:(NSError **)outError matchingPredicateWithFormat:(NSString *)aFormat, ...;
+ (NSArray *)ti_objectsInManagedObjectContext:(NSManagedObjectContext *)aContext sortedWithDescriptors:(NSArray *)someDescriptors error:(NSError **)outError matchingPredicateWithFormat:(NSString *)aFormat, ...;

+ (id)ti_firstObjectMatchingPredicate:(NSPredicate *)aPredicate inManagedObjectContext:(NSManagedObjectContext *)aContext error:(NSError **)outError;
+ (id)ti_firstObjectInManagedObjectContext:(NSManagedObjectContext *)aContext error:(NSError **)outError matchingPredicateWithFormat:(NSString *)aFormat, ...;

@end
