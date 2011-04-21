//
//  TICDSError.h
//  ShoppingListMac
//
//  Created by Tim Isted on 21/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICDSTypesAndEnums.h"

@interface TICDSError : NSObject {
@private
}

+ (NSError *)errorWithCode:(TICDSErrorCode)aCode userInfo:(id)someInfo;
+ (NSError *)errorWithCode:(TICDSErrorCode)aCode classAndMethod:(const char *)aClassAndMethod;
+ (NSError *)errorWithCode:(TICDSErrorCode)aCode underlyingError:(NSError *)anUnderlyingError classAndMethod:(const char *)aClassAndMethod;
+ (NSError *)errorWithCode:(TICDSErrorCode)aCode underlyingError:(NSError *)anUnderlyingError userInfo:(id)someInfo classAndMethod:(const char *)aClassAndMethod;

@end
