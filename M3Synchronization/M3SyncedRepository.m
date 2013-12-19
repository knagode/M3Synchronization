//
//  SyncedRepository.m
//  travelExpenses
//
//  Created by Marko Jurincic on 4/16/13.
//  Copyright (c) 2013 Mice3. All rights reserved.
//

#import "M3SyncedRepository.h"
#import "RepositoryItem.h"
#import "AppDelegate.h"
#import "NSManagedObject+markAsDirty.h"
#import "M3Synchronization.h"

@implementation M3SyncedRepository

+(RepositoryItem *) getRepositoryItemForKey:(NSString *) key
{
    NSPredicate *selectItemPredicate = [NSPredicate predicateWithFormat:@"uniqueKey == %@",key];
    
    return [RepositoryItem findFirstWithPredicate:selectItemPredicate];
}

+(NSString *) getRepositoryItemValueForKey:(NSString *) key
{
    RepositoryItem * repositoryItem = [self getRepositoryItemForKey:key];
    if (repositoryItem) {
        NSLog(@"%@", key);
        NSLog(@"repository item %@ = %@", key, repositoryItem.value);
        return repositoryItem.value;
    }
    return nil;
}

+(NSString *) getString:(NSString *) key defaultValue:(NSString *) defaultValue {
    NSString * valueForKey =  [self getRepositoryItemValueForKey:key];
    
    if(valueForKey != nil) {
        return valueForKey;
    }
    return defaultValue;
}

+(BOOL) getBool:(NSString *) key defaultValue:(BOOL) defaultValue {
    NSString * valueForKey = [self getRepositoryItemValueForKey:key];
    if(valueForKey != nil) {
        if([valueForKey isEqualToString:@"1"] || [valueForKey isEqualToString:@"YES"]) {
            return YES;
        } else {
            return NO;
        }
    }
    
    return defaultValue;
}

+(double) getDouble:(NSString *) key defaultValue:(double) defaultValue {
    NSString * valueForKey = [self getRepositoryItemValueForKey:key];
    
    if(valueForKey != nil) {
        return [valueForKey doubleValue];
    }
    
    return defaultValue;
}

+(NSDate *) getDate:(NSString *) key defaultValue:(NSDate *) defaultValue {
    NSString * valueForKey = [self getRepositoryItemValueForKey:key];
    
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"yyyy-MM-dd"];
    
    if(valueForKey != nil) {
        return [dateFormat dateFromString:valueForKey];
    }
    
    return defaultValue;
}
+(NSDate *) getDatetime:(NSString *) key defaultValue:(NSDate *) defaultValue {
    NSString * valueForKey = [self getRepositoryItemValueForKey:key];
    
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"yyyy-MM-dd hh:mm:s"];
    
    if(valueForKey != nil) {
        return [dateFormat dateFromString:valueForKey];
    }
    
    return defaultValue;
}

+(int) getInt:(NSString *) key defaultValue:(int) defaultValue {
    
    NSString * valueForKey = [self getRepositoryItemValueForKey:key];
    
    if(valueForKey != nil) {
        return [valueForKey intValue];
    }
    
    return defaultValue;
}

+(void) setDatetime:(NSDate *) value forKey:(NSString *) key {

    NSCalendar *calendar = [NSCalendar currentCalendar];

    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd hh:mm:s"];
    
    [M3SyncedRepository setString:[dateFormatter stringFromDate:value] forKey:key];
}
+(void) setDate:(NSDate *) value forKey:(NSString *) key {
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd"];
    
    NSLog(@"store to db %@ original: %@", [dateFormatter stringFromDate:value], value );
    
    [M3SyncedRepository setString:[dateFormatter stringFromDate:value] forKey:key];
}

+(void) setBOOL:(BOOL) value forKey:(NSString *) key {
    [M3SyncedRepository setString:(value) ? @"1" : @"0" forKey:key];
}

+(void) setDouble:(double) value forKey:(NSString *) key {
    [M3SyncedRepository setString:[NSString stringWithFormat:@"%f",value] forKey:key];
}

+(void) setInt:(int) value forKey:(NSString *) key {
    [M3SyncedRepository setString:[NSString stringWithFormat:@"%i",value] forKey:key];
}

+(void) setString:(NSString *) value forKey:(NSString *) key {
    
    BOOL valueIsChanged = YES;
    BOOL userDefaultsAlreadyExists = NO;
    
    RepositoryItem * repositoryItem = [self getRepositoryItemForKey:key];
    
    if(repositoryItem) {
        NSLog(@"Repository item %@",repositoryItem.value);
        if([repositoryItem.value isEqualToString:value]) {
            valueIsChanged = NO;
        } else {
            repositoryItem.value = value;
            [repositoryItem markAsDirty];
        }
        
        userDefaultsAlreadyExists = YES;
    }
    
    if(!userDefaultsAlreadyExists) {
        RepositoryItem * repositoryItem = [RepositoryItem createEntity];
        repositoryItem.uniqueKey = key;
        repositoryItem.value = value;
        [repositoryItem markAsJustInserted];
    }
    
    if(valueIsChanged) {
        [AppDelegate saveContext];
        
        [[[M3Synchronization alloc] initForClassFromJsonConfiguration:@"RepositoryItem"] sync]; // SyncConfiguration.json should exist
    }
    
    
}


@end
