//
//  CarViewController.m
//  M3SynchronizationExample
//
//  Created by Klemen Nagode on 8/21/13.
//  Copyright (c) 2013 Mice3. All rights reserved.
//

#import "CarViewController.h"
#import "M3Synchronization.h"
#import "Constants.h"
#import "AppDelegate.h"
#import "Car.h"
#import "AddOrEditViewController.h"

@interface CarViewController ()


@property (nonatomic, strong) NSMutableArray * cars;

@end

@implementation CarViewController


-(void) viewWillAppear:(BOOL)animated {
    [self refreshData];
}

- (void)refreshData
{
    
    AppDelegate * appDelegate = [[UIApplication sharedApplication] delegate];
    NSManagedObjectContext * context = appDelegate.managedObjectContext;
    
    NSEntityDescription *entityDescription = [NSEntityDescription
                                              entityForName:@"Car" inManagedObjectContext:context];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDescription];
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc]
                                        initWithKey:@"timestampModified" ascending:NO];
    [request setSortDescriptors:@[sortDescriptor]];
    
    NSError *error;
    NSArray *array = [context executeFetchRequest:request error:&error];
    
    self.cars = [NSMutableArray arrayWithArray:array];
    
    if (array == nil)
    {
        // Deal with error...
    }
    
    [self.tableView reloadData];
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [self.cars count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    Car * car = [self.cars objectAtIndex:indexPath.row];
    
    [cell.textLabel setText:car.licenceNumber];

    
    return cell;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Create and push another view controller.
    
    
    UIStoryboard *sboard = [UIStoryboard storyboardWithName:@"Storyboard" bundle:nil];
    
    AddOrEditViewController *viewController = [sboard instantiateViewControllerWithIdentifier:@"AddOrEditViewController"];
    
    viewController.car = [self.cars objectAtIndex:indexPath.row];
     
     [self.navigationController pushViewController:viewController animated:YES];
    
}



- (IBAction) syncButtonTapHandler:(id)sender {
    
    AppDelegate * appDelegate = [[UIApplication sharedApplication] delegate];
    NSManagedObjectContext * context = appDelegate.managedObjectContext;
    
    M3Synchronization * syncEntity = [[M3Synchronization alloc] initForClass: @"Car"
                                                                  andContext: context
                                                                andServerUrl: kWebsiteUrl
                                                 andServerReceiverScriptName: kServerReceiverScript
                                                  andServerFetcherScriptName: kServerFetcherScript
                                                        ansSyncedTableFields:@[@"licenceNumber", @"manufacturer", @"model"]
                                                        andUniqueTableFields:@[@"licenceNumber"]];
    

    
    
    syncEntity.delegate = self;
    syncEntity.additionalPostParamsDictionary = [NSMutableDictionary dictionary];
    [syncEntity.additionalPostParamsDictionary setObject:[[NSUserDefaults standardUserDefaults] stringForKey:@"userDeviceId"] forKey:@"userDeviceId"];
    [syncEntity.additionalPostParamsDictionary setObject:[[NSUserDefaults standardUserDefaults] stringForKey:@"secureCode"] forKey:@"secureCode"];
    
    
    
    [syncEntity sync];
}

-(void) onSynchronizationComplete:(id)entity {
    [self refreshData];
    NSLog(@"Sync Complete");

}
-(void) onSynchronizationError:(id)entity {
    NSLog(@"Sync error");
}






@end
