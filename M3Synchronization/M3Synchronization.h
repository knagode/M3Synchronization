//
//  SynchronizationEntity.h
//  travelExpenses
//
//  Created by Klemen Nagode on 3/4/13.
//  Copyright (c) 2013 Mice3. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSManagedObject+markAsDirty.h"

@protocol SynchronizationEntityEventHandler <NSObject>

-(void) onSynchronizationComplete: (id) entity;
-(void) onSynchronizationError: (id) entity;

@end


@interface M3Synchronization : NSObject

//@property (nonatomic, strong) NSDictionary * classSettings;
@property (nonatomic, copy) NSString * className;
@property (nonatomic, strong) id<SynchronizationEntityEventHandler> delegate; // Important: if delegate is set we want to make shure that delegate stays in the memory until onComplete/error methods are called. In other case it could easily happen that onComplete is never called

@property (nonatomic) int countItemsToSync;
@property (nonatomic) int countModifiedItemsFromServer;
@property (nonatomic, copy) NSString *clientNewDataPredicate;
@property (nonatomic) BOOL syncToServerOnly;
@property (nonatomic) BOOL outputCommunicationContentToConsole;
@property (nonatomic) BOOL showAlertWithErrorDescriptionOnErrorDetected;

@property (nonatomic, strong) NSMutableDictionary * additionalPostParamsDictionary;

// please note that json file should omit .json extension
-(id)               initForClass: (NSString *) className
                      andContext: (NSManagedObjectContext *) context
                    andServerUrl: (NSString *) serverUrl
     andServerReceiverScriptName: (NSString *) serverReceiverScript
      andServerFetcherScriptName: (NSString *) serverFetcherScript
            ansSyncedTableFields: (NSArray *) syncedTableFields
            andUniqueTableFields: (NSArray *) uniqueTableFields;


-(void) sync;
-(void) getModifiedDataFromServer;
-(void) sendNewDataToServer;

/* if you want to attach multipart data, use this method */
-(void) addMultipartData: (NSData *) data
                 andName: (NSString *) name
             andFileName: (NSString *) fileName
             andMimeType: (NSString *) mimeType;


@end
