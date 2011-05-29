//
//  TICDSDocumentDeletionOperation.m
//  Notebook
//
//  Created by Tim Isted on 29/05/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICoreDataSync.h"

@interface TICDSDocumentDeletionOperation ()

@end

@implementation TICDSDocumentDeletionOperation

- (void)main
{
    
}

#pragma mark -
#pragma mark Initialization and Deallocation
- (void)dealloc
{
    [_documentIdentifier release], _documentIdentifier = nil;
    
    [super dealloc];
}

#pragma mark -
#pragma mark Properties
@synthesize documentIdentifier = _documentIdentifier;

@end
