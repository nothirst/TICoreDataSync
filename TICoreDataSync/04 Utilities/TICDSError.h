//
//  TICDSError.h
//  ShoppingListMac
//
//  Created by Tim Isted on 21/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICDSTypesAndEnums.h"

/** `TICDSError` is a utility class to generate `NSError` objects with certain characteristics. */

@interface TICDSError : NSObject {
@private
}

/** @name Error Generation */

/** Generate an error with the given code.
 
 @param aCode The error code to use.
 @param someInfo The user info to set on the `NSError` object.
 
 @return A properly-configured `NSError` object.
 */
+ (NSError *)errorWithCode:(TICDSErrorCode)aCode userInfo:(id)someInfo;

/** Generate an error with the given code in a specific class and method.
 
 @param aCode The error code to use.
 @param aClassAndMethod A C-string, typically provided by `__PRETTY_FUNCTION__`.
 
 @return A properly-configured `NSError` object with the class and method specified in the user info.
 */
+ (NSError *)errorWithCode:(TICDSErrorCode)aCode classAndMethod:(const char *)aClassAndMethod;

/** Generate an error with the given code and another *underlying error* in a specific class and method.
 
 @param aCode The error code to use.
 @param anUnderlyingError The underlying `NSError` that caused this particular `TICoreDataSync` error.
 @param classAndMethod A C-string, typically provided by `__PRETTY_FUNCTION__`.
 
 @return A properly-configured `NSError` object, with the underlying error, and class and method specified in the user info.
 */
+ (NSError *)errorWithCode:(TICDSErrorCode)aCode underlyingError:(NSError *)anUnderlyingError classAndMethod:(const char *)aClassAndMethod;

/** Generate an error with the given code and another *underlying error* in a specific class and method, also providing your own user info.
 
 @param aCode The error code to use.
 @param anUnderlyingError The underlying `NSError` that caused this particular `TICoreDataSync` error.
 @param someInfo The user info you wish to supply (in addition that created automatically) for this error.
 @param classAndMethod A C-string, typically provided by `__PRETTY_FUNCTION__`.
 
 @return A properly-configured `NSError` object, with the underlying error and class and method, specified in the user info, which will be merged with the provided `someInfo`.
 */
+ (NSError *)errorWithCode:(TICDSErrorCode)aCode underlyingError:(NSError *)anUnderlyingError userInfo:(id)someInfo classAndMethod:(const char *)aClassAndMethod;

@end
