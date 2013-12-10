//
//  RepositoryItem.h
//  travelExpenses
//
//  Created by Klemen Nagode on 5/3/13.
//  Copyright (c) 2013 Mice3. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface RepositoryItem : NSManagedObject

@property (nonatomic, retain) NSNumber * timestampInserted;
@property (nonatomic, retain) NSNumber * timestampModified;
@property (nonatomic, retain) NSNumber * is_Deleted;
@property (nonatomic, retain) NSNumber * isDirty;
@property (nonatomic, retain) NSNumber * remoteId;
@property (nonatomic, retain) NSString * uniqueKey;
@property (nonatomic, retain) NSString * value;

@end
