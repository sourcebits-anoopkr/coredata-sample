//
//  SBFacebookViewController.m
//  SLFacebook
//
//  Created by Anoop Radhakrishnan on 25/04/14.
//  Copyright (c) 2014 Sourcebits. All rights reserved.
//

#import "SBFacebookViewController.h"
#import <FacebookSDK/FacebookSDK.h>

@implementation SBFacebookViewController
@synthesize m_delegate;

-(id)init {
    if (self = [super init]) {
       
    }
    return self;
}

- (void)sessionStateChanged:(FBSession *)session state:(FBSessionState) state error:(NSError *)error
{
    if (!error && state == FBSessionStateOpen){
        
        NSLog(@"Session opened");
        
        [self userLoggedIn];
        
        [FBRequestConnection startWithGraphPath:@"me" parameters:[NSMutableDictionary dictionaryWithObjectsAndKeys:@"name,education",@"fields",nil] HTTPMethod:@"GET" completionHandler:^(FBRequestConnection *connection, id result, NSError *error)
         {
             NSLog(@"Getting Requested FB User Data");
             
             NSDictionary *userData = (NSDictionary *)result;
             NSString *picURLString =  [NSString stringWithFormat:@"https://graph.facebook.com/me/picture?type=large&return_ssl_resources=1&access_token=%@", [[FBSession activeSession]accessTokenData]];
             
             [m_delegate UserLogged:YES withFBUserData:userData withImageURL:picURLString];
             
         }];
         
        return;
    }
    if (state == FBSessionStateClosed || state == FBSessionStateClosedLoginFailed){
        
        NSLog(@"Session closed");
        [self userLoggedOut];
    }
    
    if (error){
        NSLog(@"Error");
        NSString *alertText;
        NSString *alertTitle;
        
        if ([FBErrorUtility shouldNotifyUserForError:error] == YES){
            alertTitle = @"Something went wrong";
            alertText = [FBErrorUtility userMessageForError:error];
            [self showMessage:alertText withTitle:alertTitle];
        }
        else
        {
            
            if ([FBErrorUtility errorCategoryForError:error] == FBErrorCategoryUserCancelled) {
                NSLog(@"User cancelled login");
                
            }
            else if ([FBErrorUtility errorCategoryForError:error] == FBErrorCategoryAuthenticationReopenSession){
                alertTitle = @"Session Error";
                alertText = @"Your current session is no longer valid. Please log in again.";
                [self showMessage:alertText withTitle:alertTitle];
            }
            else{
                
                NSDictionary *errorInformation = [[[error.userInfo objectForKey:@"com.facebook.sdk:ParsedJSONResponseKey"] objectForKey:@"body"] objectForKey:@"error"];
                
                alertTitle = @"Something went wrong";
                alertText = [NSString stringWithFormat:@"Please retry. \n\n If the problem persists contact us and mention this error code: %@", [errorInformation objectForKey:@"message"]];
                [self showMessage:alertText withTitle:alertTitle];
            }
        }
        
        [FBSession.activeSession closeAndClearTokenInformation];
        [self userLoggedOut];
    }
}

- (void)userLoggedIn
{
    
}

- (void)userLoggedOut
{
    [m_delegate UserLogged:NO withFBUserData:nil withImageURL:nil];
}

- (void)showMessage:(NSString *)text withTitle:(NSString *)title
{
    [[[UIAlertView alloc] initWithTitle:title
                                message:text
                               delegate:self
                      cancelButtonTitle:@"OK!"
                      otherButtonTitles:nil] show];
}

@end
