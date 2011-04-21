//
//  TICDSApplicationRegistrationOperation.h
//  ShoppingListMac
//
//  Created by Tim Isted on 21/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICDSOperation.h"

@interface TICDSApplicationRegistrationOperation : TICDSOperation {
@private
    NSString *_appIdentifier;
    NSString *_clientDescription;
    
    BOOL _completionInProgress;
    TICDSOperationPhaseStatus _globalAppFileStructureStatus;
    TICDSOperationPhaseStatus _clientDeviceFileStructureStatus;
}

@end
