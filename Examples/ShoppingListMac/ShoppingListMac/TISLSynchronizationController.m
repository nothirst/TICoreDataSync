//
//  TISLSynchronizationController.m
//  ShoppingListMac
//
//  Created by Tim Isted on 30/03/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TISLSynchronizationController.h"
#import "TICoreDataSync.h"

#import "MyDocument.h"

#import <SystemConfiguration/SystemConfiguration.h>
#import <QuartzCore/CoreAnimation.h>

@interface TISLSynchronizationController () <TICDSApplicationSyncManagerDelegate>

- (void)registerDropboxClient;
- (NSURL *)customDropboxLocation;
- (void)increaseSyncActivity;
- (void)decreaseSyncActivity;
- (void)dismissAllSyncActivity;
- (void)replaceView:(NSView *)aView andGoBackwardToView:(NSView *)nextView;
- (void)replaceView:(NSView *)aView andGoForwardToView:(NSView *)previousView;
- (void)replaceAnyExistingViewWithView:(NSView *)aView;

@end

NSString * const kTISLGlobalApplicationIdentifier = @"com.timisted.ShoppingList";
NSString * const kTISLSynchronizationClientIdentifier = @"kTISLSynchronizationClientIdentifier";
NSString * const kTISLSynchronizationUserWantsToSync = @"kTISLSynchronizationUserWantsToSync";
NSString * const kTISLDropboxWebsiteURL = @"http://www.dropbox.com";
NSString * const kTISLDropboxDefaultLocation = @"~/Dropbox";
NSString * const kTISLUserDropboxLocation = @"kTISLUserDropboxLocation";

@implementation TISLSynchronizationController

#pragma mark -
#pragma mark Registration
+ (void)initialize
{
    // Set Logging Verbosity (DEBUG must be #defined to see logs, regardless of verbosity setting)
    [TICDSLog setVerbosity:TICDSLogVerbosityErrorsOnly];
    [TICDSError setIncludeStackTraceInErrors:YES];
}

- (void)enableSynchronizationIfNecessaryShouldOpenViewIfDisabled:(BOOL)shouldOpenView
{
    if( [[NSUserDefaults standardUserDefaults] boolForKey:kTISLSynchronizationUserWantsToSync] ) {
        [self registerDropboxClient];
    } else if( shouldOpenView ) {
        [self showWindow:self];
    }
}

- (void)enableSynchronizationIfEnabledOrShowSyncConfigViewIfDisabled
{
    [self enableSynchronizationIfNecessaryShouldOpenViewIfDisabled:YES];
}

- (void)enableSynchronizationIfNecessary
{
    [self enableSynchronizationIfNecessaryShouldOpenViewIfDisabled:NO];
}

- (void)registerDropboxClient
{
    // Fetch the default sync manager (will be created by this call)
    // This application uses only one global sync manager for any sync'd documents
    TICDSApplicationSyncManager *syncManager = [TICDSFileManagerBasedApplicationSyncManager defaultApplicationSyncManager];
    
    NSURL *dropboxLocation = [NSURL fileURLWithPath:[[NSUserDefaults standardUserDefaults] valueForKey:kTISLUserDropboxLocation]];
    
    [(TICDSFileManagerBasedApplicationSyncManager *)syncManager setApplicationContainingDirectoryLocation:dropboxLocation];
    
    // Get a unique client ID for this client from user defaults, generating one if it doesn't already exist
    NSString *clientUuid = [[NSUserDefaults standardUserDefaults] stringForKey:kTISLSynchronizationClientIdentifier];
    if( !clientUuid ) {
        clientUuid = [TICDSUtilities uuidString];
        [[NSUserDefaults standardUserDefaults] setValue:clientUuid forKey:kTISLSynchronizationClientIdentifier];
    }
    
    // Get the device description (uses SystemConfiguration.framework)
    CFStringRef name = SCDynamicStoreCopyComputerName(NULL,NULL);
    NSString *deviceDescription = [NSString stringWithString:(NSString *)name];
    CFRelease(name);
    
    // Register this sync manager ready for future sync'ing
    [syncManager registerWithDelegate:self globalAppIdentifier:kTISLGlobalApplicationIdentifier uniqueClientIdentifier:clientUuid description:deviceDescription userInfo:[NSDictionary dictionaryWithObject:@"Hello" forKey:@"HelloKey"]];
}

- (void)disableSync
{
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kTISLSynchronizationUserWantsToSync];
    
    [self replaceView:[self dropboxConfiguredView] andGoBackwardToView:[self configureSyncView]];
}

#pragma mark Sync Delegate
- (void)syncManagerDidStartRegistration:(TICDSApplicationSyncManager *)aSyncManager
{
    [self increaseSyncActivity];
}

- (void)syncManagerDidRegisterSuccessfully:(TICDSApplicationSyncManager *)aSyncManager
{
    [self decreaseSyncActivity];
    
    [self replaceAnyExistingViewWithView:[self dropboxConfiguredView]];
    
    [[self mainStatusTextField] setStringValue:NSLocalizedString(@"Sync is On", @"Sync is On")];
}

- (void)syncManager:(TICDSApplicationSyncManager *)aSyncManager encounteredRegistrationError:(NSError *)anError
{
    NSLog(@"Error registering: %@", anError);
}

- (void)syncManagerFailedToRegister:(TICDSApplicationSyncManager *)aSyncManager
{
    NSLog(@"Failed to register");
    [self decreaseSyncActivity];
}

#pragma mark -
#pragma mark List of Available Documents
- (void)fetchListOfAvailableDocuments
{
    TICDSApplicationSyncManager *syncManager = [TICDSFileManagerBasedApplicationSyncManager defaultApplicationSyncManager];
    
    [syncManager requestListOfPreviouslySynchronizedDocuments];
}

#pragma mark Available Docs Delegate
- (void)syncManagerDidBeginToCheckForPreviouslySynchronizedDocuments:(TICDSApplicationSyncManager *)aSyncManager
{
    [self increaseSyncActivity];
}

- (void)syncManager:(TICDSApplicationSyncManager *)aSyncManager failedToCheckForPreviouslySynchronizedDocumentsWithError:(NSError *)anError
{
    [self decreaseSyncActivity];
}

- (void)syncManagerDidNotFindAnyPreviouslySynchronizedDocuments:(TICDSApplicationSyncManager *)aSyncManager
{
    [self decreaseSyncActivity];
}

- (void)syncManager:(TICDSApplicationSyncManager *)aSyncManager didFindPreviouslySynchronizedDocuments:(NSArray *)documentsArray
{
    [self decreaseSyncActivity];
    
    NSSortDescriptor *sortDescriptor = [[[NSSortDescriptor alloc] initWithKey:kTICDSLastSyncDate ascending:NO] autorelease];
    documentsArray = [documentsArray sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    
    [self setDropboxListOfAvailableDocumentsArray:documentsArray];
    [[self dropboxListOfAvailableDocumentsTableView] reloadData];
}

#pragma mark -
#pragma mark Download Document
- (void)downloadSelectedDocument
{
    NSInteger selectedRow = [[self dropboxListOfAvailableDocumentsTableView] selectedRow];
    if( selectedRow < 0 || selectedRow >= [[self dropboxListOfAvailableDocumentsArray] count] ) {
        return;
    }
    
    NSSavePanel *savePanel = [NSSavePanel savePanel];
    [savePanel setAllowedFileTypes:[NSArray arrayWithObject:@"sqlite"]];
    NSString *fileName = [[[self dropboxListOfAvailableDocumentsArray] objectAtIndex:selectedRow] valueForKey:kTICDSDocumentDescription];
        
    if( [savePanel runModalForDirectory:nil file:fileName] == NSFileHandlingPanelCancelButton ) {
        return;
    }
    
    NSURL *fileLocation = [savePanel URL];
    
    NSString *itemIdentifier = [[[self dropboxListOfAvailableDocumentsArray] objectAtIndex:selectedRow] valueForKey:kTICDSDocumentIdentifier];
    
    TICDSApplicationSyncManager *syncManager = [TICDSFileManagerBasedApplicationSyncManager defaultApplicationSyncManager];
    
    [syncManager requestDownloadOfDocumentWithIdentifier:itemIdentifier toLocation:fileLocation];
}

#pragma mark Download Doc Delegate
- (void)syncManager:(TICDSApplicationSyncManager *)aSyncManager didStartToDownloadDocumentWithIdentifier:(NSString *)anIdentifier
{
    [self increaseSyncActivity];
}

- (void)syncManager:(TICDSApplicationSyncManager *)aSyncManager encounteredDownloadError:(NSError *)anError forDownloadOfDocumentWithIdentifier:(NSString *)anIdentifier
{
    NSLog(@"Error downloading: %@", anError);
}

- (void)syncManager:(TICDSApplicationSyncManager *)aSyncManager failedToDownloadDocumentWithIdentifier:(NSString *)anIdentifier
{
    [self decreaseSyncActivity];
}

- (void)syncManager:(TICDSApplicationSyncManager *)aSyncManager willReplaceWholeStoreFileForDocumentWithIdentifier:(NSString *)anIdentifier atLocation:(NSURL *)aLocation
{
    NSLog(@"Replacing the document at %@", aLocation);
}

- (TICDSDocumentSyncManager *)syncManager:(TICDSApplicationSyncManager *)aSyncManager preConfiguredDocumentSyncManagerForDownloadedDocumentWithIdentifier:(NSString *)anIdentifier atLocation:(NSURL *)aLocation
{
    NSLog(@"Downloaded %@ to %@", anIdentifier, aLocation);
    
    NSError *anyError = nil;
    MyDocument *document = [[NSDocumentController sharedDocumentController] makeDocumentWithContentsOfURL:aLocation ofType:@"SQLite" error:&anyError];
    if( !document ) { 
        NSLog(@"Error opening downloaded store: %@", anyError);
        return nil;
    }
    
    [[NSDocumentController sharedDocumentController] addDocument:document];
    
    [document configureSyncManagerForDownloadedStoreWithIdentifier:anIdentifier];
    
    return [document documentSyncManager];
}

- (void)syncManager:(TICDSApplicationSyncManager *)aSyncManager didFinishDownloadingDocumentWithIdentifier:(NSString *)anIdentifier toLocation:(NSURL *)aLocation
{
    [self decreaseSyncActivity];
    NSError *anyError = nil;
    MyDocument *document = [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:aLocation display:YES error:&anyError];
    
    if( !document ) {
        NSLog(@"Error opening document: %@", anyError);
        return;
    }
    
    [document makeWindowControllers];
    [document showWindows];
}

#pragma mark -
#pragma mark View Display
- (void)replaceView:(NSView *)aView andGoBackwardToView:(NSView *)nextView
{
    [[self leftRightAnimation] setSubtype:kCATransitionFromLeft];
    [[[self panelContainerView] animator] replaceSubview:aView with:nextView];
}

- (void)replaceView:(NSView *)aView andGoForwardToView:(NSView *)previousView
{
    [[self leftRightAnimation] setSubtype:kCATransitionFromRight];
    [[[self panelContainerView] animator] replaceSubview:aView with:previousView];
}

- (void)replaceAnyExistingViewWithView:(NSView *)aView
{
    NSView *currentView = [[[self panelContainerView] subviews] lastObject];
    
    if( currentView ) {
        [self replaceView:currentView andGoForwardToView:aView];
    } else {
        [[self panelContainerView] addSubview:aView];
    }
}

#pragma mark -
#pragma mark Lifecycle
- (void)awakeFromNib
{
    // this method will be called twice (once awaking from MainMenu.xib, once from TINCSynchronizationWindow.xib) but it shouldn't matter
    [self window]; // loads the window ready for animations etc
    [[self panelContainerView] setAnimations:[NSDictionary dictionaryWithObject:[self leftRightAnimation] forKey:@"subviews"]];
}

- (void)windowDidLoad
{
    if( ![[NSUserDefaults standardUserDefaults] boolForKey:kTISLSynchronizationUserWantsToSync] ) {
        [self replaceAnyExistingViewWithView:[self configureSyncView]];
    }
}

#pragma mark -
#pragma mark Actions
- (IBAction)configureSyncConfigureAction:(id)sender
{
    [self replaceView:[self configureSyncView] andGoForwardToView:[self syncTypeView]];
}

#pragma mark Sync Type
- (IBAction)syncTypeViewBack:(id)sender
{
    [self replaceView:[self syncTypeView] andGoBackwardToView:[self configureSyncView]];
}

- (IBAction)syncTypeDropboxAction:(id)sender
{
    NSString *defaultDropboxPath = [kTISLDropboxDefaultLocation stringByExpandingTildeInPath];
    
    if( [[self fileManager] fileExistsAtPath:defaultDropboxPath] ) {
        [[self dropboxFoundPathControl] setURL:[NSURL fileURLWithPath:defaultDropboxPath]];
        [self replaceView:[self syncTypeView] andGoForwardToView:[self dropboxFoundView]];
    } else {
        [self replaceView:[self syncTypeView] andGoForwardToView:[self dropboxNotFoundView]];
    }
}

#pragma mark Dropbox Found
- (IBAction)dropboxFoundBackAction:(id)sender
{
    [self replaceView:[self dropboxFoundView] andGoBackwardToView:[self syncTypeView]];
}

- (IBAction)dropboxFoundUseSpecifiedDropbox:(id)sender
{
    NSString *path = [[[self dropboxFoundPathControl] URL] path];
    path = [path stringByAppendingPathComponent:kTISLGlobalApplicationIdentifier];
    
    [[self dropboxCreatePathControl] setURL:[NSURL fileURLWithPath:path]];
    [self replaceView:[self dropboxFoundView] andGoForwardToView:[self dropboxCreateView]];
}

- (IBAction)dropboxFoundChooseAnotherDropbox:(id)sender
{
    NSURL *chosenDropboxURL = [self customDropboxLocation];
    
    if( chosenDropboxURL ) {
        [[self dropboxFoundPathControl] setURL:chosenDropboxURL];
        [[self dropboxCreatePathControl] setURL:[NSURL fileURLWithPath:[[chosenDropboxURL path] stringByAppendingPathComponent:kTISLGlobalApplicationIdentifier]]];
    }
}

#pragma mark Dropbox Not Found
- (IBAction)dropboxNotFoundBackAction:(id)sender
{
    [self replaceView:[self dropboxNotFoundView] andGoBackwardToView:[self syncTypeView]];
}

- (IBAction)dropboxNotFoundVisitDropboxWebsiteAction:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:kTISLDropboxWebsiteURL]];
    
    [self replaceView:[self dropboxNotFoundView] andGoBackwardToView:[self syncTypeView]];
}

- (IBAction)dropboxNotFoundChooseCustomDropboxLocationAction:(id)sender
{
    NSURL *chosenDropboxURL = [self customDropboxLocation];
    
    if( chosenDropboxURL ) {
        [[self dropboxFoundPathControl] setURL:chosenDropboxURL];
        
        [self replaceView:[self dropboxNotFoundView] andGoForwardToView:[self dropboxCreateView]];
    }
}

#pragma mark Dropbox Create
- (IBAction)dropboxCreateBackAction:(id)sender
{
    [self replaceView:[self dropboxCreateView] andGoBackwardToView:[self dropboxFoundView]];
}

- (IBAction)dropboxCreateContinueAction:(id)sender
{
    NSString *path = [[[self dropboxCreatePathControl] URL] path];
    path = [path stringByDeletingLastPathComponent];
    
    [[NSUserDefaults standardUserDefaults] setValue:path forKey:kTISLUserDropboxLocation];
    
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kTISLSynchronizationUserWantsToSync];
    
    [self registerDropboxClient];
}

#pragma mark Dropbox Configured
- (IBAction)dropboxConfiguredDisableSyncAction:(id)sender
{
    [self disableSync];
}

- (IBAction)dropboxConfiguredViewAvailableDocumentsAction:(id)sender
{
    [self setDropboxListOfAvailableDocumentsArray:nil];
    
    //[[self dropboxListOfAvailableDocumentsArrayController] setContent:nil];
    [[self dropboxListOfAvailableDocumentsTableView] reloadData];
    [self replaceView:[self dropboxConfiguredView] andGoForwardToView:[self dropboxListOfAvailableDocumentsView]];
    [self fetchListOfAvailableDocuments];
}

#pragma mark Dropbox List of Available Documents
- (IBAction)dropboxListOfAvailableDocumentsBackAction:(id)sender
{
    [self replaceView:[self dropboxListOfAvailableDocumentsView] andGoBackwardToView:[self dropboxConfiguredView]];
    [self setDropboxListOfAvailableDocumentsArray:nil];
    //[[self dropboxListOfAvailableDocumentsArrayController] setContent:nil];
    [[self dropboxListOfAvailableDocumentsTableView] reloadData];
}

- (IBAction)dropboxListOfAvailableDocumentsDownloadSelectedDocumentAction:(id)sender
{
    [self downloadSelectedDocument];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    if( aTableView != [self dropboxListOfAvailableDocumentsTableView] ) {
        return 0;
    }
    
    return [[self dropboxListOfAvailableDocumentsArray] count];
}

- (NSDateFormatter *)lastSyncDateFormatter
{
    static NSDateFormatter *sLastSyncDateFormatter = nil;
    if( sLastSyncDateFormatter ) {
        return sLastSyncDateFormatter;
    }
    
    sLastSyncDateFormatter = [[NSDateFormatter alloc] init];
    [sLastSyncDateFormatter setTimeStyle:NSDateFormatterShortStyle];
    [sLastSyncDateFormatter setDateStyle:NSDateFormatterShortStyle];
    
    return sLastSyncDateFormatter;
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    if( aTableView != [self dropboxListOfAvailableDocumentsTableView] || rowIndex >= [[self dropboxListOfAvailableDocumentsArray] count] ) {
        return @"";
    }
    
    if( aTableColumn == [self dropboxListOfAvailableDocumentsDescriptionColumn] ) {
        return [[[self dropboxListOfAvailableDocumentsArray] objectAtIndex:rowIndex] valueForKey:kTICDSDocumentDescription];
    } else if( aTableColumn == [self dropboxListOfAvailableDocumentsLastSyncColumn] ) {
        return [[self lastSyncDateFormatter] stringFromDate:[[[self dropboxListOfAvailableDocumentsArray] objectAtIndex:rowIndex] valueForKey:kTICDSLastSyncDate]];
    }
    
    return @"";
}

#pragma mark -
#pragma mark Helpers
- (NSURL *)customDropboxLocation
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel setCanChooseFiles:NO];
    [openPanel setCanChooseDirectories:YES];
    //[openPanel setDirectoryURL:[NSURL fileURLWithPath:NSHomeDirectory()]];
    NSInteger result = [openPanel runModalForDirectory:NSHomeDirectory() file:nil];
    
    if( result == NSOKButton ) {
        return [[openPanel URLs] lastObject];
    } else {
        return nil;
    }
}

#pragma mark -
#pragma mark Sync Activity
- (void)increaseSyncActivity
{
    NSInteger currentActivity = [self syncActivity];
    
    currentActivity++;
    
    if( currentActivity > 0 ) {
        [[self syncLabel] setHidden:NO];
        [[self syncProgressIndicator] setHidden:NO];
        [[self syncProgressIndicator] startAnimation:self];
    }
    
    [self setSyncActivity:currentActivity];
}

- (void)decreaseSyncActivity
{
    NSInteger currentActivity = [self syncActivity];
    
    if( currentActivity > 0 ) {
        currentActivity--;
    }
    
    if( currentActivity < 1 ) {
        [[self syncLabel] setHidden:YES];
        [[self syncProgressIndicator] setHidden:YES];
        [[self syncProgressIndicator] stopAnimation:self];
    }
    
    [self setSyncActivity:currentActivity];
}

- (void)dismissAllSyncActivity
{
    [[self syncLabel] setHidden:YES];
    [[self syncProgressIndicator] setHidden:YES];
    
    [self setSyncActivity:0];
}

#pragma mark -
#pragma mark Initialization and Deallocation
- (id)init
{
    return [super initWithWindowNibName:@"TISLSynchronizationWindow"];
}

- (void)dealloc
{
    [_leftRightAnimation release], _leftRightAnimation = nil;
    [_dropboxListOfAvailableDocumentsArray release], _dropboxListOfAvailableDocumentsArray = nil;
    
    [super dealloc];
}

#pragma mark -
#pragma mark Properties
@synthesize mainStatusTextField = _mainStatusTextField;
@synthesize leftRightAnimation = _leftRightAnimation;
@synthesize fileManager = _fileManager;
@synthesize syncActivity = _syncActivity;
@synthesize syncProgressIndicator = _syncProgressIndicator;
@synthesize syncLabel = _syncLabel;
@synthesize panelContainerView = _panelContainerView;
@synthesize configureSyncView = _configureSyncView;
@synthesize syncTypeView = _syncTypeView;
@synthesize dropboxFoundView = _dropboxFoundView;
@synthesize dropboxFoundPathControl = _dropboxFoundPathControl;
@synthesize dropboxNotFoundView = _dropboxNotFoundView;
@synthesize dropboxCreateView = _dropboxCreateView;
@synthesize dropboxCreatePathControl = _dropboxCreatePathControl;
@synthesize dropboxCreateBackButton = _dropboxCreateBackButton;
@synthesize dropboxCreateContinueButton = _dropboxCreateContinueButton;
@synthesize dropboxConfiguringView = _dropboxConfiguringView;
@synthesize dropboxConfiguringProgressIndicator = _dropboxConfiguringProgressIndicator;
@synthesize dropboxConfiguredView = _dropboxConfiguredView;
@synthesize dropboxErrorView = _dropboxErrorView;
@synthesize dropboxErrorMessageTextField = _dropboxErrorMessageTextField;
@synthesize dropboxListOfAvailableDocumentsView = _dropboxListOfAvailableDocumentsView;
@synthesize dropboxListOfAvailableDocumentsTableView = _dropboxListOfAvailableDocumentsTableView;
@synthesize dropboxListOfAvailableDocumentsArrayController = _dropboxListOfAvailableDocumentsArrayController;
@synthesize dropboxListOfAvailableDocumentsDescriptionColumn = _dropboxListOfAvailableDocumentsDescriptionColumn;
@synthesize dropboxListOfAvailableDocumentsLastSyncColumn = _dropboxListOfAvailableDocumentsLastSyncColumn;
@synthesize dropboxListOfAvailableDocumentsArray = _dropboxListOfAvailableDocumentsArray;

- (CATransition *)leftRightAnimation
{
    if( _leftRightAnimation ) return _leftRightAnimation;
    
    _leftRightAnimation = [[CATransition alloc] init];
    [_leftRightAnimation setType:kCATransitionPush];
    [_leftRightAnimation setSubtype:kCATransitionFromRight];
    
    return _leftRightAnimation;
}

- (NSFileManager *)fileManager
{
    if( _fileManager ) return _fileManager;
    
    _fileManager = [[NSFileManager alloc] init];
    
    return _fileManager;
}

@end
