//
//  ContactViewController.m
//  CallSample
//
//  Created by Kiran Vangara on 05/02/15.
//  Copyright © 2015-2018, Connect Arena Private Limited. All rights reserved.
//

//#import <AddressBook/AddressBook.h>
#import <CoreFoundation/CoreFoundation.h>
#import <CoreFoundation/CFArray.h>
#import "ContactViewController.h"
#import "CallViewController.h"
#import "AppSettings.h"
#import "CallManager.h"
#import "VideoCallViewController.h"

@import Contacts;

@import VoxSDK;

const NSInteger VIEW_MODE_CONTACTS  = 0;
const NSInteger VIEW_MODE_GROUPS  = 1;

@interface ContactViewController ()<UISearchBarDelegate>

@property (weak, nonatomic) IBOutlet UIButton *audioCallBtn;






@property (weak, nonatomic) IBOutlet UITableView *contactTableView;
@property (weak, nonatomic) IBOutlet UISearchBar *search_bar;
@property (strong, nonatomic) CNContactStore* store;
@property (strong, nonatomic) NSMutableArray  *contactArray;
@property (strong, nonatomic) NSArray *searchResults;
@property (strong, nonatomic) NSArray *groupArray;
@property (nonatomic) NSInteger viewMode;
@property (strong, nonatomic) NSIndexPath* selectedIndexPath;


@property (nonatomic) BOOL allContactsFlag, isSearching;



@property (strong, nonatomic) IBOutlet UILabel *noDataLabel;

@end


@implementation ContactViewController

@synthesize contactArray;
@synthesize selectedIndexPath;

#pragma mark - ViewDidLoad

- (void)viewDidLoad {
	
    [super viewDidLoad];
    // Do any additional setup after loading the view.
	
	self.store = [[CNContactStore alloc] init];

    CSClient *appManager = [CSClient sharedInstance];
    
    if(![CSSettings getAutoSignin]) {
        [appManager login:[CSSettings getLoginId]
             withPassword:[CSSettings getPassword]
		completionHandler:nil];
    }
    
    // register for reload group info
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleReloadContacts:) name:@"ReloadContactsNotification" object:nil];
	
    
    self.viewMode = VIEW_MODE_CONTACTS;
	
    self.allContactsFlag = [AppSettings getAllContactsFlag];
    
    // empty cells
    self.contactTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
	
    CSContactStore* contactStore = [CSContactStore sharedInstance];
	if(![contactStore isAccessGrantedForContacts])
		[contactStore promptContactAccess];

	
	[self loadContacts];
    NSLog(@"ContactViewController::viewDidLoad getContacts : %zd", (unsigned long)self.contactArray.count);

    selectedIndexPath = nil;
    
}

#pragma mark - dealloc

-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - ViewWillAppear

-(void)viewWillAppear:(BOOL)animated {
	
	
	[self refreshBadgeCount];
	
}

#pragma mark - WillDisappear

-(void)viewWillDisappear:(BOOL)animated {

	
}

#pragma mark - MemoryWarning

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - LoadContacts

//Check Contacts Permission and get all Contacts

-(void)loadContacts {

	CSContactStore* contactStore = [CSContactStore sharedInstance];
	NSMutableArray	*tempContactArray = [[NSMutableArray alloc] init];

	[contactStore getContactList:&tempContactArray flag:self.allContactsFlag];
	self.contactArray = [[NSMutableArray alloc] initWithArray:tempContactArray];

	NSMutableArray* removedContacts = [[NSMutableArray alloc] init];
	
	for (CSContact* contact in self.contactArray) {
		
		NSMutableArray* numbers = [[NSMutableArray alloc] init];
		
		for(CSNumber* phoneNumber in contact.numbers) {
			
			if(![phoneNumber.number isEqualToString:[CSSettings getLoginId]]) {
				[numbers addObject:phoneNumber];
			}
		}
		
		if(numbers.count == 0)
			[removedContacts addObject:contact];
		else
			contact.numbers = numbers;
	}
	
	for(CSContact* contact in removedContacts)
		[self.contactArray removeObject:contact];
	
	if(self.contactArray.count > 0)
		self.contactTableView.backgroundView = nil;
	else {

		if(![[CSContactStore sharedInstance] isAccessGrantedForContacts]) {
			self.noDataLabel.text = @"You denied permission for Contacts.\nPlease enable from Settings";
		}
		else {
			if(self.allContactsFlag == TRUE) {
				self.noDataLabel.text = @"No contacts to show";
			}
			else {
				self.noDataLabel.text = @"Your friends are not yet using CallSample";
			}
		}
		self.contactTableView.backgroundView = self.noDataLabel;
	}

	[self.contactTableView reloadData];
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    
    if(selectedIndexPath) {
        
        NSIndexPath *indexPath = selectedIndexPath;
        
        selectedIndexPath = nil;
        
        if(self.isSearching) {
            [self.contactTableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:(UITableViewRowAnimationAutomatic)];
        }
        else {
            [self.contactTableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:(UITableViewRowAnimationAutomatic)];
        }
    }
}

#pragma mark - UnwindSegue

//Can use tranfer data from Another controller to here

- (IBAction)unwindFromAddParticipantViewController: (UIStoryboardSegue *)segue {
    
    [self.contactTableView reloadData];
    
    
}

//Making an image with Color in required sizes

- (UIImage*) imageWithColor:(UIColor*)color size:(CGSize)size
{
    UIGraphicsBeginImageContext(size);
    UIBezierPath* rPath = [UIBezierPath bezierPathWithRect:CGRectMake(0.0, 0.0, size.width, size.height)];
    [color setFill];
    [rPath fill];
    UIImage* image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

#pragma mark Rotation

-(BOOL)shouldAutorotate {
	
	return NO;
}

-(UIInterfaceOrientationMask)supportedInterfaceOrientations {
	
	return UIInterfaceOrientationMaskPortrait;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
	
	return UIInterfaceOrientationPortrait;
}

#pragma mark - Search Handling


//Search Begin editing
- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    // only show the status bar’s cancel button while in edit mode sbar (UISearchBar)
    searchBar.showsCancelButton = YES;
    self.isSearching = YES;
	//searchBar.tintColor = [UIColor redColor];
//    searchBar.barTintColor = [UIColor colorWithRed:0.0 green:137.0/255.0 blue:123.0/255.0 alpha:1.0];
    searchBar.autocorrectionType = UITextAutocorrectionTypeNo;
}

//Search bar Keyboard Search button action

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
}

//Search bar Cancel button action

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    searchBar.showsCancelButton = NO;
    self.isSearching = NO;
    [searchBar resignFirstResponder];
    searchBar.text = @"";
    [self.contactTableView reloadData];
}

//Search bar end editing

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
    searchBar.showsCancelButton = NO;
    self.isSearching = NO;
    [searchBar resignFirstResponder];
    [self.contactTableView reloadData];
}

//Search bar textdidchange to get search text and filter contacts with Name/Number

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    
    if([searchText length] != 0) {
        self.isSearching = YES;
        [self filterContentForSearchText:searchText scope:nil];
    }
    else {
        self.isSearching = NO;
    }
    [self.contactTableView reloadData];
}

#pragma mark - FilterContent SearchText

//Filtering contacts for Search Text

- (void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope {
	
	if(self.viewMode == VIEW_MODE_CONTACTS) {
		
		NSPredicate *resultPredicate =  [NSPredicate predicateWithBlock:^BOOL(id contactData, NSDictionary *bindings) {
			
			NSString *matchString = ((CSContact*)contactData).name;
			
			if(matchString != nil &&
			   [matchString rangeOfString:searchText options:NSCaseInsensitiveSearch].location != NSNotFound)
				return TRUE;
			
			CSNumber* phoneNumber = [((CSContact*)contactData).numbers objectAtIndex:0];
			
			matchString  = phoneNumber.number;
			if([matchString rangeOfString:searchText options:NSCaseInsensitiveSearch].location != NSNotFound)
				return TRUE;
			
			matchString = [matchString stringByReplacingOccurrencesOfString:@"(" withString:@""];
			matchString = [matchString stringByReplacingOccurrencesOfString:@")" withString:@""];
			matchString = [matchString stringByReplacingOccurrencesOfString:@"-" withString:@""];
			
			NSArray* spaces = [matchString componentsSeparatedByCharactersInSet :[NSCharacterSet whitespaceCharacterSet]];
			matchString  = [spaces componentsJoinedByString:@""];
			
			return ([matchString rangeOfString:searchText options:NSCaseInsensitiveSearch].location != NSNotFound);
		}];
		
		self.searchResults = [contactArray filteredArrayUsingPredicate:resultPredicate];
	}
}

#pragma mark - TableView Handling

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	
	if (self.isSearching)
		return [self.searchResults count];
    
    return [self.contactArray count];
    
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	
    if([selectedIndexPath isEqual:indexPath])
        return 128.0f;
    
    return 64.0f;
}

//-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
//    
//        if(selectedIndexPath)
//            [tableView reloadRowsAtIndexPaths:@[selectedIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
//        
//        selectedIndexPath = indexPath;
//
//        [self performSegueWithIdentifier:@"showContactDetails" sender:self];
//        selectedIndexPath = nil;
//    
//}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *contactCellIdentifier = @"ContactCell";
    static NSString *ContactOptionsCellIdentifier = @"ContactOptionsCell";
    
    UITableViewCell *cell = nil;
    
    CSContact *contactRecord = nil;
    
        if (self.isSearching)
            contactRecord = [self.searchResults objectAtIndex:indexPath.row];
        else
            contactRecord = [self.contactArray objectAtIndex:indexPath.row];
    
    if([selectedIndexPath isEqual:indexPath]) {
        cell = [self.contactTableView dequeueReusableCellWithIdentifier:ContactOptionsCellIdentifier];
        if (cell == nil)
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ContactOptionsCellIdentifier];
    }
    else {
        cell = [self.contactTableView dequeueReusableCellWithIdentifier:contactCellIdentifier];
        if (cell == nil)
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:contactCellIdentifier];
    }
    
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    
    UILabel* contactName = (UILabel*)[cell.contentView viewWithTag:102];
    UILabel* contactNumber = (UILabel*)[cell.contentView viewWithTag:103];
    UILabel* initials = (UILabel*)[cell.contentView viewWithTag:104];
    UIButton* callBtn = (UIButton*)[cell.contentView viewWithTag:106];
    UIButton* videoCallBtn = (UIButton*)[cell.contentView viewWithTag:107];
		
        CSNumber* phoneNumber = [contactRecord.numbers objectAtIndex:0];
    
         self.allContactsFlag = [AppSettings getAllContactsFlag];
         if(phoneNumber.contactStatus == CSContactAppStatusUser) {
             callBtn.hidden = NO;
             videoCallBtn.hidden = NO;
          }
         else {
             callBtn.hidden = NO;
             videoCallBtn.hidden = YES;

           }
    
        [callBtn addTarget:self action:@selector(callBtnTapped:) forControlEvents:UIControlEventTouchUpInside];
        [videoCallBtn addTarget:self action:@selector(videoCallBtnTapped:) forControlEvents:UIControlEventTouchUpInside];
		
		for(int i = 0; i < contactRecord.numbers.count; i++) {
			CSNumber* number = [contactRecord.numbers objectAtIndex:i];
			if(number.contactStatus == CSContactAppStatusUser) {
				phoneNumber = number;
				break;
			}
		}
		
		NSString* name;
		
        if (contactRecord.name)
            name = contactRecord.name;
		else {
			if(phoneNumber.profileName.length > 0)
				name = phoneNumber.profileName;
			else
				name = phoneNumber.number;
		}
		
		contactName.text = name;
		
        if([selectedIndexPath isEqual:indexPath])
            contactNumber.text = phoneNumber.number;
        else
            contactNumber.text = phoneNumber.number;
        
        initials.text = @"";
        
        UIImageView *contactImage = (UIImageView*)[cell.contentView viewWithTag:101];
		UIImageView *appContactIcon = (UIImageView*)[cell.contentView viewWithTag:105];
		
		if(phoneNumber.contactStatus == CSContactAppStatusUser)
			appContactIcon.hidden = NO;
		else
			appContactIcon.hidden = YES;
		
		if(phoneNumber.profilePhotoPath.length) {
			
			contactImage.image = [UIImage imageWithContentsOfFile:phoneNumber.profilePhotoPath];
			contactImage.layer.cornerRadius = contactImage.frame.size.width / 2;
			contactImage.clipsToBounds = YES;
		}
		else {
			
			NSError* error;
			
			NSArray *keys = @[CNContactThumbnailImageDataKey];

			CNContact* contact = [self.store unifiedContactWithIdentifier:contactRecord.recordID
											 keysToFetch:keys
												   error:&error];
			
			if(contact != nil) {

				if(contact.thumbnailImageData) {
					contactImage.image = [UIImage imageWithData:contact.thumbnailImageData];
					contactImage.layer.cornerRadius = contactImage.frame.size.width / 2;
					contactImage.clipsToBounds = YES;
				}
				else {
					contactImage.image = [self imageWithColor:[UIColor lightGrayColor] size:contactImage.frame.size];
					contactImage.layer.cornerRadius = contactImage.frame.size.width / 2;
					contactImage.clipsToBounds = YES;
					
					initials.text = [[name substringToIndex:1] uppercaseString];
				}
			}
			else {
				contactImage.image = [self imageWithColor:[UIColor lightGrayColor] size:contactImage.frame.size];
				contactImage.layer.cornerRadius = contactImage.frame.size.width / 2;
				contactImage.clipsToBounds = YES;
				
				initials.text = [[name substringToIndex:1] uppercaseString];
			}
		}
    
    
    return cell;
}


#pragma mark - button actions

//Used for displaying Options between "All Contacts" or "App Contacts"

-(void)callBtnTapped:(UIButton*)sender{
    CSClientState clientState = [[CSClient sharedInstance] getClientState];
    
    if(clientState == CSClientStateInactive) {
        
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"CallSample"
                                                                       message:@"Can't place calls now. Please check your internet connection"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* okButton = [UIAlertAction actionWithTitle:@"Ok"
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction * action)
                                   {
                                   }];
        
        [alert addAction:okButton];
        [self presentViewController:alert animated:YES completion:nil];
        
        return;
    }
    else if(clientState < CSClientStateActive) {
        
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"CallSample"
                                                                       message:@"App not ready. Please try after some time"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* okButton = [UIAlertAction actionWithTitle:@"Ok"
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction * action)
                                   {
                                   }];
        
        [alert addAction:okButton];
        [self presentViewController:alert animated:YES completion:nil];
        
        return;
    }
    
    // Check for microphone permissions
    [[CallManager sharedInstance] checkForMicrophonePermissionWithCompletionHandler:^(BOOL success) {
        
        // TODO for other usages
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if(success) {
                CGPoint buttonPosition = [sender convertPoint:CGPointMake(0, 0) toView:self.contactTableView];
                NSIndexPath *indexPath = [self.contactTableView indexPathForRowAtPoint:buttonPosition];
                NSLog(@"%ld",(long)indexPath.row);
                if (indexPath != nil) {
                    
                    UITabBarController* tabbar = self.tabBarController;
                    [self.tabBarController setSelectedIndex:0];
                    
                    UIViewController* vc = [tabbar.viewControllers objectAtIndex:0];
                    CSContact *contactRecord = nil;
                    
                    if (self.isSearching)
                        contactRecord = [self.searchResults objectAtIndex:indexPath.row];
                    else
                        contactRecord = [self.contactArray objectAtIndex:indexPath.row];
                    
                    CSNumber* phoneNumber = [contactRecord.numbers objectAtIndex:0];
                    
                    CallViewController* callViewController = (CallViewController*)[self.storyboard instantiateViewControllerWithIdentifier:@"CallViewController"];
                    
                    callViewController.recordID = contactRecord.recordID;
                    callViewController.remoteNumber = phoneNumber.number;
                    callViewController.outgoingCall = TRUE;
                    if(phoneNumber.contactStatus == CSContactAppStatusUser) {
                         callViewController.pstnCall = FALSE;
                    }else{
                         callViewController.pstnCall = TRUE;
                    }
                   
                    
                    [vc presentViewController:callViewController animated:YES completion:^{
                        [self.navigationController popViewControllerAnimated:NO];
                    }];
                }
            }
            else {
                UIAlertController* alert = [UIAlertController alertControllerWithTitle:nil
                                                                               message:@"CallSample needs microphone permission to place calls. Enable in Settings and try again"
                                                                        preferredStyle:UIAlertControllerStyleAlert];
                
                UIAlertAction* settingsButton = [UIAlertAction actionWithTitle:@"Settings" style:UIAlertActionStyleDefault handler:^(UIAlertAction* action)
                                                 {
                                                     [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
                                                 }];
                [alert addAction:settingsButton];
                
                UIAlertAction* okButton = [UIAlertAction actionWithTitle:@"Ok"
                                                                   style:UIAlertActionStyleDefault
                                                                 handler:^(UIAlertAction * action)
                                           {
                                           }];
                
                [alert addAction:okButton];
                [self presentViewController:alert animated:YES completion:nil];
                
            }
        });
    }];
}
-(void)videoCallBtnTapped:(UIButton*)sender{
    CSClientState clientState = [[CSClient sharedInstance] getClientState];
    
    if(clientState == CSClientStateInactive) {
        
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"CallSample"
                                                                       message:@"Can't place calls now. Please check your internet connection"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* okButton = [UIAlertAction actionWithTitle:@"Ok"
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction * action)
                                   {
                                   }];
        
        [alert addAction:okButton];
        [self presentViewController:alert animated:YES completion:nil];
        
        return;
    }
    else if(clientState < CSClientStateActive) {
        
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"CallSample"
                                                                       message:@"App not ready. Please try after some time"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* okButton = [UIAlertAction actionWithTitle:@"Ok"
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction * action)
                                   {
                                   }];
        
        [alert addAction:okButton];
        [self presentViewController:alert animated:YES completion:nil];
        
        return;
    }
    
    CGPoint buttonPosition = [sender convertPoint:CGPointMake(0, 0) toView:self.contactTableView];
    NSIndexPath *indexPath = [self.contactTableView indexPathForRowAtPoint:buttonPosition];
    
    if (indexPath != nil) {
        
        //! Check for microphone permissions
        [[CallManager sharedInstance] checkForMicrophonePermissionWithCompletionHandler:^(BOOL success) {
            
            if(success) {
                
                //! Check for Camera permissions
                [[CallManager sharedInstance] checkForCameraPermissionWithCompletionHandler:^(BOOL success) {
                    
                    if(success) {
                        
                        UITabBarController* tabbar = self.tabBarController;
                        [self.tabBarController setSelectedIndex:0];
                        
                        UIViewController* vc = [tabbar.viewControllers objectAtIndex:0];
                        CSContact *contactRecord = nil;
                        if (self.isSearching)
                            contactRecord = [self.searchResults objectAtIndex:indexPath.row];
                        else
                            contactRecord = [self.contactArray objectAtIndex:indexPath.row];
                        CSNumber* phoneNumber = [contactRecord.numbers objectAtIndex:0];
                        
                        VideoCallViewController* callViewController = (VideoCallViewController*)[self.storyboard instantiateViewControllerWithIdentifier:@"VideoCallViewController"];
                        
                        callViewController.recordID = contactRecord.recordID;
                        callViewController.remoteNumber = phoneNumber.number;
                        callViewController.outgoingCall = TRUE;
                        callViewController.pstnCall = FALSE;
                        
                        [vc presentViewController:callViewController animated:YES completion:^{
                            [self.navigationController popViewControllerAnimated:NO];
                        }];
                        
                    }
                    else {
                        UIAlertController* alert = [UIAlertController alertControllerWithTitle:nil
                                                                                       message:@"CallSample needs camera permission to place video calls. Enable in Settings and try again"
                                                                                preferredStyle:UIAlertControllerStyleAlert];
                        
                        UIAlertAction* settingsButton = [UIAlertAction actionWithTitle:@"Settings" style:UIAlertActionStyleDefault handler:^(UIAlertAction* action)
                                                         {
                                                             [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
                                                         }];
                        [alert addAction:settingsButton];
                        
                        UIAlertAction* okButton = [UIAlertAction actionWithTitle:@"Ok"
                                                                           style:UIAlertActionStyleDefault
                                                                         handler:^(UIAlertAction * action)
                                                   {
                                                   }];
                        
                        [alert addAction:okButton];
                        [self presentViewController:alert animated:YES completion:nil];
                    }
                }];
            }
            else {
                UIAlertController* alert = [UIAlertController alertControllerWithTitle:nil
                                                                               message:@"CallSample needs microphone permission to place calls. Enable in Settings and try again"
                                                                        preferredStyle:UIAlertControllerStyleAlert];
                
                UIAlertAction* settingsButton = [UIAlertAction actionWithTitle:@"Settings" style:UIAlertActionStyleDefault handler:^(UIAlertAction* action)
                                                 {
                                                     [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
                                                 }];
                [alert addAction:settingsButton];
                
                UIAlertAction* okButton = [UIAlertAction actionWithTitle:@"Ok"
                                                                   style:UIAlertActionStyleDefault
                                                                 handler:^(UIAlertAction * action)
                                           {
                                           }];
                
                [alert addAction:okButton];
                [self presentViewController:alert animated:YES completion:nil];
            }
        }];
    }
}

- (IBAction)contextMenuAction:(id)sender {
	
		if(self.allContactsFlag == TRUE) {
            [self displayAlertForContacts:@"APP Contacts"];
		}
		else {
            [self displayAlertForContacts:@"All Contacts"];
		}
	
}

//Method is used for Dispalying Actionsheet for Above options

-(void)displayAlertForContacts:(NSString *)btnTitle {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        
        [alertVC addAction:[UIAlertAction actionWithTitle:btnTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            if(self.allContactsFlag == FALSE) {
                [AppSettings setAllContactsFlag:TRUE];
                self.allContactsFlag = TRUE;
            }
            else {
                [AppSettings setAllContactsFlag:FALSE];
                self.allContactsFlag = FALSE;
            }
            [self loadContacts];
        }]];
        
        [alertVC addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
        
        [self presentViewController:alertVC animated:true completion:nil];
    });
}


#pragma mark - handle notification

//Used for Loading Contacts from Notification

-(void) handleReloadContacts:(NSNotification*)notification {
	[self loadContacts];
}

#pragma mark - Badge Count

//Displaying Missed calls Count on Tabbar Calls tab

-(void) refreshBadgeCount {

	NSDictionary* notifications = [[CSDataStore sharedInstance] getNotificationCount];

	// Calls
	NSInteger callCount = [notifications[@"callCount"] integerValue];
	
	if(callCount == 0)
		[[self.tabBarController.tabBar.items objectAtIndex:1] setBadgeValue:nil];
	else
		[[self.tabBarController.tabBar.items objectAtIndex:1] setBadgeValue:[NSString stringWithFormat:@"%zd", callCount]];
	
}

@end
