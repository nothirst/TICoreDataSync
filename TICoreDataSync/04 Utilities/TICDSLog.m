//
//  TICDSLog.m
//  ShoppingListMac
//
//  Created by Tim Isted on 21/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICoreDataSync.h"

NSInteger gTICDSLogVerbosity = 0;

@implementation TICDSLog

#pragma mark - Verbosity
+ (NSInteger)verbosity
{
    return gTICDSLogVerbosity;
}

+ (void)setVerbosity:(NSInteger)verbosity
{
    gTICDSLogVerbosity = verbosity;
}

#pragma mark - Logging
+ (void)logWithVerbosity:(NSInteger)someVerbosity formatString:(NSString *)formatString args:(va_list)args
{
    if( someVerbosity > [self verbosity] ) {
        return;
    }
    
    NSLogv(formatString, args);
}

+ (void)logWithVerbosity:(NSInteger)someVerbosity information:(NSString *)formatString, ...
{
    va_list args;
    va_start(args, formatString);
    [self logWithVerbosity:someVerbosity formatString:formatString args:args];
    va_end(args);
}

@end
