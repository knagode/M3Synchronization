//
//  Car.h
//  M3Synchronization
//
//  Created by Klemen Nagode on 8/20/13.
//  Copyright (c) 2013 Mice3. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Car : NSManagedObject

@property (nonatomic, retain) NSNumber * is_Deleted;
@property (nonatomic, retain) NSNumber * isDirty;
@property (nonatomic, retain) NSString * licenceNumber;
@property (nonatomic, retain) NSString * manufacturer;
@property (nonatomic, retain) NSString * model;
@property (nonatomic, retain) NSNumber * remoteId;
@property (nonatomic, retain) NSNumber * timestampInserted;
@property (nonatomic, retain) NSNumber * timestampModified;

@end
