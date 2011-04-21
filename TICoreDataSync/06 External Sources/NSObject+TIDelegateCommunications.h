//
//  NSObject+TIDelegateCommunications.h
//  ShoppingListMac
//
//  Created by Tim Isted on 21/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

@interface NSObject (TIDelegateCommunications)

/** Returns an invocation confgured to target the delegate */
- (NSInvocation *)ti_invocationForDelegateSelector:(SEL)aSelector;

/** Method used primarily by others to get some kind of result from a delegate selector passing a variable number of (object) arguments. Returns YES if invocation was invoked successfully; result parameter won't be changed if invocation not invoked */
- (BOOL)ti_getResult:(void *)result fromDelegateWithSelector:(SEL)aSelector, ...;

/** Method used primarily by others to get some kind of result from a delegate selector passing a va_list of arguments. Returns YES if invocation was invoked successfully; result parameter won't be changed if invocation not invoked */
- (BOOL)ti_getResult:(void *)result fromDelegateWithSelector:(SEL)aSelector withArgList:(va_list)args;

/** Returns an object value from a given delegate selector and provided (object) arguments */
- (id)ti_objectFromDelegateWithSelector:(SEL)aSelector, ...;

/** Returns a BOOL value from a given delegate selector; indicate optimistic to return YES if the delegate doesn't respond to the selector */
- (BOOL)ti_optimistic:(BOOL)optimistic boolFromDelegateSelector:(SEL)aSelector, ...;

/** Returns a BOOL value from a given delegate selector. If the delegate does not respond to the selector, YES is returned. */
- (BOOL)ti_optimisticBoolFromDelegateSelector:(SEL)aSelector, ...;

/** Returns a BOOL value from a given delegate selector. If the delegate does not respond to the selector, NO is returned. */
- (BOOL)ti_boolFromDelegateSelector:(SEL)aSelector, ...;

/** Alerts a delegate with a given selector and provided arguments */
- (void)ti_alertDelegateWithSelector:(SEL)aSelector, ...;

- (void)ti_alertDelegateOnMainThreadWithSelector:(SEL)aSelector waitUntilDone:(BOOL)shouldWait, ...;

@end
