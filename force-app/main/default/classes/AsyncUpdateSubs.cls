public class AsyncUpdateSubs implements Queueable  {
   public Set<Id> assetIds;
  
   public AsyncUpdateSubs(Set<Id> assetIds){
    this.assetIds = assetIds ;  
  }

public void execute(QueueableContext context){  

        Set<Id> serId=new Set<Id>();
        Set<Id> subId=new Set<Id>();
        Set<Id> prodId=new Set<Id>();
        Map<Id,String> assrBaseSKU=new Map<Id,String>();
        LogModel log = LogModel.startLog('DynamicBusinessRuleAsset','updateSubs');  
            
        List<SBQQ__ProductOption__c> prodOptionFor=new List<SBQQ__ProductOption__c>();
       
        try {

            for( Asset asst :[Select Id,SBCF_Serial_Number__c,BNCPQ_Serial__c from Asset where 
            Id in :assetIds]) {

                serId.add(asst.BNCPQ_Serial__c);
                System.Debug('SerialIds::'+ serId);
            }

            Map<Id,SBQQ__Subscription__c> asSubMap=new Map<Id,SBQQ__Subscription__c>();      
            Map<Id,Id> asProdIdMap=new Map<Id,Id>();           

            for( Assigned_Serial__c assr :[Select Id,Subscription__c,Base_SKU__c,Product_SKU__c from Assigned_Serial__c 
            where Subscription__c !=null and  Serial__c in :serId]) {

                subId.add(assr.Subscription__c);               
                assrBaseSKU.put(assr.Id,assr.Base_SKU__c);
            }          

            System.Debug('assrBaseSKU::'+ assrBaseSKU);

            List<SBQQ__Subscription__c> subs=[Select Id,SBQQ__Product__c,SBQQ__RequiredById__c,SBQQ__ProductOption__c,
            SBQQ__RequiredByProduct__c from SBQQ__Subscription__c where Id
            in : subId];

            for( Assigned_Serial__c assr :[Select Id,Subscription__c,Subscription__r.SBQQ__Product__r.Id,
             Base_SKU__c from Assigned_Serial__c 
            where Subscription__c !=null and  Serial__c in :serId]) {

                for(SBQQ__Subscription__c s : subs) {
                 
                    if(assr.Subscription__c==s.Id) {
                        asSubMap.put(assr.Id,s);
                    }
                }

                asProdIdMap.put(assr.Id,assr.Subscription__r.SBQQ__Product__r.Id);
            }

            System.Debug('asSubMap::'+ asSubMap);
            System.Debug('asProdIdMap::'+ asProdIdMap);
         
            for(SBQQ__Subscription__c sub : [Select Id,SBQQ__Product__c from SBQQ__Subscription__c where Id in : subId]){

                prodId.add(sub.SBQQ__Product__c);                
           }

           System.Debug('prodId::'+ prodId);

           Map<Id, List<SBQQ__ProductOption__c>> prodIdOptionMap=new Map<Id, List<SBQQ__ProductOption__c>>();
           List<SBQQ__ProductOption__c> templist=new List<SBQQ__ProductOption__c>();

          for(Product2 prod : [Select Id, (Select Id, name,SBQQ__ConfiguredSKU__c,SBQQ__ConfiguredSKU__r.ProductCode,SBQQ__ProductCode__c
                               from SBQQ__OptionalFor__r), (Select Id , name from SBQQ__Subscriptions__r where Id in : subId) from product2  where Id in : prodId]){

            for(SBQQ__ProductOption__c po : prod.SBQQ__OptionalFor__r) {

                templist.add(po);               
            }          
          
            prodOptionFor=templist.clone();
           
            templist.clear();
            prodIdOptionMap.put(prod.Id,prodOptionFor);
                 
          }

          System.Debug('prodOptionFor::'+ prodOptionFor);
          System.Debug('prodOptionMap::'+ prodIdOptionMap);   

           Map<Id,Id> getProdOption=new Map<Id,Id>();
           Map<Id,SBQQ__ProductOption__c> sub2Update=new Map<Id,SBQQ__ProductOption__c>();
           List<SBQQ__Subscription__c> thisSubUpdate=new List <SBQQ__Subscription__c>();
           System.Debug('assrBaseSKU.keySet()::'+ assrBaseSKU.keySet());
        
          for(Id assrid: assrBaseSKU.keySet())
          {          
            if(assrBaseSKU.get(assrid)=='BEO001a')              
              continue;            

            for(SBQQ__ProductOption__c po:prodIdOptionMap.get(asProdIdMap.get(assrid)) ) {    
                          
              if((assrBaseSKU.get(assrid)==po.SBQQ__ConfiguredSKU__r.ProductCode) ) {
               
               System.Debug('assrBaseSKU.get(assrid)::'+ assrBaseSKU.get(assrid));
               System.Debug('po.SBQQ__ConfiguredSKU__r.ProductCode::'+ po.SBQQ__ConfiguredSKU__r.ProductCode);
              
               asSubMap.get(assrid).SBQQ__ProductOption__c =po.Id;   
               asSubMap.get(assrid).SBQQ__RequiredByProduct__c =po.SBQQ__ConfiguredSKU__c;                   
              
              // sub2Update.put(asSubMap.get(assrid).Id,po);             
                break;
              }
             }          
          }

          //  for(SBQQ__Subscription__c subbs: [Select Id,SBQQ__ProductOption__c,SBQQ__RequiredByProduct__c from SBQQ__Subscription__c
          //                  where Id in : sub2Update.keySet()]){

          //                   subbs.SBQQ__ProductOption__c=sub2Update.get(subbs.Id).Id;
          //                   subbs.SBQQ__RequiredByProduct__c=sub2Update.get(subbs.Id).SBQQ__ConfiguredSKU__c;
          //                   thisSubUpdate.add(subbs);

          //                   System.debug('thisSubUpdate::' + thisSubUpdate);
          //  }

           System.Debug('asSubMap.values::'+ asSubMap.values());            

         if((asSubMap.values()!=null && !asSubMap.values().isEmpty()))
         {        
          Database.SaveResult[] srList = Database.update(asSubMap.values(), false);
          for(Database.SaveResult sr: srList){
              if(!sr.isSuccess()){
                String errorMessage =  'Error updating Subscription ' + sr.getId() + ' : ';
                for(Database.Error error: sr.getErrors()){
                  errorMessage += error.getMessage();
                }
                log.addLog(errorMessage);
              }
              else{
                log.addLog('Subscription updated: ' + sr.getId());
                //System.debug(':Subscription:'+ thisSubUpdate);             
              }
            }
            log.endLog();
          }

        } catch (Exception e) {
            System.debug(':Exception:'+ e.getMessage()); 
            log.addLog(':Exception: ' + e);
            log.endLog();            
        }
    

}
}