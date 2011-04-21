//
//  TICDSLocalDropboxApplicationSyncManager.h
//  ShoppingListMac
//
//  Created by Tim Isted on 21/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICDSApplicationSyncManager.h"

@interface TICDSLocalDropboxApplicationSyncManager : TICDSApplicationSyncManager {
@private
    NSURL *_localDropboxLocation;
}

@property (nonatomic, retain) NSURL *localDropboxLocation;

@end
