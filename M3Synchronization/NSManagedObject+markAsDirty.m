//
//  NSManagedObject+markAsDirty.m
//  travelExpenses
//
//  Created by Klemen Nagode on 4/30/13.
//  Copyright (c) 2013 Mice3. All rights reserved.
//

#import "NSManagedObject+markAsDirty.h"

@implementation NSManagedObject (markAsDirty)


-(void) markAsDirty
{
    NSDate *date = [NSDate date];
    NSTimeInterval ti = [date timeIntervalSince1970];
    [self setValue:[NSNumber numberWithBool:YES] forKey:@"isDirty"];
    [self setValue:[NSNumber numberWithInt:(int) ti] forKey:@"timestampModified"];
}
-(void) markAsJustInserted
{
    [self setValue:[NSNumber numberWithBool:NO] forKey:@"is_Deleted"];
    [self markAsDirty];
    [self setValue:[self valueForKey:@"timestampModified"] forKey:@"timestampInserted"];
}
-(void) markAsDeleted
{
    [self setValue:[NSNumber numberWithBool:YES] forKey:@"is_Deleted"];
    [self markAsDirty];
}

@end
