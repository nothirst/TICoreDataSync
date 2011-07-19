//
//  Created by Tim Isted on 04/05/2011.
//  Copyright (c) 2011 Tim Isted. All rights reserved.
//


/* Uncomment these #defines and supply the information for your 
 * Dropbox developer account. 

 * This info can be found at: 
 * https://www.dropbox.com/developers/app_info/yourAppID

 * Both need to be Objective-C strings, using @"" notation. */

#define kTICDDropboxSyncKey @"fqv4grvh4a1u885"
#define kTICDDropboxSyncSecret @"x7yo7k9bnrus87z"


#ifndef kTICDDropboxSyncKey
#error "You must specify your Dropbox Sync Key"
#endif

#ifndef kTICDDropboxSyncSecret
#error "You must specify your Dropbox Sync Secret"
#endif