/**
 * Author: Marcus Ericsson - mericsson@salesforce.com
 */
trigger DisableFeedPostDeletes on FeedItem (before delete,after insert) 
{    new FeedItemTriggerHandler().run();
    if (!DisableChatterDeleteDelegate.allowDelete() && Trigger.isDelete==true) {
        for(FeedItem f : Trigger.old){
             if ((((String)f.parentId).startsWith('00Q') && f.type == 'TrackedChange') 
            || ((String)f.parentId).startsWith('a1Y')){
                // ok to ignore
            }
            else {
                f.addError('Your administrator has disabled feed post and comment deletions.'); 
            }
        }
    }
}