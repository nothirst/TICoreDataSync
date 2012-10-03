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

#import "TIKQDirectoryWatcher.h"
#import "TICoreDataSync.h"

#import <fcntl.h>
#import <errno.h>
#import <strings.h>
#import <sys/event.h>

@interface TIKQDirectoryWatcher () 

- (void)cancelRunLoopSourceRef;

@end

#pragma mark - Notification Constants
NSString * const kTIKQDirectoryWatcherObservedDirectoryActivityNotification = @"kTIKQDirectoryWatcherObservedDirectoryActivityNotification";
NSString * const kTIKQDirectory = @"kTIKQDirectory";
NSString * const kTIKQExpandedDirectory = @"kTIKQExpandedDirectory";

#pragma mark - Function Declarations
void TIKQSocketCallback( CFSocketRef socketRef, CFSocketCallBackType type, CFDataRef address, const void *data, void *info );




#pragma mark - Primary Implementation
@implementation TIKQDirectoryWatcher

#pragma mark - Primary Methods
- (BOOL)watchDirectory:(NSString *)aDirectoryName error:(NSError **)outError
{
    int directoryFileDescriptor = open( [aDirectoryName UTF8String], O_RDONLY );
    
    if( directoryFileDescriptor == - 1) {
        TICDSLog(TICDSLogVerbosityEveryStep, @"Could not open file descriptor for %@. Error %d (%s)", aDirectoryName, errno, strerror(errno));
        return NO;
    }
    
    [[self watchedDirectories] addObject:aDirectoryName];
    
    struct kevent directoryEvent;
    EV_SET( &directoryEvent, directoryFileDescriptor, EVFILT_VNODE, EV_ADD | EV_CLEAR | EV_ENABLE, NOTE_WRITE, 0, (__bridge void *)aDirectoryName);
    
    if( kevent( [self kqFileDescriptor], &directoryEvent, 1, NULL, 0, NULL ) == -1 ) {
        TICDSLog(TICDSLogVerbosityEveryStep, @"Could not kevent watching %@. Error %d (%s)", aDirectoryName, errno, strerror(errno));
        return NO;
    }
    
    return YES;
}

- (BOOL)scheduleWatcherOnMainRunLoop:(NSError **)outError
{
    [self cancelRunLoopSourceRef];
    
    CFSocketContext socketContext = { 0, (__bridge void *)(self), NULL, NULL, NULL };
    
    CFSocketRef runLoopSocket = CFSocketCreateWithNative(NULL, [self kqFileDescriptor], kCFSocketReadCallBack, TIKQSocketCallback, &socketContext);
    
    if( runLoopSocket == NULL ) {
        TICDSLog(TICDSLogVerbosityEveryStep, @"Failed to create run loop socket using CFSocketCreateWithNative()");
        return NO;
    }
    
    _runLoopSourceRef = CFSocketCreateRunLoopSource(NULL, runLoopSocket, 0);
    if( _runLoopSourceRef == NULL ) {
        TICDSLog(TICDSLogVerbosityEveryStep, @"Could not create a run loop source reference");
        CFRelease(runLoopSocket);
        return NO;
    }
    
    CFRunLoopAddSource(CFRunLoopGetCurrent(), _runLoopSourceRef, kCFRunLoopDefaultMode);
    
    CFRelease(runLoopSocket);
    
    return YES;
}

- (void)notifyActivityOnPath:(NSString *)aPath
{
    [[NSNotificationCenter defaultCenter] 
     postNotificationName:kTIKQDirectoryWatcherObservedDirectoryActivityNotification 
     object:self userInfo:
     [NSDictionary dictionaryWithObjectsAndKeys:
      [aPath stringByAbbreviatingWithTildeInPath], kTIKQDirectory,
      [aPath stringByExpandingTildeInPath], kTIKQExpandedDirectory, nil]];
}

#pragma mark - Removing the Run Loop
- (void)cancelRunLoopSourceRef
{
    if( _runLoopSourceRef ) {
        CFRunLoopRemoveSource(CFRunLoopGetCurrent(), _runLoopSourceRef, kCFRunLoopDefaultMode);
        
        CFRelease(_runLoopSourceRef), _runLoopSourceRef = NULL;
    }
}

#pragma mark - Socket Callback
void TIKQSocketCallback( CFSocketRef socketRef, CFSocketCallBackType type, CFDataRef address, const void *data, void *info )
{
    TIKQDirectoryWatcher *watcher = (__bridge TIKQDirectoryWatcher *)info;
    
    struct kevent event;
    
    if( kevent(watcher->_kqFileDescriptor, NULL, 0, &event, 1, NULL) == -1 ) {
        // TODO: sort this out so the problem causing this message to appear 1000s of times doesn't occur
        TICDSLog(TICDSLogVerbosityDirectoryWatcherPickUpEventIssue, @"TIKQDirectoryWatcher could not pick up an event. Error %d (%s)", errno, strerror(errno));
    } else {
        [watcher notifyActivityOnPath:(__bridge NSString *)event.udata];
    }
}

#pragma mark - Lazy Generators
- (int)kqFileDescriptor
{
    if( _kqFileDescriptor ) return _kqFileDescriptor;
    
    TICDSLog(TICDSLogVerbosityEveryStep, @"Creating the kqueue file descriptor");
    _kqFileDescriptor = kqueue();
    
    if( _kqFileDescriptor == -1 ) {
        TICDSLog(TICDSLogVerbosityEveryStep, @"Could not create kqueue. Error %d (%s)", errno, strerror(errno));
    }
    
    return _kqFileDescriptor;
}

- (NSMutableArray *)watchedDirectories
{
    if( _watchedDirectories ) {
        return _watchedDirectories;
    }
    
    _watchedDirectories = [[NSMutableArray alloc] init];
    
    return _watchedDirectories;
}

#pragma mark - Initialization and Deallocation
- (void)dealloc
{
    close(_kqFileDescriptor);
    _kqFileDescriptor = 0;
    
    [self cancelRunLoopSourceRef];
    _watchedDirectories = nil;
    
}

#pragma mark - Properties
@synthesize kqFileDescriptor = _kqFileDescriptor;
@synthesize runLoopSourceRef = _runLoopSourceRef;
@synthesize watchedDirectories = _watchedDirectories;

@end
