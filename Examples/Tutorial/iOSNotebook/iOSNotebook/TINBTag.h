//
//  TINBTag.h
//  Notebook
//
//  Created by Tim Isted on 04/05/2011.
//  Copyright (c) 2011 Tim Isted. All rights reserved.
//

@class TINBNote;

@interface TINBTag : NSManagedObject {
@private
}
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSSet* notes;

@end
