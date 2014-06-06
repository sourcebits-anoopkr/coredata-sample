//
//  ViewController.m
//  FBCoredata
//
//  Created by Anoop Radhakrishnan on 05/06/14.
//  Copyright (c) 2014 Sourcebits. All rights reserved.
//

#import "ViewController.h"
#import <FacebookSDK/FacebookSDK.h>

@interface ViewController ()
@property (strong,nonatomic) SBFacebookViewController *facebookVC;
@property (strong, nonatomic) IBOutlet UIButton *fbLoginBtn;
@property (strong, nonatomic) IBOutlet UIImageView *profileImageView;
@property (strong, nonatomic) IBOutlet UIButton *showUsernameBTN;
@property (strong, nonatomic) IBOutlet UIButton *showEducationBTN;
@property (strong, nonatomic) IBOutlet UILabel *userNameLbl;
@property (strong, nonatomic) IBOutlet UILabel *educationLbl;
@property (strong,nonatomic) NSArray *userData;
@property (strong,nonatomic) NSArray *userEducation;
@end

@implementation ViewController
@synthesize IsCachedToken;

- (NSManagedObjectContext *)managedObjectContext {
    NSManagedObjectContext *context = nil;
    id delegate = [[UIApplication sharedApplication] delegate];
    if ([delegate performSelector:@selector(managedObjectContext)]) {
        context = [delegate managedObjectContext];
    }
    return context;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    self.facebookVC.m_delegate=self;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(SBFacebookViewController*) facebookVC
{
    if(_facebookVC==nil)
    {
        _facebookVC=[[SBFacebookViewController alloc] init];
    }
    
    return _facebookVC;
}

-(void)viewWillAppear:(BOOL)animated{
    
    [super viewWillAppear:animated];
    
    if([FBSession activeSession].isOpen)
    {
        _showUsernameBTN.hidden = NO;
        _showEducationBTN.hidden = NO;
        _profileImageView.hidden = NO;
        
        [_fbLoginBtn setTitle:@"Log Out" forState:UIControlStateNormal];
    }
    else{
        _showUsernameBTN.hidden = YES;
        _showEducationBTN.hidden = YES;
        _userNameLbl.hidden = YES;
        _educationLbl.hidden = YES;
        _profileImageView.hidden = YES;
        
        [_fbLoginBtn setTitle:@"Login with Facebook" forState:UIControlStateNormal];
    }
}

- (IBAction)logintoFBAccount:(id)sender {
    
    __block __weak ViewController *weakSelf=self;
    
    if (FBSession.activeSession.state == FBSessionStateOpen
        || FBSession.activeSession.state == FBSessionStateOpenTokenExtended)
    {
        IsCachedToken = YES;
        [FBSession.activeSession closeAndClearTokenInformation];
        [weakSelf.facebookVC sessionStateChanged:FBSession.activeSession state:FBSession.activeSession.state error:nil];
        [self deleteAllObjects:@"Fbuserdata"];
    }
    else
    {
        
        [FBSession openActiveSessionWithReadPermissions:@[@"basic_info",@"user_education_history"]
                                           allowLoginUI:YES
                                      completionHandler:
         ^(FBSession *session, FBSessionState state, NSError *error) {
             NSLog(@"Opening FB Session");
             IsCachedToken = NO;
             [weakSelf.facebookVC sessionStateChanged:session state:state error:error];
         }];
    }

}

-(void)UserLogged:(BOOL)boolValue withFBUserData:(NSDictionary*)dict withImageURL:(NSString*)imageURLString
{
    NSLog(@"FB User Sesssion Delegate called");
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if(boolValue){
            _showUsernameBTN.hidden = NO;
            _showEducationBTN.hidden = NO;
            _profileImageView.hidden = NO;

            [_fbLoginBtn setTitle:@"Log Out" forState:UIControlStateNormal];
        }
        else{
            _showUsernameBTN.hidden = YES;
            _showEducationBTN.hidden = YES;
            _userNameLbl.hidden = YES;
            _educationLbl.hidden = YES;
            _profileImageView.hidden = YES;

            [_fbLoginBtn setTitle:@"Login with Facebook" forState:UIControlStateNormal];
        }
        
    });
    
    /*
    NSLog(@"Facebook User Data Dict %@",[dict description]);
    
    NSLog(@"Name = %@", [dict objectForKey:@"name"]);

    NSArray *arrayResult = [dict objectForKey:@"education"];
    for (NSDictionary *result in arrayResult){
        
        NSString *school = [[result objectForKey:@"school"] objectForKey:@"name"];
        NSString *year = [[result objectForKey:@"year"] objectForKey:@"name"];

        NSLog(@"School Name = %@ in Year = %@", school,year);
    }
    */

    [self saveUserDataInToCoredataDatabaseWithDict:dict withImgURL:imageURLString];
    [self showProfilePhoto];

}

-(void)saveUserDataInToCoredataDatabaseWithDict:(NSDictionary*)dict withImgURL:(NSString*)imageURLString{
    
    if(!IsCachedToken)
    {
        //Create a managed object context
        NSManagedObjectContext *context = [self managedObjectContext];
        
        // Create a new managed object
        NSManagedObject *newFBUserData = [NSEntityDescription insertNewObjectForEntityForName:@"Fbuserdata" inManagedObjectContext:context];
        [newFBUserData setValue:[dict objectForKey:@"name"] forKey:@"name"];
        [newFBUserData setValue:imageURLString forKey:@"profilephotoURL"];
        
        // Create a another managed object
        NSManagedObject *newFBUserEdu = [NSEntityDescription insertNewObjectForEntityForName:@"Fbusereducation" inManagedObjectContext:context];
        NSArray *arrayResult = [dict objectForKey:@"education"];
        for (NSDictionary *result in arrayResult){
            
            NSString *school = [[result objectForKey:@"school"] objectForKey:@"name"];
            NSString *year = [[result objectForKey:@"year"] objectForKey:@"name"];
            
            [newFBUserEdu setValue:school  forKey:@"school"];
            [newFBUserEdu setValue:year  forKey:@"year"];
        }
        
        NSError *error = nil;
        // Save the object to persistent store
        if (![context save:&error]) {
            NSLog(@"Can't Save! %@ %@", error, [error localizedDescription]);
        }
    }
}

- (IBAction)showUserName:(id)sender {
    
    if(_userNameLbl.hidden){
        _userNameLbl.hidden = NO;
        [self fetchName];
    }
    else{
        _userNameLbl.hidden = YES;
    }
}

- (IBAction)showEducationDetails:(id)sender {
   
    if(_educationLbl.hidden){
        _educationLbl.hidden = NO;
        [self fetchEducationDetails];
    }
    else{
        _educationLbl.hidden = YES;
    }
    
}

-(void)showProfilePhoto{

    NSManagedObjectContext *managedObjectContext = [self managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Fbuserdata"];
    
    if(self.userData.count != 0){
        self.userData = nil;
    }
    self.userData = [[managedObjectContext executeFetchRequest:fetchRequest error:nil] mutableCopy];
    
    NSString *imageURLString =[NSString stringWithFormat:@"%@",[[self.userData valueForKey:@"profilephotoURL"]objectAtIndex:0]];
    NSString *str  = [imageURLString stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSURL *imageUrl = [NSURL URLWithString:str];
    NSData *imageData = [NSData dataWithContentsOfURL:imageUrl];
    UIImage *image = [UIImage imageWithData:imageData];
    
    if(_profileImageView) _profileImageView.image = nil;
    _profileImageView.image =image;
}

-(void)fetchName{
    
    NSManagedObjectContext *managedObjectContext = [self managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Fbuserdata"];
    
    if(self.userData.count != 0){
        self.userData = nil;
    }
    self.userData = [[managedObjectContext executeFetchRequest:fetchRequest error:nil] mutableCopy];
    
    NSString *nameString =[NSString stringWithFormat:@"%@",[[self.userData valueForKey:@"name"]objectAtIndex:0]];
    
    if(_userNameLbl) _userNameLbl.text = nil;
    
    _userNameLbl.text =nameString;
    
}

-(void)fetchEducationDetails{
    
    NSManagedObjectContext *managedObjectContext = [self managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Fbusereducation"];
    
    if(self.userEducation.count != 0){
        self.userEducation = nil;
    }
    self.userEducation = [[managedObjectContext executeFetchRequest:fetchRequest error:nil] mutableCopy];
    
    NSString *school =[NSString stringWithFormat:@"%@",[[self.userEducation valueForKey:@"school"]objectAtIndex:0]];
    NSString *year =[NSString stringWithFormat:@"%@",[[self.userEducation valueForKey:@"year"]objectAtIndex:0]];

    if(_educationLbl) _educationLbl.text = nil;
    
    _educationLbl.text =[NSString stringWithFormat:@"Studied at %@ in %@",school,year];

}

- (void) deleteAllObjects: (NSString *) entityDescription{
    
    NSManagedObjectContext *context = [self managedObjectContext];

    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:entityDescription inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    
    NSError *error;
    NSArray *items = [context executeFetchRequest:fetchRequest error:&error];
    
    
    for (NSManagedObject *managedObject in items) {
    	[context deleteObject:managedObject];
    	NSLog(@"%@ object deleted",entityDescription);
    }
    if (![context save:&error]) {
    	NSLog(@"Error deleting %@ - error:%@",entityDescription,error);
    }
    
}

@end
