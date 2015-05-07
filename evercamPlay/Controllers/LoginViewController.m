//
//  LoginViewController.m
//  evercamPlay
//
//  Created by jw on 3/8/15.
//  Copyright (c) 2015 evercom. All rights reserved.
//

#import "LoginViewController.h"
#import "SWRevealViewController.h"
#import "MenuViewController.h"
#import "CamerasViewController.h"
#import "SignupViewController.h"
#import "EvercamShell.h"
#import "AppUser.h"
#import "EvercamUser.h"
#import "EvercamApiKeyPair.h"
#import "AppDelegate.h"

@interface LoginViewController ()
{
    UITextField *activeTextField;
}
@end

@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.screenName = @"Login";
    // Do any additional setup after loading the view from its nib.
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = self.view.bounds;
    gradient.colors = [NSArray arrayWithObjects:(id)[[UIColor blackColor] CGColor], (id)[[UIColor colorWithRed:39.0/255.0 green:45.0/255.0 blue:51.0/255.0 alpha:1.0] CGColor], nil];
    [self.view.layer insertSublayer:gradient atIndex:0];
    self.contentView.contentSize = self.contentView.bounds.size;
    
    if ([self.txt_username respondsToSelector:@selector(setAttributedPlaceholder:)]) {
        UIColor *color = [UIColor lightTextColor];
        self.txt_username.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Email/Username" attributes:@{NSForegroundColorAttributeName: color}];
        self.txt_password.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Password" attributes:@{NSForegroundColorAttributeName: color}];
    } else {
        NSLog(@"Cannot set placeholder text's color, because deployment target is earlier than iOS 6.0");
        // TODO: Add fall-back code to set placeholder color.
    }
    
    UITapGestureRecognizer *singleFingerTap =
    [[UITapGestureRecognizer alloc] initWithTarget:self
                                            action:@selector(handleSingleTap:)];
    [self.view addGestureRecognizer:singleFingerTap];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onKeyboardShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onKeyboardHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillShowNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillHideNotification
                                                  object:nil];
}

- (IBAction)onLogin:(id)sender
{
    NSString *username = _txt_username.text;
    NSString *password = _txt_password.text;
    
    if ([username stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]].length <= 0)
    {
        UIAlertController * alert=   [UIAlertController
                                      alertControllerWithTitle:@"Username required"
                                      message:nil
                                      preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* ok = [UIAlertAction
                             actionWithTitle:@"OK"
                             style:UIAlertActionStyleDefault
                             handler:^(UIAlertAction * action)
                             {
                                 [alert dismissViewControllerAnimated:YES completion:nil];
                                 [_txt_username becomeFirstResponder];
                             }];
        [alert addAction:ok];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }
    else if ([username containsString:@" "])
    {
        UIAlertController * alert=   [UIAlertController
                                      alertControllerWithTitle:@"Invalid username"
                                      message:nil
                                      preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* ok = [UIAlertAction
                             actionWithTitle:@"OK"
                             style:UIAlertActionStyleDefault
                             handler:^(UIAlertAction * action)
                             {
                                 [alert dismissViewControllerAnimated:YES completion:nil];
                                 [_txt_username becomeFirstResponder];
                             }];
        [alert addAction:ok];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }
    else if (password.length <= 0)
    {
        UIAlertController * alert=   [UIAlertController
                                      alertControllerWithTitle:@"Password required"
                                      message:nil
                                      preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* ok = [UIAlertAction
                             actionWithTitle:@"OK"
                             style:UIAlertActionStyleDefault
                             handler:^(UIAlertAction * action)
                             {
                                 [alert dismissViewControllerAnimated:YES completion:nil];
                                 [_txt_password becomeFirstResponder];
                             }];
        [alert addAction:ok];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }
    

    [_activityIndicator startAnimating];
    [[EvercamShell shell] requestEvercamAPIKeyFromEvercamUser:username Password:password WithBlock:^(EvercamApiKeyPair *userKeyPair, NSError *error) {
        if (error == nil)
        {
            [[EvercamShell shell] getUserFromId:username withBlock:^(EvercamUser *newuser, NSError *error) {
                [_activityIndicator stopAnimating];
                if (error == nil) {
                    AppUser *user = [APP_DELEGATE userWithName:newuser.username];
                    [user setDataWithEvercamUser:newuser];
                    [user setApiKeyPairWithApiKey:userKeyPair.apiKey andApiId:userKeyPair.apiId];
                    [APP_DELEGATE saveContext];
                    [APP_DELEGATE setDefaultUser:user];
                    
                    CamerasViewController *camerasViewController = [[CamerasViewController alloc] init];
                    MenuViewController *menuViewController = [[MenuViewController alloc] init];
                    
                    UINavigationController *frontNavigationController = [[UINavigationController alloc] initWithRootViewController:camerasViewController];
                    frontNavigationController.navigationBarHidden = YES;
                    UINavigationController *rearNavigationController = [[UINavigationController alloc] initWithRootViewController:menuViewController];
                    rearNavigationController.navigationBarHidden = YES;
                    
                    SWRevealViewController *revealController = [[SWRevealViewController alloc] initWithRearViewController:rearNavigationController frontViewController:frontNavigationController];
                    NSMutableArray *vcArr = [NSMutableArray arrayWithArray:self.navigationController.viewControllers];
                    [vcArr removeLastObject];
                    [vcArr addObject:revealController];
                    [self.navigationController setViewControllers:vcArr animated:YES];

                } else {
                    NSLog(@"Error %li: %@", (long)error.code, error.description);
                    UIAlertController * alert=   [UIAlertController
                                                  alertControllerWithTitle: nil
                                                  message:error.localizedDescription
                                                  preferredStyle:UIAlertControllerStyleAlert];
                    
                    UIAlertAction* ok = [UIAlertAction
                                         actionWithTitle:@"OK"
                                         style:UIAlertActionStyleDefault
                                         handler:^(UIAlertAction * action)
                                         {
                                             [alert dismissViewControllerAnimated:YES completion:nil];
                                         }];
                    [alert addAction:ok];
                    [self presentViewController:alert animated:YES completion:nil];
                }
            }];
            
        }
        else
        {
            [_activityIndicator stopAnimating];
            NSLog(@"Error %li: %@", (long)error.code, error.description);
            UIAlertController * alert=   [UIAlertController
                                          alertControllerWithTitle: nil
                                          message:error.localizedDescription
                                          preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction* ok = [UIAlertAction
                                 actionWithTitle:@"OK"
                                 style:UIAlertActionStyleDefault
                                 handler:^(UIAlertAction * action)
                                 {
                                     [alert dismissViewControllerAnimated:YES completion:nil];
                                 }];
            [alert addAction:ok];
            [self presentViewController:alert animated:YES completion:nil];
        }
    }];
}

- (IBAction)onBack:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)onCreateAccount:(id)sender
{
    SignupViewController *vc = [[SignupViewController alloc] initWithNibName:@"SignupViewController" bundle:nil];
    NSMutableArray *vcArr = [NSMutableArray arrayWithArray:self.navigationController.viewControllers];
    [vcArr removeLastObject];
    [vcArr addObject:vc];
    [self.navigationController setViewControllers:vcArr animated:YES];
}

#pragma mark UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == self.txt_username)
    {
        [self.txt_password becomeFirstResponder];
    }
    else if (textField == self.txt_password)
    {
        [self.txt_password resignFirstResponder];
    }
    
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    activeTextField = textField;
}

#pragma mark - UIKeyboard events
// Called when UIKeyboardWillShowNotification is sent
- (void)onKeyboardShow:(NSNotification*)notification
{
    // if we have no view or are not visible in any window, we don't care
    if (!self.isViewLoaded || !self.view.window) {
        return;
    }
    
    NSDictionary *userInfo = [notification userInfo];
    
    CGRect keyboardFrameInWindow;
    [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] getValue:&keyboardFrameInWindow];
    
    // the keyboard frame is specified in window-level coordinates. this calculates the frame as if it were a subview of our view, making it a sibling of the scroll view
    CGRect keyboardFrameInView = [self.view convertRect:keyboardFrameInWindow fromView:nil];
    
    CGRect scrollViewKeyboardIntersection = CGRectIntersection(_contentView.frame, keyboardFrameInView);
    UIEdgeInsets newContentInsets = UIEdgeInsetsMake(0, 0, scrollViewKeyboardIntersection.size.height, 0);
    
    // this is an old animation method, but the only one that retains compaitiblity between parameters (duration, curve) and the values contained in the userInfo-Dictionary.
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:[[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue]];
    [UIView setAnimationCurve:[[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue]];
    
    _contentView.contentInset = newContentInsets;
    _contentView.scrollIndicatorInsets = newContentInsets;
    
    /*
     * Depending on visual layout, _focusedControl should either be the input field (UITextField,..) or another element
     * that should be visible, e.g. a purchase button below an amount text field
     * it makes sense to set _focusedControl in delegates like -textFieldShouldBeginEditing: if you have multiple input fields
     */
    if (activeTextField) {
        CGRect controlFrameInScrollView = [_contentView convertRect:_btn_Signup.bounds fromView:_btn_Signup]; // if the control is a deep in the hierarchy below the scroll view, this will calculate the frame as if it were a direct subview
        controlFrameInScrollView = CGRectInset(controlFrameInScrollView, 0, -10); // replace 10 with any nice visual offset between control and keyboard or control and top of the scroll view.
        
        CGFloat controlVisualOffsetToTopOfScrollview = controlFrameInScrollView.origin.y - _contentView.contentOffset.y;
        CGFloat controlVisualBottom = controlVisualOffsetToTopOfScrollview + controlFrameInScrollView.size.height;
        
        // this is the visible part of the scroll view that is not hidden by the keyboard
        CGFloat scrollViewVisibleHeight = _contentView.frame.size.height - scrollViewKeyboardIntersection.size.height;
        
        if (controlVisualBottom > scrollViewVisibleHeight) { // check if the keyboard will hide the control in question
            // scroll up until the control is in place
            CGPoint newContentOffset = _contentView.contentOffset;
            newContentOffset.y += (controlVisualBottom - scrollViewVisibleHeight);
            
            // make sure we don't set an impossible offset caused by the "nice visual offset"
            // if a control is at the bottom of the scroll view, it will end up just above the keyboard to eliminate scrolling inconsistencies
            newContentOffset.y = MIN(newContentOffset.y, _contentView.contentSize.height - scrollViewVisibleHeight);
            
            [_contentView setContentOffset:newContentOffset animated:NO]; // animated:NO because we have created our own animation context around this code
        } else if (controlFrameInScrollView.origin.y < _contentView.contentOffset.y) {
            // if the control is not fully visible, make it so (useful if the user taps on a partially visible input field
            CGPoint newContentOffset = _contentView.contentOffset;
            newContentOffset.y = controlFrameInScrollView.origin.y;
            
            [_contentView setContentOffset:newContentOffset animated:NO]; // animated:NO because we have created our own animation context around this code
        }
    }
    
    [UIView commitAnimations];
}


// Called when the UIKeyboardWillHideNotification is sent
- (void)onKeyboardHide:(NSNotification*)notification
{
    // if we have no view or are not visible in any window, we don't care
    if (!self.isViewLoaded || !self.view.window) {
        return;
    }
    
    NSDictionary *userInfo = notification.userInfo;
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:[[userInfo valueForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue]];
    [UIView setAnimationCurve:[[userInfo valueForKey:UIKeyboardAnimationCurveUserInfoKey] intValue]];
    
    // undo all that keyboardWillShow-magic
    // the scroll view will adjust its contentOffset apropriately
    _contentView.contentInset = UIEdgeInsetsZero;
    _contentView.scrollIndicatorInsets = UIEdgeInsetsZero;
    
    [UIView commitAnimations];
}

#pragma mark - UITapGesture Recognizer
- (void)handleSingleTap:(UITapGestureRecognizer *)recognizer {
    [activeTextField resignFirstResponder];
}

@end