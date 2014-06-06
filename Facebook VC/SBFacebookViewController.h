//
//  SBFacebookViewController.h
//  SLFacebook
//
//  Created by Anoop Radhakrishnan on 25/04/14.
//  Copyright (c) 2014 Sourcebits. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <FacebookSDK/FacebookSDK.h>

@class ViewController;


@protocol FBSessionUIManager<NSObject>
@required
-(void)UserLogged:(BOOL)boolValue withFBUserData:(NSDictionary*)dict withImageURL:(NSString*)imageURLString;
@end

@interface SBFacebookViewController : UIViewController{

}

@property (nonatomic, weak) id<FBSessionUIManager> m_delegate;

- (void)sessionStateChanged:(FBSession *)session state:(FBSessionState) state error:(NSError *)error;

@end
