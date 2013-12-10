//
//
//  Created by Klemen Nagode on 1/29/13.
//  Copyright (c) 2013 Mice3. All rights reserved.
//  Specification & protocol: http://goo.gl/KFGXj
//

#define kSynchronizationError @"syncError"


#import <Foundation/Foundation.h>
#import "M3Synchronization.h"


@protocol M3SerialSyncEventHandler <NSObject>

@optional
-(void) onSerialSyncComplete;
//-(void) onSynchronizationStart;
-(void) onSerialSyncError: (id) entity;

@end


@interface M3SerialSync : NSObject


@property (nonatomic, weak) id<M3SerialSyncEventHandler> delegate;
//@property (nonatomic, weak) ViewRoutesTableController * routeGroupsTableViewController;
@property (nonatomic, strong) NSMutableDictionary *synchingTablesDictionary;



-(id) initWithStringArray: (NSArray *) entitieNames;

-(void) sync;



@end
