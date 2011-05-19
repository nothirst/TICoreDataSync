//
//  TINBTag.h
//  Notebook
//
//  Created by Tim Isted on 04/05/2011.
//  Copyright (c) 2011 Tim Isted. All rights reserved.
//

#import "TICoreDataSync.h"

@class TINBNote;

@interface TINBTag : TICDSSynchronizedManagedObject {
@private
}
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSSet* notes;

@end
