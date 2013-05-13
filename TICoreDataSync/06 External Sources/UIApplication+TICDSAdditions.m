//
//  UIApplication+TICDSAdditions.m
//  TICoreDataSync-iOS
//
//  Created by Michael Fey on 4/26/13.
//  Copyright (c) 2013 No Thirst Software LLC. All rights reserved.
//

#import "UIApplication+TICDSAdditions.h"

@implementation UIApplication (TICDSAdditions)

- (void)ticds_setNetworkActivityIndicatorVisible:(BOOL)visible
{
    @synchronized(self)
    {
        static NSInteger NetworkActivityStack = 0;
        if (visible) {
            NetworkActivityStack++;
        } else {
            NetworkActivityStack--;
        }

        if (NetworkActivityStack < 0) {
            NSLog(@"%s NetworkActivityStack dipped below zero, resetting to 0.", __PRETTY_FUNCTION__);
            NetworkActivityStack = 0;
        }

        if (NetworkActivityStack == 0) {
            [self performSelector:@selector(ticds_hideNetworkActivityIndicator) withObject:nil afterDelay:0.1];
            return;
        }

        [[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(ticds_hideNetworkActivityIndicator) object:nil];

        if ([[UIApplication sharedApplication] isNetworkActivityIndicatorVisible] && (NetworkActivityStack > 0)) {
            return;
        }

        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:(NetworkActivityStack > 0)];
    }
}

- (void)ticds_hideNetworkActivityIndicator
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

@end
