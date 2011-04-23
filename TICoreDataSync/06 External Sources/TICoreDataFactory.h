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

@protocol TICoreDataFactoryDelegate;


@interface TICoreDataFactory : NSObject {
    NSObject <TICoreDataFactoryDelegate> *_delegate;
    
    NSManagedObjectContext *_managedObjectContext;
    NSPersistentStoreCoordinator *_persistentStoreCoordinator;
    
    NSString *_momdName;
    NSManagedObjectModel *_managedObjectModel;
    
    NSString *_persistentStoreDataFileName;
    NSString *_persistentStoreDataPath;
    
    NSString *_persistentStoreType;
    NSDictionary *_persistentStoreOptions;
    
    NSError *_mostRecentError;
}

- (id)init;
- (id)initWithMomdName:(NSString *)aMomdName;

+ (id)coreDataFactory;
+ (id)coreDataFactoryWithMomdName:(NSString *)aMomdName;

- (NSManagedObjectContext *)secondaryManagedObjectContext;

@property (nonatomic, assign) NSObject <TICoreDataFactoryDelegate> *delegate;

@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@property (nonatomic, retain) NSString *momdName;
@property (nonatomic, retain) NSManagedObjectModel *managedObjectModel;

@property (nonatomic, retain) NSString *persistentStoreDataFileName;
@property (nonatomic, retain) NSString *persistentStoreDataPath;

@property (nonatomic, assign) NSString *persistentStoreType;
@property (nonatomic, retain) NSDictionary *persistentStoreOptions;

@property (nonatomic, retain) NSError *mostRecentError;

@end


@protocol TICoreDataFactoryDelegate
@optional
- (void)coreDataFactory:(TICoreDataFactory *)aFactory encounteredError:(NSError *)anError;

@end