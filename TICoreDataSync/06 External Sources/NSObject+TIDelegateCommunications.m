// Copyright (c) 2011 Tim Isted
// 
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "NSObject+TIDelegateCommunications.h"


@implementation NSObject (TIDelegateCommunications)

#pragma mark Invocation Generation
- (NSInvocation *)ti_invocationForDelegateSelector:(SEL)aSelector withArgList:(va_list)args
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
    
    NSMethodSignature *methodSignature = [[[(id)self delegate] class] instanceMethodSignatureForSelector:aSelector];
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:methodSignature];
    [invocation setSelector:aSelector];
    [invocation setTarget:[(id)self delegate]];
    [invocation setArgument:&self atIndex:2];
        
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
- (BOOL)ti_optimisticBoolFromDelegateWithSelector:(SEL)aSelector, ...
{
    BOOL result = YES;
    
    va_list args;
    va_start(args, aSelector);
    
    [self ti_getResult:&result fromDelegateWithSelector:aSelector withArgList:args];
    va_end(args);
    
    return result;
}

- (BOOL)ti_boolFromDelegateWithSelector:(SEL)aSelector, ...
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
