//
//  AddOrEditViewController.m
//  M3SynchronizationExample
//
//  Created by Klemen Nagode on 8/21/13.
//  Copyright (c) 2013 Mice3. All rights reserved.
//

#import "AddOrEditViewController.h"
#import "AppDelegate.h"
#import "NSManagedObject+markAsDirty.h"


@interface AddOrEditViewController ()

@property (weak, nonatomic) IBOutlet UITextField *licenceNumberTextField;
@property (weak, nonatomic) IBOutlet UITextField *manufacturerTextField;
@property (weak, nonatomic) IBOutlet UITextField *modelTextField;

@property (weak, nonatomic) IBOutlet UIButton *saveButton;


@end

@implementation AddOrEditViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    if (self.car) {
        [self.licenceNumberTextField setText:self.car.licenceNumber];
        [self.manufacturerTextField setText:self.car.manufacturer];
        [self.modelTextField setText:self.car.model];
    }
    
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)saveTapHandler:(id)sender {
    AppDelegate * appDelegate = [[UIApplication sharedApplication] delegate];
    NSManagedObjectContext * context = appDelegate.managedObjectContext;
    
    if (!self.car) {
        self.car = [NSEntityDescription insertNewObjectForEntityForName:@"Car" inManagedObjectContext:context];
        
        [self.car markAsJustInserted];

        
    } else {
        [self.car markAsDirty];
    }
    
    self.car.licenceNumber = self.licenceNumberTextField.text;
    self.car.manufacturer = self.manufacturerTextField.text;
    self.car.model = self.modelTextField.text;
    
    [context save:nil];
    
    
    [self.navigationController popToRootViewControllerAnimated:YES];
}


@end
