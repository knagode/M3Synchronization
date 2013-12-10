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
    AppDelegate * appdelegate = [[UIApplication sharedApplication] delegate];
    NSManagedObjectContext * context = [appdelegate managedObjectContext];
    NSError * error;
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription * entity = [NSEntityDescription entityForName:@"RepositoryItem" inManagedObjectContext:context];
    [request setEntity:entity];
    
    NSPredicate *selectItemPredicate = [NSPredicate predicateWithFormat:@"uniqueKey == %@",key];
    [request setPredicate:selectItemPredicate];
    
    NSArray * array = [context executeFetchRequest:request error:&error];
    
    if([array count]>0) {
        return [array objectAtIndex:0];
    }
    
    return nil;
}
+(NSString *) getRepositoryItemValueForKey:(NSString *) key
{
    RepositoryItem * repositoryItem = [self getRepositoryItemForKey:key];
    if (repositoryItem) {
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
    [dateFormat setDateFormat:@"Y-d-m H:i:s"];
    
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

+(void) setDate:(NSDate *) value forKey:(NSString *) key {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"Y-d-m H:i:s"];
    
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
    
    
    AppDelegate * appdelegate = [[UIApplication sharedApplication] delegate];
    NSManagedObjectContext * context = [appdelegate managedObjectContext];

    
    if(!userDefaultsAlreadyExists) {
        
        RepositoryItem * repositoryItem = [NSEntityDescription insertNewObjectForEntityForName:@"RepositoryItem" inManagedObjectContext:context];
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
