//
//  TICDSLog.h
//  ShoppingListMac
//
//  Created by Tim Isted on 21/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICDSTypesAndEnums.h"

#ifdef DEBUG
#define TICDSLog(verbosity,...) [TICDSLog logWithVerbosity:verbosity information:[NSString stringWithFormat:@"%s : %@", __PRETTY_FUNCTION__, [NSString stringWithFormat:__VA_ARGS__]]]
#else
#define TICDSLog(verbosity,...) asm("nop\n\t");
#endif


@interface TICDSLog : NSObject {
@private
}

+ (NSInteger)verbosity;
+ (void)setVerbosity:(NSInteger)verbosity;

+ (void)logWithVerbosity:(NSInteger)someVerbosity information:(NSString *)formatString, ...;
+ (void)logWithVerbosity:(NSInteger)someVerbosity formatString:(NSString *)formatString args:(va_list)args;


@end
