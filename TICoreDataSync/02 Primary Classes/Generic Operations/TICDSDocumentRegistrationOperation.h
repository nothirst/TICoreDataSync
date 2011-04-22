//
//  TICDSDocumentRegistrationOperation.h
//  ShoppingListMac
//
//  Created by Tim Isted on 22/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICDSOperation.h"


@interface TICDSDocumentRegistrationOperation : TICDSOperation {
@private
    NSString *_documentIdentifier;
    NSString *_documentDescription;
    NSString *_clientDescription;
    NSDictionary *_userInfo;
}

@property (nonatomic, retain) NSString *documentIdentifier;
@property (nonatomic, retain) NSString *documentDescription;
@property (nonatomic, retain) NSString *clientDescription;
@property (nonatomic, retain) NSDictionary *userInfo;
@end
