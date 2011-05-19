//
//  TINBTag.m
//  Notebook
//
//  Created by Tim Isted on 04/05/2011.
//  Copyright (c) 2011 Tim Isted. All rights reserved.
//

#import "TINBTag.h"
#import "TINBNote.h"


@implementation TINBTag
@dynamic name;
@dynamic notes;

- (void)addNotesObject:(TINBNote *)value {    
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    [self willChangeValueForKey:@"notes" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"notes"] addObject:value];
    [self didChangeValueForKey:@"notes" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [changedObjects release];
}

- (void)removeNotesObject:(TINBNote *)value {
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    [self willChangeValueForKey:@"notes" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"notes"] removeObject:value];
    [self didChangeValueForKey:@"notes" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
    [changedObjects release];
}

- (void)addNotes:(NSSet *)value {    
    [self willChangeValueForKey:@"notes" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value];
    [[self primitiveValueForKey:@"notes"] unionSet:value];
    [self didChangeValueForKey:@"notes" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value];
}

- (void)removeNotes:(NSSet *)value {
    [self willChangeValueForKey:@"notes" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value];
    [[self primitiveValueForKey:@"notes"] minusSet:value];
    [self didChangeValueForKey:@"notes" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value];
}


@end
