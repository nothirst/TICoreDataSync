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


@interface NSObject (TIDelegateCommunications)

/** Returns an invocation confgured to target the delegate */
- (NSInvocation *)ti_invocationForDelegateSelector:(SEL)aSelector withArgList:(va_list)args;

/** Method used primarily by others to get some kind of result from a delegate selector passing a variable number of (object) arguments. Returns YES if invocation was invoked successfully; result parameter won't be changed if invocation not invoked */
- (BOOL)ti_getResult:(void *)result fromDelegateWithSelector:(SEL)aSelector, ...;

/** Method used primarily by others to get some kind of result from a delegate selector passing a va_list of arguments. Returns YES if invocation was invoked successfully; result parameter won't be changed if invocation not invoked */
- (BOOL)ti_getResult:(void *)result fromDelegateWithSelector:(SEL)aSelector withArgList:(va_list)args;

/** Returns an object value from a given delegate selector and provided (object) arguments */
- (id)ti_objectFromDelegateWithSelector:(SEL)aSelector, ...;

/** Returns a BOOL value from a given delegate selector. If the delegate does not respond to the selector, YES is returned. */
- (BOOL)ti_optimisticBoolFromDelegateSelector:(SEL)aSelector, ...;

/** Returns a BOOL value from a given delegate selector. If the delegate does not respond to the selector, NO is returned. */
- (BOOL)ti_boolFromDelegateSelector:(SEL)aSelector, ...;

/** Alerts a delegate with a given selector and provided arguments */
- (void)ti_alertDelegateWithSelector:(SEL)aSelector, ...;

- (void)ti_alertDelegateOnMainThreadWithSelector:(SEL)aSelector waitUntilDone:(BOOL)shouldWait, ...;

@end
