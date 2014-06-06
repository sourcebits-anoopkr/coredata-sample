//
//  ViewController.h
//  FBCoredata
//
//  Created by Anoop Radhakrishnan on 05/06/14.
//  Copyright (c) 2014 Sourcebits. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SBFacebookViewController.h"

@interface ViewController : UIViewController<FBSessionUIManager>{
    
}
@property(nonatomic,assign) BOOL IsCachedToken;
@end
