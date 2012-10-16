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
    NSObject <TICoreDataFactoryDelegate> *__weak _delegate;
    
    NSManagedObjectContext *_managedObjectContext;
    NSPersistentStoreCoordinator *_persistentStoreCoordinator;
    
    NSString *_momdName;
    NSManagedObjectModel *_managedObjectModel;
    
    NSString *_persistentStoreDataFileName;
    NSString *_persistentStoreDataPath;
    
    NSString *__weak _persistentStoreType;
    NSDictionary *_persistentStoreOptions;
    
    NSError *_mostRecentError;
}

- (id)init;
- (id)initWithMomdName:(NSString *)aMomdName;

+ (id)coreDataFactory;
+ (id)coreDataFactoryWithMomdName:(NSString *)aMomdName;

- (NSManagedObjectContext *)secondaryManagedObjectContext;

@property (nonatomic, weak) NSObject <TICoreDataFactoryDelegate> *delegate;

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@property (nonatomic, copy) NSString *momdName;
@property (nonatomic, strong) NSManagedObjectModel *managedObjectModel;

@property (nonatomic, copy) NSString *persistentStoreDataFileName;
@property (nonatomic, copy) NSString *persistentStoreDataPath;

@property (nonatomic, weak) NSString *persistentStoreType;
@property (nonatomic, strong) NSDictionary *persistentStoreOptions;

@property (nonatomic, strong) NSError *mostRecentError;

@end


@protocol TICoreDataFactoryDelegate
@optional
- (void)coreDataFactory:(TICoreDataFactory *)aFactory encounteredError:(NSError *)anError;

@end