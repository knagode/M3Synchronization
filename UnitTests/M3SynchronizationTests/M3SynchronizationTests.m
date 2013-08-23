//
//  M3SynchronizationTests.m
//  M3SynchronizationTests
//
//  Created by Klemen Nagode on 8/20/13.
//  Copyright (c) 2013 Mice3. All rights reserved.
//

#import "M3SynchronizationTests.h"
#import "M3Synchronization.h"
#import "Car.h"

/* constants */ // TODO: everything should be renamet to save/get - it will be much more logical
#define kUnitTestsWebsiteUrl @"http://synctest.talcho.com/"
#define kUnitTestServerReceiverScript @"/mobile_scripts/syncDynamic.php?class=%@"
#define kUnitTestServerFetcherScript @"/mobile_scripts/getLastChangesDynamic.php?class=%@"


@interface M3SynchronizationTests(){}

@property (nonatomic) int  userDeviceId;
@property (nonatomic, copy) NSString * secureCode;
@property (nonatomic, strong) NSManagedObjectContext * context;
@property (nonatomic) BOOL asynchronousCallIsCompleted;

@end


@implementation M3SynchronizationTests



- (void)setUp
{
    [super setUp];
    
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    
    
    NSURL *url = [bundle URLForResource:@"Database" withExtension:@"momd"];
    
    NSManagedObjectContext *moc = [[NSManagedObjectContext alloc] init];
    self.context = moc;
    
    NSManagedObjectModel * mom =  [[NSManagedObjectModel alloc] initWithContentsOfURL:url]; //[NSManagedObjectModel mergedModelFromBundles: nil];
    if(!mom) {
        assert(@"momd file not found ... Make shure that file exists and it is added to copile sources on test target");
    }
    
    NSPersistentStoreCoordinator *psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:mom];
    
    
    [psc addPersistentStoreWithType:NSInMemoryStoreType configuration:nil URL:nil options:nil error:NULL];
    
    [moc setPersistentStoreCoordinator:psc];
    
    
    NSDictionary * response = [self syncedRequest:[NSString stringWithFormat:@"%@mobile_scripts/unitTests/truncateDatabase.php", kUnitTestsWebsiteUrl] andPostData:[NSDictionary dictionaryWithObjectsAndKeys:@"testgmailcom", @"email", nil]];

    
    response = [self syncedRequest:[NSString stringWithFormat:@"%@mobile_scripts/createDevice.php", kUnitTestsWebsiteUrl] andPostData:[NSDictionary dictionaryWithObjectsAndKeys:@"testgmailcom", @"email", nil]];
    
    self.userDeviceId = [[response objectForKey:@"userDeviceId"] intValue];
    self.secureCode = [response objectForKey:@"secureCode"];
    
    
    
    response = [self syncedRequest:[NSString stringWithFormat:@"%@mobile_scripts/unitTests/activateUserDevice.php", kUnitTestsWebsiteUrl] andPostData:[self getUserDevicePostDictionary]];
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}


/* supporting methods for testing */


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
        STFail([NSString stringWithFormat:@"JSON error for url %@. Server response: %@. \nJSON error: %@ %@", stringUrl, content, e.description, e.debugDescription]);
    }
    
    return JSON;
}

-(NSMutableDictionary *) getUserDevicePostDictionary
{
    return [NSMutableDictionary dictionaryWithObjectsAndKeys:self.secureCode, @"secureCode", [NSNumber numberWithInt:self.userDeviceId ], @"userDeviceId", nil];
}

-(NSArray *) getAllCars
{
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription * entity = [NSEntityDescription entityForName:@"Car" inManagedObjectContext:self.context];
    [request setEntity:entity];
    
    return [self.context executeFetchRequest:request error:nil];
}

-(void) synchronousSyncWithEntity: (M3Synchronization *) syncEntity
{
    self.asynchronousCallIsCompleted = NO;
    [syncEntity sync];
    while(!self.asynchronousCallIsCompleted) {
        NSDate *oneSecond = [NSDate dateWithTimeIntervalSinceNow:1];
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:oneSecond];
    }
}

// get car with max remoteId
-(Car *) getLastInsertedCarOnServer{
    NSArray * cars = [self getAllCars];
    Car * lastCar = [cars objectAtIndex:0];
    for (Car * car in cars) {
        if (car.remoteId.intValue > lastCar.remoteId.intValue) {
            lastCar = car;
        }
    }
    return lastCar;
}

-(NSArray *) getAllRemoteCars
{
    NSArray * cars = [self syncedRequest:[NSString stringWithFormat:@"%@mobile_scripts/unitTests/getAllCars.php", kUnitTestsWebsiteUrl] andPostData:[self getUserDevicePostDictionary]];
    
    return cars;
}

-(void) testSendFile {
    STFail(@"Test fail?");
}


-(void) testTimezones {
    
    NSDictionary * response = [self syncedRequest:[NSString stringWithFormat:@"%@mobile_scripts/unitTests/testTimezone.php", kUnitTestsWebsiteUrl] andPostData:nil];
    
    int serverTime = [[response valueForKey:@"gmmktime"] intValue];
    
    NSDate *date = [NSDate date];
    int clientTime = [date timeIntervalSince1970];
    int diff = abs(clientTime - serverTime);
    
    STAssertTrue(diff < 20 , [NSString stringWithFormat:@"time stamps are not equal. Diff: %d", serverTime-clientTime]);
    
    
}



-(void) testSimpleSyncWithUniqueFieldsDetectionOnServerAndClient
{
    // TODO: check if server has correct UTC timezone? DO WE NEED TO HAVE THIS? NOOOO!
    
    
    // try to send two same cars to the server (that could happen if connection is interupted)
    for(int i=0; i<2; i++){
        Car * car = [NSEntityDescription insertNewObjectForEntityForName:@"Car" inManagedObjectContext:self.context];
        car.licenceNumber = @"SV-FIRST-v1";
        car.manufacturer = @"Audi";
        car.model = @"A6";
        
        if(![car respondsToSelector:@selector(markAsJustInserted)]) {
            STFail(@"You have to add NSManagedObject+markAdDirty.m to project->targets->Test target->compile Sources");
        }
        [car markAsJustInserted];
        
        
        [self.context save:nil];
        
        
        //[AppDelegate saveContext];
    }
    
    
    // before syncing there should be two cars in repository (duplicates will be removed upon sync)
    NSArray * localCars = [self getAllCars];
    STAssertEquals([localCars count], (NSUInteger) 2, @"Two car should be inserted");
    
    // check if isDirty field and datetimeModified and datetimeInserted was properly set
    for(Car * car in localCars) {
        STAssertEquals(car.isDirty.boolValue, YES, @"Is dirty field must be set on new inserted data!");
    }
    
    
    
    M3Synchronization * syncEntity = [[M3Synchronization alloc] initForClass: @"Car"
                                                                  andContext: self.context
                                                                andServerUrl: kUnitTestsWebsiteUrl
                                                 andServerReceiverScriptName: kUnitTestServerReceiverScript
                                                  andServerFetcherScriptName: kUnitTestServerFetcherScript
                                                        ansSyncedTableFields:@[@"licenceNumber", @"manufacturer", @"model"]
                                                        andUniqueTableFields:@[@"licenceNumber"]];
    syncEntity.delegate = self;
    syncEntity.additionalPostParamsDictionary = [self getUserDevicePostDictionary];
    
    
    [self synchronousSyncWithEntity: syncEntity];
    
    // after sync is completed - duplicates should be removed
    localCars = [self getAllCars];
    STAssertEquals([localCars count], (NSUInteger) 1, @"One car should be inserted");
    
    
    NSArray * remoteCars = [self getAllRemoteCars];
    
    STAssertEquals([remoteCars count], (NSUInteger) 1, @"One car should be online");
    
    // check if local cars have received remoteId
    for(Car * car in localCars) {
        STAssertTrue(car.remoteId.intValue > 0, @"Car should receive remoteId from server");
    }
    
    // check if we will receive new data from server
    // insert new car on server
    sleep(1); // wait at least on second - we download changes which have timestamp newer than last sync timestamp (there must be one second between two syncs)
    
    [self syncedRequest:[NSString stringWithFormat:@"%@mobile_scripts/unitTests/insertNewCar.php", kUnitTestsWebsiteUrl] andPostData:[self getUserDevicePostDictionary]];
    
    [self synchronousSyncWithEntity:syncEntity];
    // check if we did receive new car
    localCars = [self getAllCars];
    STAssertEquals([localCars count], (NSUInteger) 2, @"New car should be transfered from server");
    
    // check what happens if we change data on client
    // change first licenceNumber
    Car * car = (Car *)[localCars objectAtIndex:0];
    car.licenceNumber = @"SV-FIRST-v2";
    [car markAsDirty];
    
    [self.context save:nil];
    
    // check if dirty fields was set
    localCars = [self getAllCars];
    for(Car * car in localCars) {
        NSLog(@"licence=%@ isDirty=%@", car.licenceNumber, car.isDirty);
    }
    
    [self synchronousSyncWithEntity:syncEntity];
    
    NSDictionary * response = [self syncedRequest:[NSString stringWithFormat:@"%@mobile_scripts/unitTests/checkIfCarExists.php?licenceNumber=%@", kUnitTestsWebsiteUrl, car.licenceNumber] andPostData:[self getUserDevicePostDictionary]];
    STAssertTrue([[response objectForKey:@"exists"] boolValue], @"Modifications should now be online");
    
    
    
    
    // check what happens if we change data on server
    sleep(1); // if we do not wait we will not received modified data
    [self syncedRequest:[NSString stringWithFormat:@"%@mobile_scripts/unitTests/changeLastInsertedCar.php?licenceNumber=%@", kUnitTestsWebsiteUrl, @"SV-SECOND-v2"] andPostData:[self getUserDevicePostDictionary]];
    [self synchronousSyncWithEntity:syncEntity];
    // now we check if at least one car has been changed
    localCars = [self getAllCars];
    BOOL isChangeDetected = NO;
    for (Car * car in localCars) {
        if ([car.licenceNumber isEqualToString:@"SV-SECOND-v2"]) {
            isChangeDetected = YES;
        }
    }
    STAssertTrue(isChangeDetected, @"Changed entity from server was not received");
    
    
    // check if we change data on server and client. Will newer entry be used? Merge works?
    // check if client version should be used
    sleep(1); // if we do not wait we will not received modified data
    [self syncedRequest:[NSString stringWithFormat:@"%@mobile_scripts/unitTests/changeLastInsertedCar.php?licenceNumber=%@", kUnitTestsWebsiteUrl, @"SV-SECOND-v3"] andPostData:[self getUserDevicePostDictionary]];
    [self synchronousSyncWithEntity:syncEntity]; // TODO: shouldnt we not do this?
    
    car = [self getLastInsertedCarOnServer];
    car.licenceNumber = @"SV-SECOND-v4";
    [car markAsDirty];
    car.timestampModified = [NSNumber numberWithInt:(int)[[[NSDate date] dateByAddingTimeInterval:100] timeIntervalSince1970]];
    
    
    [self.context save:nil];
    
    [self synchronousSyncWithEntity:syncEntity];
    
    remoteCars = [self getAllRemoteCars];
    NSDictionary * lastCarRemote = (NSDictionary *)[remoteCars objectAtIndex:1];
    car = [self getLastInsertedCarOnServer];
    
    if (![car.licenceNumber isEqualToString:@"SV-SECOND-v4"]) {
        STFail([NSString stringWithFormat:@"Local value is not correct: %@", car.licenceNumber]);
    }
    if (![[lastCarRemote valueForKey:@"licenceNumber"] isEqualToString:@"SV-SECOND-v4"]) {
        STFail([NSString stringWithFormat:@"Remote value is not correct: %@", [lastCarRemote valueForKey:@"licenceNumber"]]);
    }
    
    
    // check if server version should be used
    sleep(1); // if we do not wait we will not received modified data
    car = [self getLastInsertedCarOnServer];
    car.licenceNumber = @"SV-SECOND-v5";
    [car markAsDirty]; // this also reset datetimeModified from last time (which was set tu future time)
    
    [self.context save:nil];
    
    [self syncedRequest:[NSString stringWithFormat:@"%@mobile_scripts/unitTests/changeLastInsertedCar.php?licenceNumber=%@&setModifiedInFuture=1", kUnitTestsWebsiteUrl, @"SV-SECOND-v6"] andPostData:[self getUserDevicePostDictionary]];
    [self synchronousSyncWithEntity:syncEntity];
    
    remoteCars = [self getAllRemoteCars];
    lastCarRemote = (NSDictionary *)[remoteCars objectAtIndex:1];
    car = [self getLastInsertedCarOnServer];
    
    if (![car.licenceNumber isEqualToString:@"SV-SECOND-v6"]) {
        STFail([NSString stringWithFormat:@"Local value is not correct: %@", car.licenceNumber]);
    }
    if (![[lastCarRemote valueForKey:@"licenceNumber"] isEqualToString:@"SV-SECOND-v6"]) {
        STFail([NSString stringWithFormat:@"Remote value is not correct: %@", [lastCarRemote valueForKey:@"licenceNumber"]]);
    }
    
    
    // check if deletition works (isDeleted=1)
    
    // check if triggers work as expected
    
    // check locking (what happens if two devices try to modifie same data
    
}

-(void) onSynchronizationComplete:(id)entity {
    self.asynchronousCallIsCompleted = YES;
}

-(void) onSynchronizationError:(id)entity {
    
    M3Synchronization * ent = (M3Synchronization *) entity;
    
    self.asynchronousCallIsCompleted = YES;
    STFail(@"Synshronization error should not pop out! %@", ent);
}



@end
