//
//  TICDSDocumentRegistrationOperation.m
//  ShoppingListMac
//
//  Created by Tim Isted on 22/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICDSDocumentRegistrationOperation.h"


@implementation TICDSDocumentRegistrationOperation

#pragma mark -
#pragma mark Initialization and Deallocation
- (void)dealloc
{
    [_documentIdentifier release], _documentIdentifier = nil;
    [_documentDescription release], _documentDescription = nil;
    [_clientDescription release], _clientDescription = nil;
    [_userInfo release], _userInfo = nil;

    [super dealloc];
}

#pragma mark -
#pragma mark Properties
@synthesize documentIdentifier = _documentIdentifier;
@synthesize documentDescription = _documentDescription;
@synthesize clientDescription = _clientDescription;
@synthesize userInfo = _userInfo;

@end
