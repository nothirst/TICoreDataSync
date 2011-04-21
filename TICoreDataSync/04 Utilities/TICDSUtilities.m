//
//  TICDSUtilities.m
//  ShoppingListMac
//
//  Created by Tim Isted on 21/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICDSUtilities.h"


@implementation TICDSUtilities

+ (NSString *)uuidString
{
    return [[NSProcessInfo processInfo] globallyUniqueString];
}

@end
