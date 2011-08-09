//
//  TICDSRemoveAllRemoteSyncDataOperation.h
//  iOSNotebook
//
//  Created by Tim Isted on 05/08/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICDSOperation.h"

/** The `TICDSRemoveAllRemoteSyncDataOperation` class describes a generic operation used by the `TICoreDataSync` framework to remove all remote sync data. */
 
@interface TICDSRemoveAllRemoteSyncDataOperation : TICDSOperation {
@private
    
}

#pragma mark Designated Initializer
/** @name Designated Initializer */

/** Initialize an operation to remove all sync data using a delegate that supports the `TICDSRemoveAllRemoteSyncDataOperationDelegate` protocol.
 
 @param aDelegate The delegate to use for this operation.
 
 @return An initialized document registration operation. */
- (id)initWithDelegate:(NSObject<TICDSRemoveAllRemoteSyncDataOperationDelegate> *)aDelegate;

#pragma mark Methods Overridden by Subclasses
/** @name Methods Overridden by Subclasses */

/** Remove all remote sync data for this application.
 
 This method must call `:` when finished. */
- (void)removeRemoteSyncDataDirectory;

#pragma mark Callbacks
/** @name Callbacks */

/** Indicate whether the removal of all remote sync data was successful.
 
 If not, call `setError:` first, then specify `NO` for `success`.
 
 @param success `YES` if the directory structure was created, otherwise `NO`. */
- (void)removedRemoteSyncDataDirectoryWithSuccess:(BOOL)success;

@end
