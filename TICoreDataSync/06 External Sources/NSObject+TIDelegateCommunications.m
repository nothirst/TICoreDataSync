//
//  NSObject+TIDelegateCommunications.m
//  ShoppingListMac
//
//  Created by Tim Isted on 21/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "NSObject+TIDelegateCommunications.h"


@implementation NSObject (TIDelegateCommunications)

#pragma mark Invocations
- (NSInvocation *)ti_invocationForDelegateSelector:(SEL)aSelector
{
    if( !aSelector ) {
        return nil;
    }
    
    if( ![self respondsToSelector:@selector(delegate)] ) {
        return nil;
    }
    
    if( ![[(id)self delegate] respondsToSelector:aSelector] ) {
        return nil;
    }
    
    NSMethodSignature *signature = [[[(id)self delegate] class] instanceMethodSignatureForSelector:aSelector];
    NSInvocation *selectorInvocation = [NSInvocation invocationWithMethodSignature:signature];
    [selectorInvocation setSelector:aSelector];
    [selectorInvocation setTarget:[(id)self delegate]];
    [selectorInvocation setArgument:&self atIndex:2];
    
    return selectorInvocation;
}

- (NSInvocation *)ti_invocationForDelegateSelector:(SEL)aSelector withArgList:(va_list)args
{
    NSInvocation *invocation = [self ti_invocationForDelegateSelector:aSelector];
    if( !invocation ) {
        return nil;
    }
    
    NSMethodSignature *methodSignature = [invocation methodSignature];
    
    id eachArgument = nil;
    for( int argumentIndex = 3; argumentIndex < [methodSignature numberOfArguments]; argumentIndex++ ) {
        eachArgument = va_arg(args, id);
        
        [invocation setArgument:&eachArgument atIndex:argumentIndex];
    }
    
    return invocation;
}

#pragma mark -
#pragma mark Requesting Values
- (BOOL)ti_getResult:(void *)result fromDelegateWithSelector:(SEL)aSelector withArgList:(va_list)args
{
    NSInvocation *invocation = [self ti_invocationForDelegateSelector:aSelector withArgList:args];
    if( !invocation ) {
        return NO;
    }
    
    [invocation invoke];
    
    if( result ) {
        [invocation getReturnValue:result];
    }
    
    return YES;
}

- (BOOL)ti_getResult:(void *)result fromDelegateWithSelector:(SEL)aSelector, ...
{
    va_list args;
    va_start(args, aSelector);
    
    BOOL returnValue = [self ti_getResult:result fromDelegateWithSelector:aSelector withArgList:args];
    va_end(args);
    
    return returnValue;
}

#pragma mark -
#pragma mark Requesting Objects
- (id)ti_objectFromDelegateWithSelector:(SEL)aSelector, ...
{
    id returnValue = nil;
    
    va_list args;
    va_start(args, aSelector);
    
    [self ti_getResult:&returnValue fromDelegateWithSelector:aSelector withArgList:args];
    va_end(args);
    
    return returnValue;
}

#pragma mark -
#pragma mark Requesting Boolean Values
- (BOOL)ti_optimistic:(BOOL)optimistic boolFromDelegateSelector:(SEL)aSelector, ...
{
    BOOL result = optimistic;
    
    va_list args;
    va_start(args, aSelector);
    
    [self ti_getResult:&result fromDelegateWithSelector:aSelector withArgList:args];
    va_end(args);

    return result;
}

- (BOOL)ti_optimisticBoolFromDelegateSelector:(SEL)aSelector, ...
{
    BOOL result = YES;
    
    va_list args;
    va_start(args, aSelector);
    
    [self ti_getResult:&result fromDelegateWithSelector:aSelector withArgList:args];
    va_end(args);
    
    return result;
}

- (BOOL)ti_boolFromDelegateSelector:(SEL)aSelector, ...
{
    BOOL result = NO;
    
    va_list args;
    va_start(args, aSelector);
    
    [self ti_getResult:&result fromDelegateWithSelector:aSelector withArgList:args];
    va_end(args);
    
    return result;
}

#pragma mark -
#pragma mark Alerting Delegate
- (void)ti_alertDelegateWithSelector:(SEL)aSelector, ...
{
    va_list args;
    va_start(args, aSelector);
    
    [self ti_getResult:nil fromDelegateWithSelector:aSelector withArgList:args];
    va_end(args);
}

- (void)ti_alertDelegateOnMainThreadWithSelector:(SEL)aSelector waitUntilDone:(BOOL)shouldWait, ...
{
    va_list args;
    va_start(args, shouldWait);
    
    NSInvocation *invocation = [self ti_invocationForDelegateSelector:aSelector withArgList:args];
    
    [invocation performSelectorOnMainThread:@selector(invoke) withObject:nil waitUntilDone:shouldWait];
    
    va_end(args);
}

@end
