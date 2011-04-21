//
//  TISLSynchronizationController.h
//  ShoppingListMac
//
//  Created by Tim Isted on 30/03/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

@class CATransition;

@interface TISLSynchronizationController : NSWindowController {
    NSTextField *_mainStatusTextField;
    CATransition *_leftRightAnimation;
    
    NSFileManager *_fileManager;
    
    NSInteger _syncActivity;
    NSProgressIndicator *_syncProgressIndicator;
    NSTextField *_syncLabel;
    
    NSView *_panelContainerView;
    
    NSView *_configureSyncView;
    
    NSView *_syncTypeView;
    
    NSView *_dropboxFoundView;
    NSPathControl *_dropboxFoundPathControl;
    
    NSView *_dropboxNotFoundView;
    
    NSView *_dropboxCreateView;
    NSPathControl *_dropboxCreatePathControl;
    NSButton *_dropboxCreateBackButton;
    NSButton *_dropboxCreateContinueButton;
    
    NSView *_dropboxConfiguringView;
    NSView *_dropboxConfiguringProgressIndicator;
    
    NSView *_dropboxConfiguredView;
    
    NSView *_dropboxErrorView;
    NSTextField *_dropboxErrorMessageTextField;
    
    NSView *_dropboxListOfAvailableDocumentsView;
    NSTableView *_dropboxListOfAvailableDocumentsTableView;
    NSTableColumn *_dropboxListOfAvailableDocumentsDescriptionColumn;
    NSTableColumn *_dropboxListOfAvailableDocumentsLastSyncColumn;
    NSArrayController *_dropboxListOfAvailableDocumentsArrayController;
    NSArray *_dropboxListOfAvailableDocumentsArray;
}

// Method to setup registration, if it's enabled, otherwise show Sync Config view
- (void)enableSynchronizationIfEnabledOrShowSyncConfigViewIfDisabled;

// Method to setup registration, if it's enabled
- (void)enableSynchronizationIfNecessary;

// Sync or No Sync View
- (IBAction)configureSyncConfigureAction:(id)sender;

// Sync Type View
- (IBAction)syncTypeViewBack:(id)sender;
- (IBAction)syncTypeDropboxAction:(id)sender;

// Dropbox Found View
- (IBAction)dropboxFoundBackAction:(id)sender;
- (IBAction)dropboxFoundUseSpecifiedDropbox:(id)sender;
- (IBAction)dropboxFoundChooseAnotherDropbox:(id)sender;

// Dropbox Not Found View
- (IBAction)dropboxNotFoundBackAction:(id)sender;
- (IBAction)dropboxNotFoundVisitDropboxWebsiteAction:(id)sender;
- (IBAction)dropboxNotFoundChooseCustomDropboxLocationAction:(id)sender;

// Dropbox Create View
- (IBAction)dropboxCreateBackAction:(id)sender;
- (IBAction)dropboxCreateContinueAction:(id)sender;

// Dropbox Configured View
- (IBAction)dropboxConfiguredDisableSyncAction:(id)sender;
- (IBAction)dropboxConfiguredViewAvailableDocumentsAction:(id)sender;

// Dropbox List Of Available Documents View
- (IBAction)dropboxListOfAvailableDocumentsBackAction:(id)sender;
- (IBAction)dropboxListOfAvailableDocumentsDownloadSelectedDocumentAction:(id)sender;

@property (nonatomic, assign) IBOutlet NSTextField *mainStatusTextField;
@property (nonatomic, retain) CATransition *leftRightAnimation;
@property (nonatomic, retain) NSFileManager *fileManager;
@property (nonatomic, assign) NSInteger syncActivity;
@property (nonatomic, assign) IBOutlet NSProgressIndicator *syncProgressIndicator;
@property (nonatomic, assign) IBOutlet NSTextField *syncLabel;
@property (nonatomic, assign) IBOutlet NSView *panelContainerView;
@property (nonatomic, assign) IBOutlet NSView *configureSyncView;
@property (nonatomic, assign) IBOutlet NSView *syncTypeView;
@property (nonatomic, assign) IBOutlet NSView *dropboxFoundView;
@property (nonatomic, assign) IBOutlet NSPathControl *dropboxFoundPathControl;
@property (nonatomic, assign) IBOutlet NSView *dropboxNotFoundView;
@property (nonatomic, assign) IBOutlet NSView *dropboxCreateView;
@property (nonatomic, assign) IBOutlet NSPathControl *dropboxCreatePathControl;
@property (nonatomic, assign) IBOutlet NSButton *dropboxCreateBackButton;
@property (nonatomic, assign) IBOutlet NSButton *dropboxCreateContinueButton;
@property (nonatomic, assign) IBOutlet NSView *dropboxConfiguringView;
@property (nonatomic, assign) IBOutlet NSView *dropboxConfiguringProgressIndicator;
@property (nonatomic, assign) IBOutlet NSView *dropboxConfiguredView;
@property (nonatomic, assign) IBOutlet NSView *dropboxErrorView;
@property (nonatomic, assign) IBOutlet NSTextField *dropboxErrorMessageTextField;
@property (nonatomic, assign) IBOutlet NSView *dropboxListOfAvailableDocumentsView;
@property (nonatomic, assign) IBOutlet NSTableView *dropboxListOfAvailableDocumentsTableView;
@property (nonatomic, assign) IBOutlet NSArrayController *dropboxListOfAvailableDocumentsArrayController;
@property (nonatomic, assign) IBOutlet NSTableColumn *dropboxListOfAvailableDocumentsDescriptionColumn;
@property (nonatomic, assign) IBOutlet NSTableColumn *dropboxListOfAvailableDocumentsLastSyncColumn;
@property (nonatomic, retain) NSArray *dropboxListOfAvailableDocumentsArray;

@end
