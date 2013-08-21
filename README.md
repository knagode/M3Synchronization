M3Synchronization
=================

Client and server synchronization of database tables. This code is for OBJC+CoreData client.

Code sample:
<pre>
    M3Synchronization * syncEntity = [[M3Synchronization alloc] initForClass: @"Car"
                                                                  andContext: context
                                                                andServerUrl: @"http://yourserver.tld"
                                                 andServerReceiverScriptName: @"/mobile/syncSave?class=%@"
                                                  andServerFetcherScriptName: @"/mobile/syncGet?class=%@"
                                                andJsonSpecificationFileName: @"syncSpecifications"];
    syncEntity.delegate = self; // delegate should implement onComplete and onError methods
    syncEntity.additionalPostParamsDictionary = ... // add some POST params to authenticate current user
    
    [syncEntity sync];
</pre>


How to add to your project (See /Example for working example):

- Add /M3Synchronization/ (which contains M3Synchronization.h ...) to your project
- Add /Dependencies/AFNetworking/AFNetworking/ (contains AFHttpClient.h ...) to your project if you dont use it already

Click on your project -> build settings -> <<your target>> -> Link binary with Libraries and make shure you have included following frameworks:

- CoreData.framework
- Security.framework



