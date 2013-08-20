//
//  NSManagedObject+markAsDirty.h
//  travelExpenses
//
//  Created by Klemen Nagode on 4/30/13.
//  Copyright (c) 2013 Mice3. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface NSManagedObject (markAsDirty)


-(void) markAsDirty;
-(void) markAsJustInserted;
-(void) markAsDeleted;


@end
