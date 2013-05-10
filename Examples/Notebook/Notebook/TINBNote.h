//
//  TINBNote.h
//  Notebook
//
//  Created by Tim Isted on 04/05/2011.
//  Copyright (c) 2011 Tim Isted. All rights reserved.
//

#import "TICoreDataSync.h"
#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class TINBTag;

@interface TINBNote : TICDSSynchronizedManagedObject {
@private
}
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * content;
@property (nonatomic, retain) NSSet* tags;

@end
