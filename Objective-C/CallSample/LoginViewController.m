//
//  LoginViewController.m
//  CallSample
//
//  Created by Kiran Vangara on 03/05/18.
//  Copyright © 2015-2018, Connect Arena Private Limited. All rights reserved.
//
#import <sys/utsname.h>

#import "LoginViewController.h"
#import "AppSettings.h"

@import VoxSDK;

@interface LoginViewController ()

@property (weak, nonatomic) IBOutlet UITextField *loginID;
@property (weak, nonatomic) IBOutlet UITextField *password;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *nextButton;
@property (weak, nonatomic) IBOutlet UIImageView *image_check;
@property (weak, nonatomic) IBOutlet UIButton *checkmark;

@property (strong, nonatomic) UILabel *nameLabel;
@property (strong, nonatomic) UIActivityIndicatorView *activityIndicator;
@property (nonatomic) CSClientState clientState;

@property (nonatomic, retain) UIButton *doneButton;

@end



@implementation LoginViewController

#pragma mark - ViewDidLoad

- (void)viewDidLoad {
	
    [super viewDidLoad];
	
    // register for signup responce
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleAppStateNotification:) name:@"AppStateNotification" object:nil];
	
    CSClient *appManager = [CSClient sharedInstance];
    self.clientState = [appManager getClientState];
    
    self.nameLabel = [[UILabel alloc] init];
//    self.nameLabel.text = @"";
    self.nameLabel.backgroundColor = [UIColor clearColor];
    self.nameLabel.textColor = [UIColor whiteColor];
    self.nameLabel.font = [UIFont systemFontOfSize:16.0];
    self.nameLabel.textAlignment = NSTextAlignmentCenter;
    self.nameLabel.frame = CGRectMake(0, 0, 200, 44);

    // custom title view for name and last seen info
    UIView * titleView = [[UIView alloc] init];
    [titleView setBackgroundColor:[UIColor clearColor]];
    titleView.frame = CGRectMake(0, 0, 200, 44);
    self.image_check.layer.borderWidth = 1.0;
    self.image_check.layer.borderColor = (__bridge CGColorRef _Nullable)([[UIColor blackColor] colorWithAlphaComponent:0.4]);
    self.image_check.layer.cornerRadius = 4;
    self.image_check.layer.masksToBounds = true;
    [titleView addSubview:self.nameLabel];
    if ([AppSettings getLoginId].length > 0) {
        self.loginID.text = [AppSettings getLoginId];
        self.password.text = [AppSettings getPassword];
        self.image_check.image = [UIImage imageNamed:@"ic_check_mark"];
        self.checkmark.selected = true;
    }
    //! start animation
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 20, 40)];
    self.activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhite;
    
    [titleView addSubview:self.activityIndicator];
    
    self.navigationItem.titleView = titleView;
    
    if(self.clientState == CSClientStateReady)
        [self enableControls:YES title:@"Login"];
    else if(self.clientState == CSClientStateConnecting)
        [self enableControls:NO title:@"Connecting..."];
    else
        [self enableControls:NO title:@"Waiting for network"];
    
    [self.loginID becomeFirstResponder];
}

#pragma mark - didReceiveMemoryWarning

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - dealloc

-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"AppStateNotification" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"LoginResponseNotification" object:nil];
}


#pragma mark - Button Actions

//Button Action For storing Login Credentials

- (IBAction)rememberme_actn:(UIButton *)sender {
    sender.selected = !sender.selected;
    if (self.checkmark.isSelected) {
        self.image_check.image = [UIImage imageNamed:@"ic_check_mark"];
    }else {
        self.image_check.image = [UIImage imageNamed:@"ic_uncheck_mark"];
    }
}

//Button Action for Login (Next BarButton)

- (IBAction) continueAction:(id)sender {
	
	if(self.loginID.text.length == 0) {
		
		UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"CallSample"
																	   message:@"Please enter Login ID"
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
	
	if(self.password.text.length == 0) {
		
		UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"CallSample"
																	   message:@"Please enter password"
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
	
    if(self.loginID.text.length > 0 &&
	   self.password.text.length > 0) {
		[[CSClient sharedInstance] login:self.loginID.text
							withPassword:self.password.text
					   completionHandler:nil];
        
        [[CSClient sharedInstance]login:self.loginID.text withPassword:self.password.text completionHandler:^(NSDictionary *response, NSError *error) {
            if (!error) {
                NSNumber *returnCode = [response objectForKey:kARReturnCode];
                
                if([returnCode intValue] == E_200_OK) { // Login success
                    if (self.checkmark.isSelected) {
                        [AppSettings setLoginId:self.loginID.text];
                        [AppSettings setpassword:self.password.text];
                    }else {
                        [AppSettings setLoginId:nil];
                        [AppSettings setpassword:nil];
                    }
                    UITabBarController *rootViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"TabBarController"];
                    
                    UIView *overlayView = [[UIScreen mainScreen] snapshotViewAfterScreenUpdates:NO];
                    [rootViewController.view addSubview:overlayView];
                    
                    [[UIApplication sharedApplication].keyWindow setRootViewController:rootViewController];
                    [rootViewController setSelectedIndex:0]; // Contacts View
                    
                    [UIView animateWithDuration:0.4f delay:0.0f options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
                        overlayView.alpha = 0;
                    } completion:^(BOOL finished) {
                        [overlayView removeFromSuperview];
                    }];
                    return;
                }
                
                NSString* message = @"Login Failed";
                
                switch ([returnCode intValue]) {
                        
                    case E_401_UNAUTHORIZED: {
                        message = @"Login Failed : Unauthorized";
                    }
                        break;
                        
                    case E_409_NOTALLOWED: {
                        message = @"Login Failed : Not allowed";
                    }
                        break;
                        
                    case E_803_USER_DEACTIVATED: {
                        message = @"Login Failed : User deactivated";
                    }
                        break;
                        
                    default:
                        break;
                }
                
                UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"CallSample"
                                                                               message:message
                                                                        preferredStyle:UIAlertControllerStyleAlert];
                
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

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

#pragma mark - Keyboard handling

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    [self.view endEditing:YES];
    [super touchesBegan:touches withEvent:event];
}

#pragma mark - Notification handlers
-(void) handleAppStateNotification:(NSNotification*)notification {
    
    if ([notification.name isEqualToString:@"AppStateNotification"]) {
        
        NSDictionary* ASNotification = notification.userInfo;
        
        NSNumber *state = [ASNotification objectForKey:kANAppState];
        self.clientState = [state intValue];
        
		switch (self.clientState) {
				
            case CSClientStateActive: {
                
            }
				break;
				
			case CSClientStateReady: {
				[self enableControls:YES title:@"Login"];
			}
				break;
				
			case CSClientStateInactive: {
				[self enableControls:NO title:@"Waiting for network"];
			}
				break;
				
			default: {
				//! TODO handle other states
			}
				break;
		}
    }
}

//Enabling controls

-(void) enableControls:(BOOL)flag title:(NSString*)title {
    
    self.nameLabel.text = title;

    if (flag == TRUE) {
        
		[self.nextButton setEnabled:YES];
		[self.activityIndicator stopAnimating];
    }
    else {
        [self.nextButton setEnabled:NO];
        [self.activityIndicator startAnimating];
    }
}

#pragma mark - Rotation

-(BOOL)shouldAutorotate {
    
    return NO;
}

-(UIInterfaceOrientationMask)supportedInterfaceOrientations {
    
    return UIInterfaceOrientationMaskPortrait;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    
    return UIInterfaceOrientationPortrait;
}

@end
