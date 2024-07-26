public with sharing class FeedItemTriggerHandler extends TriggerHandler {
        
     public override void afterInsert() {
        List<FeedItem> feedItemList = Trigger.New;
       
        //Start SFDC-19350
        Map<Id,feedItem> csIdtofeedIdMap=new Map<Id,feedItem>();
         for(feedItem item:feedItemList){
             if(item.ParentId!=null && ((String)item.ParentId).StartsWith('500') && item.Body.contains('@Zendesk')){
              	csIdtofeedIdMap.put(item.ParentId,item);  
                 }
         }
         ZendeskIntegrationHandler.addCommentInZendesk(csIdtofeedIdMap);
         //End SFDC-19350
     }
}