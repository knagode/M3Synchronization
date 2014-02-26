//
//  AppDelegate.m
//  M3SynchronizationExample
//
//  Created by Klemen Nagode on 8/21/13.
//  Copyright (c) 2013 Mice3. All rights reserved.
//

#import "AppDelegate.h"
#import "Constants.h"

@implementation AppDelegate

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    
    /* clear database first */
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Car" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    NSError *error;
    NSArray *items = [_managedObjectContext executeFetchRequest:fetchRequest error:&error];
    
    
    for (NSManagedObject *managedObject in items) {
    	[_managedObjectContext deleteObject:managedObject];
    }
    if (![_managedObjectContext save:&error]) {
    	// display error?
    }
    
    /* we will store some test data on our server */
    
    /* we manually create user with unique email + userDevice entity first */
    NSDictionary * response = [self syncedRequest:[NSString stringWithFormat:@"%@/mobile_scripts/createDevice.php", kWebsiteUrl] andPostData:[NSMutableDictionary dictionaryWithObjectsAndKeys: [NSString stringWithFormat:@"%f-example@mice3.it", [[NSDate date] timeIntervalSince1970]], @"email", nil]];
    
    /* we save user authentication params in userDefaults to access it later */
    [[NSUserDefaults standardUserDefaults] setValue:[response objectForKey:@"userDeviceId"] forKey:@"userDeviceId"];
    [[NSUserDefaults standardUserDefaults] setValue:[response objectForKey:@"secureCode"] forKey:@"secureCode"];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"isActivated"]; // todo remove - this should not be part of our library
    
    /* show alert with server URL viewer/editor */
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle: @"User Created" message: [NSString stringWithFormat:@"Use this URL to view/edit online version of data: %@/cars.php?userDeviceId=%@ \n (URL was generated for this test run. We generate data inside [AppDelegate application] method)", kWebsiteUrl, [response objectForKey:@"userDeviceId"]] delegate: nil cancelButtonTitle: @"Ok" otherButtonTitles: nil];
    [alert show];
    
    
    /* After creation of device with email - user has to activate email link - we will activate it manually */
    [self syncedRequest:[NSString stringWithFormat:@"%@/mobile_scripts/unitTests/activateUserDevice.php", kWebsiteUrl] andPostData:[NSMutableDictionary dictionaryWithDictionary:response]];
    
    /* We request first car creation on server */
    [self syncedRequest:[NSString stringWithFormat:@"%@/mobile_scripts/unitTests/insertNewCar.php", kWebsiteUrl] andPostData:[NSMutableDictionary dictionaryWithDictionary:response]];
    
    
    return YES;
}

-(id) syncedRequest: (NSString *) stringUrl andPostData: (NSMutableDictionary *) post
{
    NSURL *url = [NSURL URLWithString:stringUrl];
    
    NSMutableURLRequest *request = [[ NSMutableURLRequest alloc ] initWithURL: url];
    
    
    if(post) {
        NSString * postString = @"";
        
        NSArray * keys = [post allKeys];
        for (int i = 0; i < [keys count]; i++) {
            if(i>0) {
                postString = [postString stringByAppendingString:@"&"];
            }
            
            postString = [postString stringByAppendingFormat:@"%@=%@", [keys objectAtIndex:i], [post objectForKey:[keys objectAtIndex:i]]];
        }
        
        NSData *myRequestData = [NSData dataWithBytes: [ postString UTF8String ] length: [ postString length ] ];
        [request setHTTPMethod: @"POST"];
        [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"content-type"];
        [request setHTTPBody: myRequestData];
    }
    
    
    
    NSURLResponse *response;
    NSError *err;
    NSData *returnData = [ NSURLConnection sendSynchronousRequest: request returningResponse:&response error:&err];
    NSString *content = [[NSString alloc] initWithData:returnData encoding:NSUTF8StringEncoding];
    NSLog(@"responseData: %@", content);
    
    NSError *e = nil;
    
    id JSON = [NSJSONSerialization JSONObjectWithData: [content dataUsingEncoding:NSUTF8StringEncoding]
                                              options: NSJSONReadingMutableContainers
                                                error: &e];
    
    if(e) {
        NSLog(@"%@", e.description);
    }
    
    return JSON;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Saves changes in the application's managed object context before the application terminates.
    [self saveContext];
}

- (void)saveContext
{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
             // Replace this implementation with code to handle the error appropriately.
             // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        } 
    }
}

#pragma mark - Core Data stack

// Returns the managed object context for the application.
// If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] init];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
        
        // subscribe to change notifications
        // If we work with multiple contexts: https://www.cocoanetics.com/2012/07/multi-context-coredata/
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_mocDidSaveNotification:) name:NSManagedObjectContextDidSaveNotification object:nil];
    }
    return _managedObjectContext;
}
- (void)_mocDidSaveNotification:(NSNotification *)notification
{
    NSManagedObjectContext *savedContext = [notification object];
    
    // ignore change notifications for the main MOC
    if (_managedObjectContext == savedContext)
    {
        return;
    }
    
    if (_managedObjectContext.persistentStoreCoordinator != savedContext.persistentStoreCoordinator)
    {
        // that's another database
        return;
    }
    
    dispatch_sync(dispatch_get_main_queue(), ^{
        [_managedObjectContext mergeChangesFromContextDidSaveNotification:notification];
    });
}

// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Database" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's store added to it.
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"Database.sqlite"];
    
    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
         
         Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.
         
         
         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
         
         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
         
         * Performing automatic lightweight migration by passing the following dictionary as the options parameter:
         @{NSMigratePersistentStoresAutomaticallyOption:@YES, NSInferMappingModelAutomaticallyOption:@YES}
         
         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
         
         */
        
        
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }    
    
    return _persistentStoreCoordinator;
}

#pragma mark - Application's Documents directory

// Returns the URL to the application's Documents directory.
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

@end
