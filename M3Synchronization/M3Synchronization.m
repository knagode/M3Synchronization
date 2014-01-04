    //
//  SynchronizationEntity.m
//  travelExpenses
//
//  Created by Klemen Nagode on 3/4/13.
//  Copyright (c) 2013 Mice3. All rights reserved.
//

#import "M3Synchronization.h"
#import "AFHTTPRequestOperationManager.h"
#import "AFHTTPRequestOperation.h"
#import "M3RegistrationManager.h"


#define kSynchronizationEntityOutputCommunication 1

@interface M3Synchronization(){}

@property (nonatomic) int currentSyncIndex;

@property (nonatomic, strong) NSMutableArray * itemsToSync;
@property (nonatomic) BOOL isSyncing;
@property (nonatomic, weak) NSManagedObjectContext * context;
@property (nonatomic, copy) NSString * serverUrl;
@property (nonatomic, copy) NSString * serverReceiverScript;
@property (nonatomic, copy) NSString * serverFetcherScript;
@property (nonatomic, strong) NSArray *uniqueTableFields; // unique fields are for used for detection and merging of duplicates
@property (nonatomic, strong) NSArray *syncedTableFields; // all fields that will be synchronized

@property (nonatomic, strong) NSMutableArray * multipartDataArray;

@end

@implementation M3Synchronization

static NSMutableDictionary *synchingTablesDictionary;


+(NSMutableDictionary *) getSynchingTableDictionary
{
    if (synchingTablesDictionary == nil) {
        synchingTablesDictionary = [NSMutableDictionary dictionaryWithCapacity:3];
    }
    return synchingTablesDictionary;
}

//-(id) initForClass: (NSString *) className{
//    return [self initForClass:className andContext:nil andServerUrl:nil];
//}

-(NSMutableArray *) multipartDataArray
{
    if (!_multipartDataArray) {
        _multipartDataArray = [NSMutableArray arrayWithCapacity:5];
    }
    return _multipartDataArray;
}

-(id)               initForClass: (NSString *) className
                      andContext: (NSManagedObjectContext *) context
                    andServerUrl: (NSString *) serverUrl
     andServerReceiverScriptName: (NSString *) serverReceiverScript
      andServerFetcherScriptName: (NSString *) serverFetcherScript
            ansSyncedTableFields: (NSArray *) syncedTableFields
            andUniqueTableFields: (NSArray *) uniqueTableFields
{
    if(self = [self init]){
        
//        if (!jsonFileName) {
//            jsonFileName = @"syncSpecifications";
//        }
        
        if (!serverReceiverScript) {
            serverReceiverScript = @"/mobile_scripts/getLastChangesDynamic.php?class=%@";
        }
        
        if (!serverFetcherScript) {
            serverFetcherScript = @"/mobile_scripts/syncDynamic.php?class=%@";
        }
        
        if (!serverUrl) {
            serverUrl = @"http://synctest.talcho.com";
        }
        
        
        //NSDictionary *json = [self getJsonFromFile:jsonFileName];
        
        self.className = className;
        //self.classSettings = nil; // [json objectForKey:className];
                
        self.context = context;
        
        self.serverUrl = serverUrl;
        self.serverFetcherScript = serverFetcherScript;
        self.serverReceiverScript = serverReceiverScript;
        
        self.uniqueTableFields = uniqueTableFields;
        self.syncedTableFields = syncedTableFields;
        
    }
    return self;
}


-(id) initForClassFromJsonConfiguration: (NSString *) className
{
    NSDictionary * json = [self getJsonFromFile:@"SyncConfiguration"];
    
    
    NSDictionary * jsonEntity = [[json objectForKey:@"entities"] objectForKey:className];
    
    
    
    if (self = [self initForClass:className
                       andContext:[NSManagedObjectContext defaultContext]
                     andServerUrl:[json objectForKey:@"serverUrl"]
      andServerReceiverScriptName:[json objectForKey:@"saveDataScript"]
       andServerFetcherScriptName:[json objectForKey:@"getDataScript"]
             ansSyncedTableFields:[jsonEntity objectForKey:@"columns"]
             andUniqueTableFields:[jsonEntity objectForKey:@"uniqueColumns"]])
    {
        NSString * className = [json objectForKey:@"additionalPostParametersClassName"];
        NSString * methodName = [json objectForKey:@"additionalPostParametersMethodName"];
        
        if([className length] > 0) {
            
            Class class = NSClassFromString(className);
            SEL selector = NSSelectorFromString(methodName);
            
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            self.additionalPostParamsDictionary = [class performSelector:selector];
#pragma clang diagnostic pop
            
        }
        
    }
    
    return self;
    
    
}


-(id) getJsonFromFile: (NSString *) file
{
    NSError *error;
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    
    NSString *filePath = [bundle pathForResource:file ofType:@"json"];
    NSString *jsonString = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&error];
    
    if(error) {
        NSLog(@"%@", error);
    }
    
    
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *results = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
    
    if(error) {
        NSLog(@"%@", error);
    }
    
    //NSLog(@"%@", results);
    
    return results;
}

-(NSString *) getIsSyncedWhenActivatedKey {
    return [@"isSyncedWhenActivated_" stringByAppendingString:self.className];
}

-(BOOL) isSyncedWhenActivated {
    
    BOOL isActivated = [[NSUserDefaults standardUserDefaults] boolForKey:[self getIsSyncedWhenActivatedKey]];
    return isActivated;
}

-(void) sync {
    // todo
    
//    if (![self isSyncedWhenActivated]) {
//      
//        if([[self.classSettings objectForKey:@"authenticationType"] isEqualToString:@"deviceId"]) {
//            // we allow syncing even if user has not yet activated account
//            if([[NSUserDefaults standardUserDefaults] integerForKey:@"userDeviceId"] < 1) {
//                [self.delegate onSynchronizationError:self];
//                return; // we require that device has been registrated (email was set but not yet activated
//            }
//        } else if([[self.classSettings objectForKey:@"authenticationType"] isEqualToString:@"userId"]) {
//            self.isSyncing = NO;
//            [self.delegate onSynchronizationError:self];
//            return; // do not sync device is not activated
//        }
//        
//    }
    
    
    
    if(!self.isSyncing) {
        if ([[M3Synchronization getSynchingTableDictionary] objectForKey:self.className] != nil) {
            
            [[M3Synchronization getSynchingTableDictionary] removeObjectForKey:self.className];
            
            self.isSyncing = NO;
            if(self.delegate && [self.delegate respondsToSelector:@selector(onSynchronizationError:)]) {
                [self.delegate onSynchronizationError:self];
            }
            
            // the table is already synching, do not synch again until the previous instance is done
        } else {
            [[M3Synchronization getSynchingTableDictionary] setObject:self.className forKey:self.className];
            
            self.isSyncing = YES;
            
            self.countItemsToSync = 0;
            self.countModifiedItemsFromServer = 0;
            self.currentSyncIndex = 0;

//            NSString * syncDirection = [self.classSettings valueForKey:@"syncDirection"];
            if(self.syncToServerOnly) {
                [self sendNewDataToServer]; // if we do not need to receive data to server just send new data to server
            } else {
                [self getModifiedDataFromServer]; // step 1, on success: merge => send new data do server
            }
            
        }
    }
}

-(int) lastSyncWithServerTimestamp
{
    int lastTimestamp = [[NSUserDefaults standardUserDefaults] integerForKey:[NSString stringWithFormat:@"lastTimestampFromServer_%@", self.className]];
    
    if(![self isSyncedWhenActivated]) {
        return 0; // until device is activated - we try to load all data from server - data with timestamp > 0
    }
    
    return lastTimestamp;
}

-(void) updateServerTimestamp: (int) timestamp
{
    [[NSUserDefaults standardUserDefaults] setInteger:timestamp forKey:[NSString stringWithFormat:@"lastTimestampFromServer_%@", self.className]];
}

-(NSArray *) getEntitiesWithRemoteIdOrderedByTimestampModified: (int) remoteId
{
    
    NSError * error;
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription * entity = [NSEntityDescription entityForName:self.className inManagedObjectContext:self.context];
    [request setEntity:entity];
     
    NSPredicate *predicate = [NSPredicate predicateWithFormat: [NSString stringWithFormat:@"remoteId = %d", remoteId]];
    [request setPredicate:predicate];
   
    NSSortDescriptor* sortDescriptor = [[NSSortDescriptor alloc]
                                        initWithKey:@"timestampModified" ascending:NO];
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects: sortDescriptor, nil];
    [request setSortDescriptors:sortDescriptors];
    
    
    NSArray * array = [NSMutableArray arrayWithArray:[self.context executeFetchRequest:request error:&error]];
    if(error) {
        [self handleError:error andDescription:NSLocalizedString(@"CoreDataProblem", nil)];
    }
    
    return array;
}

-(NSMutableDictionary *) getAdditionalPostParams
{
    if (!self.additionalPostParamsDictionary) {
        return [NSMutableDictionary dictionary];
    }
    

    return [[NSMutableDictionary alloc] initWithDictionary:self.additionalPostParamsDictionary];
}


-(void) getModifiedDataFromServer
{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];

    NSMutableDictionary * postParams = [self getAdditionalPostParams];
    
    
    if ([self lastSyncWithServerTimestamp]) {
        [postParams setObject:[NSNumber numberWithInt:[self lastSyncWithServerTimestamp]] forKey:@"timestampLastSync"];
    }
    
    NSLog(@"Fetch URL: server=%@, fetcherScript=%@", self.serverUrl, self.serverFetcherScript);
    
    
    NSString *url = [NSString stringWithFormat:@"%@%@%@",self.serverUrl,self.serverReceiverScript, self.className];
    
    [manager POST:url
parameters:postParams
success:^(AFHTTPRequestOperation *operation, id responseObject) {
    
        NSDictionary *JSON;
        NSError *error;
        if ([responseObject isKindOfClass:[NSData class]]) {
            NSString *text = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
            
    #if kSynchronizationEntityOutputCommunication
            NSLog(@"response for class: %@: %@",self.className,  text);
    #endif
            JSON = [NSJSONSerialization JSONObjectWithData: [text dataUsingEncoding:NSUTF8StringEncoding]
                                                   options: NSJSONReadingMutableContainers
                                                     error: &error];
        } else {
            JSON = responseObject;
        }
        
        if(error) {
//            UIAlertView *alert = [[UIAlertView alloc]initWithTitle: @"ERRORS ON SERVER"
//                                                           message: text
//                                                          delegate: nil
//                                                 cancelButtonTitle:@"OK"
//                                                 otherButtonTitles:nil];
//            [alert show];
//
//            self.isSyncing = NO;
            
            [self handleError:error andDescription:[NSString stringWithFormat:@"%@", JSON]];
            
            if(self.delegate && [self.delegate respondsToSelector:@selector(onSynchronizationError:)]) {
                [self.delegate onSynchronizationError:self];
            }
            return;
        }
        
        
        if(!error &&  ![[JSON objectForKey:@"hasError"] boolValue]) {
            BOOL isActivated = [self isSyncedWhenActivated];
            if(!isActivated) {
                [[NSUserDefaults standardUserDefaults] setBool:YES forKey:[self getIsSyncedWhenActivatedKey]];
                
                [self onDeviceActivationDetected];
            }
            
            NSArray * items = [JSON objectForKey:@"items"];
            
            self.countModifiedItemsFromServer = [items count];
            
            NSDateFormatter *format = [[NSDateFormatter alloc] init];
            [format setDateFormat:@"yyyy-MM-dd' 'HH:mm:ss"];
            
            for (NSDictionary * item in items) {
                // check if we have item in local DB
                
                int remoteId = [[item objectForKey:@"remoteId"] intValue];
                
                // check for duplicates
                NSString * predicateString = @"";
                
                
                // check for unique fields
                if(self.uniqueTableFields) {
                    NSArray * fields = self.uniqueTableFields;
                    
                    if ([fields count]) {
                        // check for duplicates and delete them
                        
                        BOOL isFirst = YES;
                        for(NSString * field in fields) {
                            if(!isFirst) {
                                predicateString = [predicateString stringByAppendingString:@" and "];
                            }
                            if([field rangeOfString:@"datetime"].location != NSNotFound) {
                                // TODO: do this work?
                                predicateString = [predicateString stringByAppendingFormat:@"%@ = '%@'", field, [format dateFromString:((NSString *)[item valueForKey:field])] ];
                                
                            } else {
                                id value = [item valueForKey:field];
                                if([value isKindOfClass:[NSString class]]) { // string
                                    predicateString = [predicateString stringByAppendingFormat:@"%@ = '%@'", field, value];
                                } else {  // number
                                    predicateString = [predicateString stringByAppendingFormat:@"%@ = %d", field, (int) value];
                                }
                            }
                            isFirst = NO;
                        }
                    }
                }
              
                // end check of unique fields
                if ([predicateString length] > 0) {
                    predicateString = [NSString stringWithFormat:@"(%@) or", predicateString];
                }
                predicateString = [NSString stringWithFormat:@"%@ (remoteId=%d)", predicateString, remoteId];

                // get local duplicates
                NSFetchRequest *request = [[NSFetchRequest alloc] init];
                NSEntityDescription * entityDescription = [NSEntityDescription entityForName:self.className inManagedObjectContext:self.context];
                [request setEntity:entityDescription];
                
                NSPredicate *predicate = [NSPredicate predicateWithFormat:predicateString];
                NSSortDescriptor* sortDescriptor = [[NSSortDescriptor alloc]
                                                    initWithKey:@"timestampModified" ascending:NO];
                NSArray *sortDescriptors = [[NSArray alloc] initWithObjects: sortDescriptor, nil];
                [request setSortDescriptors:sortDescriptors];
                [request setPredicate:predicate];
                
                NSArray * array = [NSMutableArray arrayWithArray:[self.context executeFetchRequest:request error:&error]];
                if(error) {
                    [self handleError:error andDescription:@"Core data problem"];
                }
 
                id entity;
                if ([array count] > 0) {
                    
                    // delete all duplicates - keep just the newes one (start with index i=1)
                    for (int i=1; i < [array count]; i++) {
                        [self.context deleteObject:[array objectAtIndex:i]];
                    }
                    
                    entity = [array objectAtIndex:0];
                    int entityTimestampModified =  [[entity valueForKey:@"timestampModified"] intValue];
                    
                    if(entityTimestampModified > [[item valueForKey:@"timestampModified"] intValue]) {
                        // we have newer data on phone: do not override data
                        continue;
                    }
                    // TODO: delete older objects
                } else {
                    // insert new data
                    entity = [NSEntityDescription insertNewObjectForEntityForName:self.className inManagedObjectContext:self.context];
                }

                // necessary fields
                [entity setValue:[NSNumber numberWithInt:[[item objectForKey:@"remoteId"] intValue]] forKey:@"remoteId"];
                [entity setValue:[item valueForKey:@"timestampInserted"] forKey:@"timestampInserted"];
                [entity setValue:[item valueForKey:@"timestampModified"] forKey:@"timestampModified"];
                [entity setValue:[NSNumber numberWithBool:[[item objectForKey:@"isDeleted"] boolValue]] forKey:@"is_Deleted"];
                [entity setValue: [NSNumber numberWithBool:NO] forKey:@"isDirty"];
                
                NSArray * fields = self.syncedTableFields;

                for(NSString * field in fields) {
                    if([field rangeOfString:@"datetime"].location != NSNotFound) {
                        [entity setValue:[format dateFromString:((NSString *)[item valueForKey:field])] forKey:field]; // special operations
                    } else {
                        [entity setValue:[item valueForKey:field] forKey:field];
                    }
                }
                

                // TODO: do we need to save every cycle or can we save at the end?
//                [self.context save:nil]; // TODO: handle error
                [AppDelegate saveContext];

                // perform action on NSManagedObjectEntity it it has afterUpdate method (PHP Doctrine style)
                SEL selector = NSSelectorFromString(@"afterUpdate");
                if([entity respondsToSelector:selector]) {
                    [entity performSelector: selector];
                }
                
                
                [self afterUpdateFromServer:item andEntity:entity];
                
            }
            
            [self updateServerTimestamp:[[JSON valueForKey:@"timestampServer"] intValue]];
            
        } else {
           
            if([JSON objectForKey:@"status"] && [[JSON objectForKey:@"status"] isEqualToString:@"deviceNotActivated"]) {
                // todo: what should we do if device is not activated?
                // most likely nothing -> or send notification and suggest user to login
            } else {

                [self handleError:nil andDescription:[JSON objectForKey:@"errorMessage"]];
            }
        }

        [self sendNewDataToServer];
        
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"%@", [error localizedDescription]);
        [self handleError:error andDescription:nil];
    }];
    
    NSLog(@"self.delegate = %@", self.delegate);
    NSLog(@"self.delegate class = %@", [self.delegate class]);
}


-(void) addMultipartData: (NSData *) data
                 andName: (NSString *) name
             andFileName: (NSString *) fileName
             andMimeType: (NSString *) mimeType
{
    
    NSDictionary * dictionary = @{@"data":data, @"name":name, @"fileName":fileName, @"mimeType":mimeType};
    
    [self.multipartDataArray addObject:dictionary];
}


-(void) sendNextNewDataToServer {
    
    if([self.itemsToSync count] == 0) {
        
        [[M3Synchronization getSynchingTableDictionary] removeObjectForKey:self.className];
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(onSynchronizationComplete:)]) {
            self.isSyncing = NO;
            [self.delegate onSynchronizationComplete:self];
        }
        
    } else {
        
        [self.multipartDataArray removeAllObjects]; // clear multipart data - it request shouls reset any data
        
        self.currentSyncIndex++; // for use with messages like: Syncing 1 of 10 items
        
        
        NSManagedObject *entity = [self.itemsToSync objectAtIndex:0];
        [self.itemsToSync removeObjectAtIndex:0];
        if (entity.managedObjectContext) {
            NSDateFormatter *format = [[NSDateFormatter alloc] init];
            [format setDateFormat:@"yyyy-MM-dd' 'HH:mm:ss"];
            
            NSMutableDictionary * entityDictionary = [NSMutableDictionary dictionaryWithCapacity:20];
            
            NSMutableArray * fields = [NSMutableArray arrayWithArray:self.syncedTableFields];
            [fields addObject:@"timestampModified"];
            [fields addObject:@"timestampInserted"];
            
            
            [entityDictionary setValue:[entity valueForKey:@"is_Deleted"] forKey:@"isDeleted"];
            
            
            for (NSString * field in fields) {
                NSLog(@"==>%@", field);
                if ([field rangeOfString:@"datetime"].location != NSNotFound) {
                    NSLog(@"date detected value=%@", [format stringFromDate:[entity valueForKey:field]]);
                    [entityDictionary setValue:[format stringFromDate:[entity valueForKey:field]] forKey:field];
                    [entityDictionary setValue:@"mona" forKey:[NSString stringWithFormat:@"x_%@", field]];
                } else {
                    id newValue = [entity valueForKey:field];
                    if (newValue == nil) {
                        [entityDictionary setValue:[NSNull null] forKey:field];
                        NSLog(@"null detected");
                    } else {
                        [entityDictionary setValue:newValue forKey:field];
                        NSLog(@"value OK");
                    }
                }
            }
            
            [self beforeSendToServer:entityDictionary andEntity:entity];
            
            //        NSMutableArray * multipartData = [entityDictionary objectForKey:@"multipartData"];
            //        [entityDictionary removeObjectForKey:@"multipartData"];
            
            
            NSString * jsonString = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:entityDictionary options:NSJSONWritingPrettyPrinted error:nil] encoding:NSUTF8StringEncoding];
            
            NSLog(@"%@", jsonString);
            
            NSMutableDictionary *params = [self getAdditionalPostParams];
            [params setObject:jsonString forKey:@"json"];
            
            
            // send remoteId if we send modified data back to server (isDirty flag=YES)
            id remoteIdObj = [entity valueForKey:@"remoteId"];
            if(remoteIdObj) { //
                int remoteId = [((NSNumber *) remoteIdObj) intValue];
                if (remoteId>0) {
                    [params setObject:((NSNumber *) remoteIdObj) forKey:@"remoteId"];
                }
            }
            
            if(self.outputCommunicationContentToConsole) {
                //NSLog(@"saveData URL: server=%@, getScript=%@", self.serverUrl, self.serverReceiverScript);
                NSLog(@"Params = %@", params);
            }
    
            
            AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
            
            NSString *url = [NSString stringWithFormat:@"%@%@%@",self.serverUrl,self.serverReceiverScript, self.className];
            
            [manager POST:url
               parameters:params constructingBodyWithBlock:^(id <AFMultipartFormData>formData){
                   
                   for (NSDictionary * dic in self.multipartDataArray) {
                       NSLog(@"multipart file detected");
                       //[formData appendPartWithFileData:data mimeType:@"image/jpeg" name:@"attachment"];
                       [formData appendPartWithFileData: dic[@"data"]
                                                   name: dic[@"name"]
                                               fileName: dic[@"fileName"]
                                               mimeType: dic[@"mimeType"]];
                   }
               } success:^(AFHTTPRequestOperation *operation, id responseObject) {
                   // Print the response body in text
                   
                   NSDictionary *JSON;
                   NSError *error;
                   if ([responseObject isKindOfClass:[NSData class]]) {
                       NSString *text = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
                    
                       JSON = [NSJSONSerialization JSONObjectWithData: [text dataUsingEncoding:NSUTF8StringEncoding]
                                                              options: NSJSONReadingMutableContainers
                                                                error: &error];
                   } else {
                       JSON = responseObject;
                   }
                   
                   if (error) {
                       [self handleError:error andDescription:[NSString stringWithFormat:@"%@", JSON]];
                       if (self.delegate && [self.delegate respondsToSelector:@selector(onSynchronizationError:)]) {
                           [self.delegate onSynchronizationError:self];
                       }
                       
                       return;
                   }
                   
                   
                   if ([[JSON valueForKey:@"hasError"] boolValue] == YES) {
                       [self handleError:nil andDescription:[JSON valueForKey:@"errorMessage"]];
                   } else {
                       
                       int remoteId = [[JSON objectForKey:@"remoteId"] intValue];
                       // check if items with same remoteId already exists and delete them! We do not want duplicates
                       
                       [entity setValue:[NSNumber numberWithInt:remoteId] forKey:@"remoteId"];
                       [entity setValue:[NSNumber numberWithBool:NO] forKey:@"isDirty"]; // mark field as synced with server
                       
                       
                       [self.context save:nil];
                       
                       SEL selector = NSSelectorFromString(@"afterUpdate");
                       if([entity respondsToSelector:selector]) {
                           [entity performSelector: selector];
                       }
                       
                       // keep only newest row with newest datetime modified data
                       NSArray * array = [self getEntitiesWithRemoteIdOrderedByTimestampModified:remoteId];
                       if ([array count] > 1) {
                           for(int i=1; i<[array count]; i++) {
                               //if(![tmp isEqual: tmp]) { // leave only current entity, delete others
                               [self.context deleteObject:[array objectAtIndex:i]];
                               //}
                           }
                       }
                   }
                   
                   [self updateServerTimestamp:[[JSON valueForKey:@"timestampServer"] intValue]];
                   [self sendNextNewDataToServer];
                   
               } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                   [self handleError:error andDescription:nil];
           }];
        
        }
    }
}


-(void) sendNewDataToServer {
    
    NSError * error;
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription * entity = [NSEntityDescription entityForName:self.className inManagedObjectContext:self.context];
    [request setEntity:entity];
    
    NSString * predicateString = @"remoteId < 1 or isDirty = YES";
    
    if (self.clientNewDataPredicate) {
        predicateString =  [NSString stringWithFormat:@"(%@) AND (%@)", predicateString, self.clientNewDataPredicate];
    }
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:predicateString];
    [request setPredicate:predicate];
    
    self.itemsToSync = [NSMutableArray arrayWithArray:[self.context executeFetchRequest:request error:&error]];
    
    if (error) {
        [self handleError:error andDescription:nil];
        return;
    }
    
    self.countItemsToSync = [self.itemsToSync count];
    
    [self sendNextNewDataToServer];
}





-(void) handleError: (NSError *) error andDescription: (NSString *) description
{
//    NSLog(@"%@ %@", error.description, description);
    
    
    self.isSyncing = NO;
    
    [self.itemsToSync removeAllObjects];
    self.itemsToSync = nil;
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(onSynchronizationError:)]) {
        [self.delegate onSynchronizationError:self];
    }
    
    
    [self onError:error andDescription:description];
}



/* code below should be updated for each framework - especially onError - we have to handle error somehow */
-(void) beforeSendToServer: (NSMutableDictionary *) json
                 andEntity: (id) entity {
    // this method should be overriden if some object needs to modify JSON before send data to server
}


-(void) afterUpdateFromServer: (NSDictionary *) json
                    andEntity: (id) entity {
    // this method should be overriden if object needs special actionas after data is received from server
}

-(void) onError: (NSError *) error andDescription: (NSString *) description
{
    // this method should be overriden and do special actions - eg: loading UI hide
}

-(void) onDeviceActivationDetected {
    // what to do when sync and detect that in mean time - device was activated
}



-(void) dealloc
{
    self.delegate = nil; // IMPORTANT: since delegate is strong in order that it stays in memory until synchronization is completed - we have to set it to nil when entity is deallocated. If
    NSLog(@"M3Synchronization was deallocated");
}

@end
