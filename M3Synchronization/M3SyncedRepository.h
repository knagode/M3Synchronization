//
//  SyncedRepository.h
//  travelExpenses
//
//  Created by Marko Jurincic on 4/16/13.
//  Copyright (c) 2013 Mice3. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface M3SyncedRepository : NSObject

+(NSString *) getString:(NSString *) key defaultValue:(NSString *) defaultValue;
+(BOOL) getBool:(NSString *) key defaultValue:(BOOL) defaultValue;
+(double) getDouble:(NSString *) key defaultValue:(double) defaultValue;
+(NSDate *) getDate:(NSString *) key defaultValue:(NSDate *) defaultValue;
+(int) getInt:(NSString *) key defaultValue:(int) defaultValue;

+(void) setDate:(NSDate *) value forKey:(NSString *) key;
+(void) setBOOL:(BOOL) value forKey:(NSString *) key;
+(void) setDouble:(double) value forKey:(NSString *) key;
+(void) setString:(NSString *) value forKey:(NSString *) key;
+(void) setInt:(int) value forKey:(NSString *) key;

@end
