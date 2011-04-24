//
//  TICDSLog.h
//  ShoppingListMac
//
//  Created by Tim Isted on 21/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICDSTypesAndEnums.h"

/** `TICDLog` is a utility class to provide the primary logging behavior for the `TICoreDataSync` framework.
 
 To see output logged by the framework, set the verbosity greater than `0`:
 
     [TICDSLog setVerbosity:<verbosityLevel>];
 
 The higher the level, the more information you will see in the console. Examine the `TICDSLogVerbosity` entries in `TICDSTypesAndEnums.h` for specific values.
 
 @warning You must have `DEBUG` defined to see log output, irrespective of verbosity. You typically do this in the `Preprocessor Macros` build settings for the project. If `DEBUG` is not defined, all `TICDSLog()` calls are replaced with a `nop` assembler instruction.
 */

#ifdef DEBUG
#define TICDSLog(verbosity,...) [TICDSLog logWithVerbosity:verbosity information:[NSString stringWithFormat:@"%s : %@", __PRETTY_FUNCTION__, [NSString stringWithFormat:__VA_ARGS__]]]
#else
#define TICDSLog(verbosity,...) asm("nop\n\t");
#endif


@interface TICDSLog : NSObject {
@private
}

/** @name Verbosity */

/** Returns the current verbosity level for logging. */
+ (NSInteger)verbosity;

/** Sets the verbosity level for logging. */
+ (void)setVerbosity:(NSInteger)verbosity;

/** @name Logging */

/** Log some information (assuming `DEBUG` is set).
 
 @param someVerbosity The verbosity level of this information (if the current verbosity is less than this, the information won't be logged).
 @param formatString The format string (using `NSLog()` format specifiers).
 @param ... A comma-separated list of arguments to substitute into `formatString`.
 */
+ (void)logWithVerbosity:(NSInteger)someVerbosity information:(NSString *)formatString, ...;

/** Log some information (assuming `DEBUG` is set).
 
 @param someVerbosity The verbosity level of this information (if the current verbosity is less than this, the information won't be logged).
 @param formatString The format string (using `NSLog()` format specifiers).
 @param args A correctly started `va_list` with the arguments to substitute into `formatString`.
 */
+ (void)logWithVerbosity:(NSInteger)someVerbosity formatString:(NSString *)formatString args:(va_list)args;

@end
