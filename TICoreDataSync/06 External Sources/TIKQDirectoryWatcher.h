// Copyright (c) 2010 Tim Isted
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

extern NSString * const kTIKQDirectoryWatcherObservedDirectoryActivityNotification;
extern NSString * const kTIKQDirectory;
extern NSString * const kTIKQExpandedDirectory;

@interface TIKQDirectoryWatcher : NSObject {
@private
    int _kqFileDescriptor;
    CFRunLoopSourceRef _runLoopSourceRef;
    NSMutableArray *_watchedDirectories;
}

- (void)notifyActivityOnPath:(NSString *)aPath;
- (BOOL)watchDirectory:(NSString *)aDirectoryName error:(NSError **)outError;
- (BOOL)scheduleWatcherOnMainRunLoop:(NSError **)outError;

@property (nonatomic, readonly) int kqFileDescriptor;
@property (nonatomic, readonly) CFRunLoopSourceRef runLoopSourceRef;
@property (nonatomic, retain) NSMutableArray *watchedDirectories;

@end
