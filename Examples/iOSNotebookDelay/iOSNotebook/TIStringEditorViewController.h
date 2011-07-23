//
//  StringEditorViewController.h
//  iOSNotebook
//
//  Created by Tim Isted on 01/06/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

@class TIStringEditorViewController;

@protocol TIStringEditorViewControllerDelegate <NSObject>

@optional
- (void)stringEditorViewControllerDidCancel:(TIStringEditorViewController *)aViewController;
@required
- (BOOL)stringEditorViewController:(TIStringEditorViewController *)aViewController shouldDismissWithString:(NSString *)aString;

@end

@interface TIStringEditorViewController : UIViewController {
    NSObject <TIStringEditorViewControllerDelegate> *_delegate;
    NSString *_initialString;
    
    UITextField *_textField;
    NSObject *_userInfo;
}

- (id)initWithInitialString:(NSString *)aString delegate:(NSObject <TIStringEditorViewControllerDelegate> *)aDelegate userInfo:(NSObject *)info;

@property (nonatomic, assign) NSObject <TIStringEditorViewControllerDelegate> *delegate;
@property (nonatomic, retain) NSString *initialString;
@property (nonatomic, retain) IBOutlet UITextField *textField;
@property (nonatomic, retain) NSObject *userInfo;

@end
