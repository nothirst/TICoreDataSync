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

/** 
 `TIDelegateCommunications` is a category on `NSObject` to make it easy to communicate with a delegate.
 
 @warning The arguments passed to any of these methods must be objects.
*/

@interface NSObject (TIDelegateCommunications)

/** Returns a Boolean value that indicates whether the receiver's delegate implements or inherits a method that can respond to a specified message.
 
 @param aSelector A selector that identifies a message.
 
 @return YES if the receiver implements or inherits a method that can respond to aSelector, otherwise NO. */
- (BOOL)ti_delegateRespondsToSelector:(SEL)aSelector;

/** @name Invocations */

/** Get some kind of result from a delegate with a given selector and arguments. 
 
 @param result A pointer to a buffer for the result. Note that this buffer won't be changed if the invocation is not invoked.
 @param aSelector The selector to invoke.
 @param ... A variable number of arguments to be passed to the selector (excluding the first argument, assumed to be `self`).
 
 @return `YES` if invocation was invoked successfully. */
- (BOOL)ti_getResult:(void *)result fromDelegateWithSelector:(SEL)aSelector, ...;

/** Get some kind of result from a delegate with a given selector and `va_list`.
 
 @param result A pointer to a buffer for the result. Note that this buffer won't be changed if the invocation is not invoked.
 @param aSelector The selector to invoke.
 @param args A properly-started `va_list` of arguments to be passed to the selector.
 
 @return `YES` if invocation was invoked successfully. */
- (BOOL)ti_getResult:(void *)result fromDelegateWithSelector:(SEL)aSelector withArgList:(va_list)args;

/** Get an object value from a given delegate selector with provided (object) arguments.
 
 @param aSelector The selector to invoke.
 @param ... The arguments to be passed to the selector (excluding the first argument, assumed to be `self`). 
 
 @return The object returned by the delegate. */
- (id)ti_objectFromDelegateWithSelector:(SEL)aSelector, ...;

/** Get a Boolean value from a given delegate selector with provided (object) arguments. 
 
 If the delegate does not respond to the selector, `YES` is returned.
 
 @param aSelector The selector to invoke.
 @param ... The arguments to be passed to the selector (excluding the first argument, assumed to be `self`). 
 
 @return The Boolean returned by the delegate, or `YES` if the delegate does not respond to the selector. */
- (BOOL)ti_optimisticBoolFromDelegateWithSelector:(SEL)aSelector, ...;

/** Get a Boolean value from a given delegate selector with provided (object) arguments. 
 
 If the delegate does not respond to the selector, `NO` is returned. 
 
 @param aSelector The selector to invoke.
 @param ... The arguments to be passed to the selector (excluding the first argument, assumed to be `self`). 
 
 @return The Boolean returned by the delegate, or `NO` if the delegate does not respond to the selector. */
- (BOOL)ti_boolFromDelegateWithSelector:(SEL)aSelector, ...;

/** Alert a delegate with a given selector and provided (object) arguments.
 
 @param aSelector The selector to invoke.
 @param ... The arguments to be passed to the selector (excluding the first argument, assumed to be `self`). */
- (void)ti_alertDelegateWithSelector:(SEL)aSelector, ...;

/** Alert a delegate on the main thread with a given selector and provided (object) arguments.
 
 @param aSelector The selector to invoke.
 @param waitUntilDone A Boolean indicating whether this method should wait until the delegate has been alerted.
 @param ... The arguments to be passed to the selector (excluding the first argument, assumed to be `self`). */
//- (void)ti_alertDelegateOnMainThreadWithSelector:(SEL)aSelector waitUntilDone:(BOOL)shouldWait, ...;

@end
