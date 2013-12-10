//
//  SynchronizationManager.m
//  travelExpenses
//
//  Created by Klemen Nagode on 1/29/13.
//  Copyright (c) 2013 Mice3. All rights reserved.
//

#import "M3SerialSync.h"
#import "M3Synchronization.h"


@interface M3SerialSync()<M3SynchronizationEventHandler> {}

@property (nonatomic) int countItemsToSync;
@property (nonatomic) int countModifiedItemsFromServer;
@property (nonatomic) int currentSyncIndex;



@property (nonatomic, strong) NSMutableArray * itemsToSync; // Array of entities which should be synced -> we sycn entities one by one
@property (nonatomic, strong) NSMutableArray * itemsToSyncAll; // one


@property (nonatomic, copy) NSString * activeEntityName;


@end


@implementation M3SerialSync

static BOOL isSyncing = NO;



-(id) initWithStringArray: (NSArray *) entityNames;
{
    if(self = [super init]) {
        //self.synchingTablesDictionary = [[NSMutableDictionary alloc] initWithCapacity:5];
        self.itemsToSync = [[NSMutableArray alloc] initWithCapacity:5];
        
        self.itemsToSyncAll = [[NSMutableArray alloc] initWithCapacity:5];
        
        
        for (NSString * name in entityNames) {
            [self.itemsToSyncAll addObject:[[M3Synchronization alloc] initForClassFromJsonConfiguration:name]];
        }
        
        
    }
    return self;
}





-(void) synchronizeNext
{
    
    if ([self.itemsToSync count]) {
        M3Synchronization * syncEntity = [self.itemsToSync objectAtIndex:0];
        [self.itemsToSync removeObjectAtIndex:0];
        
        [syncEntity sync];
    } else {
        NSLog(@"WARNING: synchronizeNext should not be called if array is empty");
    }
    
}



-(void) sync
{
    if (isSyncing) {
        if (self.delegate) {
            [self.delegate onSerialSyncError:nil];
        }

        return;
    }
    [self.itemsToSyncAll removeAllObjects];
    
    self.countItemsToSync = 0;
    self.countModifiedItemsFromServer = 0;
    
    
    
    for (M3Synchronization * syncEntity in self.itemsToSyncAll) {
        [self.itemsToSync addObject: syncEntity];
    }

    [self synchronizeNext];
    
}





-(void) onSynchronizationComplete:(id)entity {

    M3Synchronization * syncEntity = (M3Synchronization *) entity;

    NSLog(@"SynchronizationComplete===>%@", syncEntity.className);
    
    self.countItemsToSync += syncEntity.countItemsToSync;
    self.countModifiedItemsFromServer += syncEntity.countModifiedItemsFromServer;
    

    
    if ([self.itemsToSync count]) {
        [self synchronizeNext];
    } else {
        
        isSyncing = NO;
        if (self.delegate && [self.delegate respondsToSelector:@selector(onSynchronizationComplete)]) {
            [self.delegate onSerialSyncComplete];
        }
    
    }
}

-(void) onSerialSyncError:(id)entity {
    //[[NSNotificationCenter defaultCenter] postNotificationName:kSynchronizationError object:nil];
    isSyncing = NO;
//    SynchronizationEntity * e = (SynchronizationEntity *) entity;
//    NSLog(@"entity ERROR: %@", e.className);

    if(self.delegate && [self.delegate respondsToSelector:@selector(onSynchronizationError:)]) {
        [self.delegate onSerialSyncError:nil];
    }
}




//-(void) showSyncError: (NSString *) error {
//    UIAlertView *alert = [[UIAlertView alloc]initWithTitle: NSLocalizedString(@"SyncError", nil)
//                                                   message: error
//                                                  delegate: nil
//                                         cancelButtonTitle: NSLocalizedString(@"Ok", nil)
//                                         otherButtonTitles:nil];
//    
//    [alert show];
//    isSyncing = NO;
//    [self.itemsToSync removeAllObjects];
//
//
//}
//
//-(void) showSyncFinishAlert
//{
//    UIAlertView *alert = [[UIAlertView alloc]initWithTitle: NSLocalizedString(@"Synchronize", nil)
//                                                   message: [NSString stringWithFormat:NSLocalizedString(@"SyncCompleted", nil), self.countModifiedItemsFromServer, self.countItemsToSync]
//                                                  delegate: nil
//                                         cancelButtonTitle: NSLocalizedString(@"Ok", nil)
//                                         otherButtonTitles:nil];
//    
//    
//    [alert show];
//    
//    isSyncing = NO;
//}

//-(void) updateServerDatetime: (NSDate *) date
//{
//    [[NSUserDefaults standardUserDefaults] setObject:date forKey:@"lastDatetimeFromServer"];
//}


//-(NSDate *) lastSyncWithServerDatetime
//{
//    NSDate * lastDate = [[NSUserDefaults standardUserDefaults] objectForKey:@"lastDatetimeFromServer"];
//    
//    BOOL isActivated = [[NSUserDefaults standardUserDefaults] boolForKey:@"isActivated"];
//    
//    if(!isActivated) {
//        return nil;
//    }
//    
//    return lastDate;
//}
//
//- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
//{
//    
//}


//-(BOOL) synchronizeIfAllowed
//{
//    BOOL syncOnCellural = [SyncedRepository getBool:kSyncedRepositoryEnableSyncOnCellularKey defaultValue:kSyncedRepositoryEnableSyncOnCellularValue];
//    
//    if (syncOnCellural || [UIDevice wiFiConnected]) {
//        [self synchronize];
//        return YES;
//    }
//
//    if (self.delegate) {
//        if ([self.delegate respondsToSelector:@selector(onSynchronizationClickToSync)]) {
//            [self.delegate onSynchronizationClickToSync];
//        }
//    }
//    return NO;
//}

//+(void) displayDeviceActivationWindow: (UIViewController *) view {
//    
//    UIStoryboard *sboard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPhone" bundle:nil];
//    UINavigationController * navigationController = [sboard instantiateViewControllerWithIdentifier:@"DeviceActivateNavigationController"];
//    
//    //[[SynchronizationManager sharedManager] setDelegate:navigationController];
//    
//    [view presentViewController:navigationController animated:YES completion:nil];
//}

-(void) dealloc
{
    NSLog(@"SynchronizationManager was deallocated");
}



@end
