M3Synchronization
=================

Client and server synchronization of database tables. This code is for OBJC+CoreData client. For server side you can use <a href="#">this repo</a>.

<h3>Functionalities</h3>
- <b>Sync client and server database table so client and server both have same values</b>
- Class knows how to resolve merge conflicts - if same row is modified on server and client only the newest one will be used
- Class in reliable even in low network quality - it automatically detects redundant data and corrects it
- It is easy to send files (e.g. photos) to server
- It is possible to easily send nested data together (e.g. News + NewsComment)
- With predicates it is possible to filter which rows will be sent to server (You can send only rows which will not change in the near future)
- You can easily connect it with custom user athentication systems - you can pass additional POST params in every request to your server
- When user will register, server will return all data but next time just rows that have been changed

<h2>Code example:</h2>
<pre>
   M3Synchronization * syncEntity = [[M3Synchronization alloc] initForClass: @"Car"
                                                                  andContext: context
                                                                andServerUrl: kWebsiteUrl
                                                 andServerReceiverScriptName: kServerReceiverScript
                                                  andServerFetcherScriptName: kServerFetcherScript
                                                        ansSyncedTableFields:@[@"licenceNumber", @"manufacturer", @"model"]
                                                        andUniqueTableFields:@[@"licenceNumber"]];
                                                
                                                
    syncEntity.delegate = self; // delegate should implement onComplete and onError methods
    syncEntity.additionalPostParamsDictionary = ... // add some POST params to authenticate current user
    
    [syncEntity sync];
</pre>

Feel free to check /Example/ folder where you can find running example of implementation. You can just tweak it a little bit and use with your own project.

<h3>Install instructions</h3>

How to add to your project:

- Add /M3Synchronization/ (which contains M3Synchronization.h ...) to your project
- Add /Dependencies/AFNetworking/AFNetworking/ (contains AFHttpClient.h ...) to your project if you dont use it already

Click on your project -> build settings -> <<your target>> -> Link binary with Libraries and make shure you have included following frameworks:

- CoreData.framework
- Security.framework

<h3>CoreData table modifications</h3>

On every table you want to sync you have to add some metadata columns:
- isDirty
- timestampModified
- timestampInserted
- remoteId
- is_Deleted (isDeleted is reserved property, sorry)

Dont forget to generate class models again. Your client is ready to go.



