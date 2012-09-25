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
*/

@interface NSObject (TIDelegateCommunications)

/** Returns a Boolean value that indicates whether the receiver's delegate implements or inherits a method that can respond to a specified message.
 
 @param aSelector A selector that identifies a message.
 
 @return YES if the receiver implements or inherits a method that can respond to aSelector, otherwise NO. */
- (BOOL)ti_delegateRespondsToSelector:(SEL)aSelector;

- (void)runOnMainQueueWithoutDeadlocking:(void (^)())block;

@end
