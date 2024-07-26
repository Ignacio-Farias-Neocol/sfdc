/**
* @author       Rajesh Wani     
* @date          2022-12-22
*                
* @description   Batch Apex class to process Legacy serial data which are RMA with new Serial in BOSS
If Model of new serial is same as original serial  then
1.Update Asset/Subscription serial with New Serial
2.Create new  Serial for new serial Number if not present
3.Create new Assign Serial for new serial Number
4.Update Old Serial Number to InActive
5.Update Assign Serial related to Old Serial Number to InActive
* @group         Helper
*
*/
global class LegacySerialDataFixBatch  implements Database.Batchable<SObject>{
    public String StatusActive ;
    public String BussinessGroupCore ;
    public String BussinessGroupMKT ;
    public Date DateFilter ;
    Global String StatusNP;
    Global string jid;
    public Static Boolean BypassQuable=false;
    /**
* START Method:
*/
    global Database.QueryLocator start(Database.BatchableContext BC) {
        DateFilter = (system.today()).adddays(-30);
        StatusActive = 'Activated';
        BussinessGroupCore = 'Core';
        BussinessGroupMKT = 'Marketplace';
        
        StatusNP = 'Not Processed';
      
        String query ='SELECT id,Asset_Id__c,Assign_Serial_Id__c,Model_Changed__c,New_Model__c,Final_Serial_For_Serial1__c, Serial_1__c,Serial_2__c,  Serial_Id__c,Status__c,Subscription_Id__c,Execute_Batch__c from Jumbled_Serial_Tracking__c WHERE Status__c=:StatusNP AND Legacy_Serial_Issue__c=true';
        if(Test.isRunningtest()){
             query ='SELECT id,Asset_Id__c,Assign_Serial_Id__c,Model_Changed__c,New_Model__c,Final_Serial_For_Serial1__c, Serial_1__c,Serial_2__c,  Serial_Id__c,Status__c,Subscription_Id__c,Execute_Batch__c from Jumbled_Serial_Tracking__c WHERE Status__c=:StatusNP AND Legacy_Serial_Issue__c=true';

        }
        return Database.getQueryLocator(query);
        
    }
    /**
* Execute Method:
*/
    global void execute(Database.BatchableContext BC, List<Jumbled_Serial_Tracking__c> LegacySerialList){
       
         List<Id> legacyIds = new List<Id>();
         for(Jumbled_Serial_Tracking__c legacySerial : LegacySerialList){
               legacyIds.add(legacySerial.id);
            }
              processExchnageData(legacyIds);
           
    }

    /**
* Finish Method:
*/
    global void finish(Database.BatchableContext BC){
        
    }
    
     @InvocableMethod(label='Legacy Serial Data fix' description='Legacy Serial Data fix')
    global Static Void processExchnage(List<ID> Ids) {
        processExchnageAsync(Ids);
    }
     @future
    global Static Void processExchnageAsync(List<ID> Ids) {
        processExchnageData(Ids);
    }
     
    global Static Void processExchnageData(List<ID> Ids) {
         //Instantiate the log class to capture logs for error conditions
        LogModel log = LogModel.startLog('LegacySerialDataFixBatch', 'executeMethod', LogModel.LOG_CATEGORY_APEX);
        
        Map<String,String> SerialsLegacytoNew = new Map<String,String>();
        List<Serial__c> SerialListUpdate = new List<Serial__c>();
        List<Assigned_Serial__c> AssignSerialListUpdate = new List<Assigned_Serial__c>();
        List<Assigned_Serial__c> AssignSerialUpsert = new List<Assigned_Serial__c>();
        List<Assigned_Serial__c> AssignSerialUpsertFinal = new List<Assigned_Serial__c>();
        List<Serial__c> SerialLatest = new List<Serial__c>();
        Set<Id> parentIds = new Set<Id>();
        List<Asset> UpdateAsset = new List<Asset>();
        List<SBQQ__Subscription__c> SubUpdate= new List<SBQQ__Subscription__c>();
        Map<String,Serial__c> SerialsMap = new Map<String,Serial__c>();
        String NewSerial ;
        String oldSerial ;
        Serial__c newSerialObj;
        BypassQuable =true;
        Boolean ModelChange=false;
        String NewModel=null; 
        Set<Id> subProducts = new Set<Id>();
        Map<String,SBQQ__ProductOption__c> POMap= new Map<String,SBQQ__ProductOption__c>();
        Set<String> subSerialkeys= new Set<String>();
        Set<String> externalIdskeys= new Set<String>();
        String StatusNPS = 'Not Processed';
        String AssetProductId;
        String AssetProductcode;
        try{
            List<Jumbled_Serial_Tracking__c> LegacySerialList=[SELECT id,Asset_Id__c,Assign_Serial_Id__c,Model_Changed__c,New_Model__c,Final_Serial_For_Serial1__c, Serial_1__c,Serial_2__c,  Serial_Id__c,Status__c,Subscription_Id__c,Execute_Batch__c FROM Jumbled_Serial_Tracking__c WHERE Status__c=:StatusNPS AND Legacy_Serial_Issue__c=true AND id IN:Ids];
                
            
            for(Jumbled_Serial_Tracking__c legacySerial : LegacySerialList){
                SerialsLegacytoNew.put(legacySerial.Serial_1__c,legacySerial.Final_Serial_For_Serial1__c);
                NewSerial=legacySerial.Final_Serial_For_Serial1__c;
                oldSerial=legacySerial.Serial_1__c;
                legacySerial.Status__c='Completed';
                legacySerial.Execute_Batch__c=false;
                ModelChange=legacySerial.Model_Changed__c;
                NewModel=legacySerial.New_Model__c;
            }
            
            for(Serial__c serial:[SELECT id,Serial_Number__c,Status__c,Account__c, Is_Terminated__c,Product__c,Base_Product_SKU__c,Business_Group__c,Product__r.Replacement_Product__c,Last_Serial__c,Product__r.Replacement_Product__r.productcode,(SELECT id,Serial__c,Subscription__c,Status__c,Parent_Subscription__c,Order_Order_Line_ID_Text__c,Asset__c,Order__c,Contract__c,Fulfillment_Date2__c,External_ID__c,Expire_Date__c,Qty_in_Use__c,Capacity__c,Business_Group__c,Date_Of_Replacement__c,Data_Reporting_Field__c ,Subscription__r.SBQQ__RequiredByProduct__r.Replacement_Product__c,Subscription__r.SBQQ__RequiredByProduct__r.Replacement_Product__r.name,Subscription__r.SBQQ__RequiredByProduct__r.Replacement_Product__r.SBCF_Product_Model__c,Subscription__r.SBQQ__RequiredByProduct__c ,Subscription__r.SBQQ__Product__c,Subscription__r.SBQQ__RequiredByProduct__r.Replacement_Product__r.ProductCode FROM Assigned_Serials__r WHERE Subscription__r.Renewed_By_Subscription__c=null AND Subscription__r.SBQQ__TerminatedDate__c=null  AND Subscription__r.SBQQ__RenewedDate__c=null) FROM Serial__c WHERE Serial_Number__c IN :SerialsLegacytoNew.keyset() OR Serial_Number__c IN :SerialsLegacytoNew.values() ]){
                SerialsMap.put(serial.Serial_Number__c,serial);
                
                if(serial.Serial_Number__c==NewSerial){
                    
                 for(Assigned_Serial__c asgSer:serial.Assigned_Serials__r){
                     
                         if(asgSer.Subscription__c!=null ){
                          subSerialkeys.add(String.valueOf(asgSer.Subscription__c)+serial.id);
                         }
                        if(asgSer.Subscription__c!=null && asgSer.Asset__c!=null ){
                          subSerialkeys.add(String.valueOf(serial.id)+ asgSer.Asset__c+asgSer.Subscription__c);
                         }
                         if(asgSer.Subscription__c==null && asgSer.Asset__c!=null){
                            
                          subSerialkeys.add(String.valueOf(asgSer.Asset__c)+serial.id);
                         }
                        if(asgSer.Parent_Subscription__c!=null && asgSer.Asset__c==null && asgSer.Subscription__c==null){
                          subSerialkeys.add(String.valueOf(asgSer.Parent_Subscription__c)+serial.id);
                         }
                     
                 }
                }
            }
                
            for(String skeyLegacy:SerialsLegacytoNew.keyset()){
                
                if(SerialsMap.containskey(skeyLegacy) ){
                    Serial__c Serial=SerialsMap.get(skeyLegacy);
                    
                    
                    serial.Status__c='Inactive';
                    serial.Is_Terminated__c=true;
                    SerialListUpdate.add(serial);
                    for(Assigned_Serial__c asgSer:serial.Assigned_Serials__r){
                        asgSer.Status__c='Inactive';
                        AssignSerialUpsert.add(asgSer);
                        if(asgSer.Asset__c!=null && !parentIds.contains(asgSer.Asset__c)){
                            parentIds.add(asgSer.Asset__c);
                            Asset aset = new asset(Id=asgSer.Asset__c,SBCF_Serial_Number__c=NewSerial,SerialNumber=NewSerial);
                           
                            if(ModelChange==TRUE && asgser.Subscription__r.SBQQ__RequiredByProduct__r.Replacement_Product__c!=null && (asgser.Subscription__r.SBQQ__RequiredByProduct__r.Replacement_Product__r.ProductCode.toUppercase().contains(NewModel) || 
                                    (asgser.Subscription__r.SBQQ__RequiredByProduct__r.Replacement_Product__r.SBCF_Product_Model__c!=null && asgser.Subscription__r.SBQQ__RequiredByProduct__r.Replacement_Product__r.SBCF_Product_Model__c.toUppercase().contains(NewModel)))  ){
                                     aset.Product2id= asgSer.Subscription__r.SBQQ__RequiredByProduct__r.Replacement_Product__c;
                                            AssetProductId=asgSer.Subscription__r.SBQQ__RequiredByProduct__r.Replacement_Product__c;
                                         AssetProductcode =asgSer.Subscription__r.SBQQ__RequiredByProduct__r.Replacement_Product__r.productcode;
                            }
                            
                            UpdateAsset.add(aset);
                        }
                        if(asgSer.Parent_Subscription__c!=null){
                            
                            parentIds.add(asgSer.Parent_Subscription__c);
                        }
                        if(asgSer.Subscription__c!=null){
                            parentIds.add(asgSer.Subscription__c);
                        }
                     
                        
                           
                       Boolean asgObjPresent=FALSE;
                       String subSerKey;
                       
                       
                            Assigned_Serial__c  newAsg =asgSer.clone(false, false, false, false);
                            newAsg.id=null;
                            newAsg.Status__c='Active';
                            newAsg.Serial__c= null;
                            newAsg.External_ID__c= null;
                         
                            if(SerialsMap.containskey(SerialsLegacytoNew.get(skeyLegacy)) ){
                                
                                newSerialObj=SerialsMap.get(SerialsLegacytoNew.get(skeyLegacy));
                                 subSerKey=asgSer.Subscription__c!=null ?String.valueOf(asgSer.Subscription__c)+newSerialObj.id:asgSer.Subscription__c;
                        subSerKey=(asgSer.Asset__c!=null && asgSer.Subscription__c==null)?String.valueOf(asgSer.Asset__c)+newSerialObj.id:subSerKey;
                        subSerKey=(asgSer.Parent_Subscription__c!=null && asgSer.Subscription__c==null && asgSer.Asset__c==null )?String.valueOf(asgSer.Parent_Subscription__c)+newSerialObj.id:subSerKey;

                                
                                newAsg.Serial__c=newSerialObj.id;
                                newAsg.External_ID__c =newAsg.Parent_Subscription__c!=null?String.valueof(newAsg.Serial__c)+newAsg.Parent_Subscription__c+newAsg.Subscription__c: String.valueof(newAsg.Serial__c)+newAsg.Asset__c+newAsg.Subscription__c;
                                asgObjPresent=externalIdskeys.contains(newAsg.External_ID__c)?TRUE:FALSE;
                                 externalIdskeys.add(newAsg.External_ID__c);
                                
                            }
                      
                         if(subSerialkeys.Contains(subSerKey)){
                            asgObjPresent=TRUE;
                           
                        }
                           
                        if(asgObjPresent==FALSE){
                             
                            AssignSerialUpsert.add(newAsg);
							
                        }
                        
                        // AssignSerialUpsert
                        if(asgSer.Subscription__r.SBQQ__Product__c!=null){
                            subProducts.add(asgSer.Subscription__r.SBQQ__Product__c);
                        }
                        if(asgSer.Subscription__r.SBQQ__RequiredByProduct__r.Replacement_Product__c!=null){
                            subProducts.add(asgSer.Subscription__r.SBQQ__RequiredByProduct__r.Replacement_Product__c);
                        }
                        
                    }
                    
                    if(!SerialsMap.containskey(NewSerial)){
                        SerialLatest.add(serial);
                    }
                }
                
            }
             
            for(SBQQ__ProductOption__c po: [SELECT id,SBQQ__ConfiguredSKU__c,SBQQ__ConfiguredSKU__r.SBCF_Product_Model__c,SBQQ__OptionalSKU__c,SBQQ__Type__c,SBQQ__Feature__c FROM SBQQ__ProductOption__c WHERE  SBQQ__OptionalSKU__c IN:subProducts AND SBQQ__ConfiguredSKU__c IN : subProducts ]){
                
                POMap.put(String.valueof(po.SBQQ__OptionalSKU__c)+po.SBQQ__ConfiguredSKU__c,po);
             }
            
            List<Asset> AssetUpdate= [SELECT id,SerialNumber,SBCF_Serial_Number__c,BNCPQ_Serial__c FROM Asset WHERE BNCPQ_Serial__r.Serial_Number__c IN :SerialsLegacytoNew.keyset() OR Id IN: parentIds ];
            
            
            for(SBQQ__Subscription__c Sub :[SELECT id,SBQQ__RequiredByProduct__r.Replacement_Product__c,SBQQ__RequiredByProduct__r.Replacement_Product__r.name,SBQQ__RequiredByProduct__r.Replacement_Product__r.SBCF_Product_Model__c,SBCF_Serial_Number__c,SBQQ__RootId__c,SBQQ__Product__c,Product_Code__c,SBQQ__ProductOption__c,SBQQ__OptionLevel__c,SBQQ__OptionType__c,Universal_OrderItem_Id__c,Universal_Order_Id__c FROM SBQQ__Subscription__c WHERE Id IN :parentIds]){
                for(String serKey:SerialsLegacytoNew.keyset()){
                    if(Sub.SBCF_Serial_Number__c!=null && sub.SBCF_Serial_Number__c.contains(serkey)){
                            Sub.SBCF_Serial_Number__c =  Sub.SBCF_Serial_Number__c.contains(',')?Sub.SBCF_Serial_Number__c.replace(serkey,NewSerial):NewSerial;

                    }
                        
                        if(Sub.SBCF_Serial_Number__c==null){
                            Sub.SBCF_Serial_Number__c=NewSerial;
                         }
                        String poKey=String.valueof(sub.SBQQ__Product__c)+sub.SBQQ__RequiredByProduct__r.Replacement_Product__c;
                        system.debug('poKey================='+ poKey);  
                        if( ModelChange== TRUE && POMap.containskey(poKey)){
                              SBQQ__ProductOption__c PO =POMap.get(poKey);
                            if( Sub.SBQQ__RequiredByProduct__c!= PO.SBQQ__ConfiguredSKU__c || sub.SBQQ__ProductOption__c!=po.id){
                              
                                Sub.SBQQ__RequiredByProduct__c= PO.SBQQ__ConfiguredSKU__c;
                                Sub.SBQQ__DynamicOptionId__c= PO.SBQQ__Feature__c;
                                Sub.SBQQ__OptionType__c= PO.SBQQ__Type__c;
                                sub.SBQQ__OptionLevel__c =1;
                                sub.SBQQ__ProductOption__c=po.id;
                                
                                
                            }
                        }
                        SubUpdate.add(sub);
                    
                }
            }
            if(!SerialLatest.isEmpty() && !SerialLatest.isEmpty()){
                Serial__c serialClone = SerialLatest[0].clone(false, false, false, false);
                serialClone.Serial_Number__c=NewSerial;
                serialClone.Status__c='Active';
                serialClone.id=null;
                serialClone.Is_Terminated__c=false;
                serialClone.Last_Serial__c =oldSerial;
                serialClone.Base_Product_SKU__c= ModelChange==true?SerialLatest[0].Product__r.Replacement_Product__r.productcode: serialClone.Base_Product_SKU__c;
                
                serialClone.Product__c= ModelChange==true?SerialLatest[0].Product__r.Replacement_Product__c:SerialLatest[0].Product__c;
                 serialClone.Product__c=  serialClone.Product__c==null? AssetProductId:  serialClone.Product__c;
                serialClone.Base_Product_SKU__c=serialClone.Base_Product_SKU__c==null?AssetProductcode:serialClone.Base_Product_SKU__c;
                SerialListUpdate.add(serialClone);
                
            }
           
			system.debug('AssignSerialUpsert================='+AssignSerialUpsert);    
             
            //Upsert Serial
            if(!SerialListUpdate.isEmpty()){
                UPSERT SerialListUpdate;
               
                for(Serial__c ser:SerialListUpdate){
                    
                    for(Asset aset:UpdateAsset){
                        
                        if(ser.Serial_Number__c==aset.SBCF_Serial_Number__c){
                            aset.BNCPQ_Serial__c=ser.id;
                        }
                    }
                    for(Assigned_Serial__c  newAsgObj: AssignSerialUpsert ){
                       
                        if(ser.Serial_Number__c==NewSerial){
                            
                        if(newAsgObj.Serial__c==null  ){
                           
                            newAsgObj.Serial__c=ser.id;
                            newAsgObj.External_ID__c =newAsgObj.Parent_Subscription__c!=null?String.valueof(newAsgObj.Serial__c)+newAsgObj.Parent_Subscription__c+newAsgObj.Subscription__c: String.valueof(newAsgObj.Serial__c)+newAsgObj.Asset__c+newAsgObj.Subscription__c;
                            newAsgObj.External_ID__c=newAsgObj.External_ID__c.contains('null')? newAsgObj.External_ID__c.remove('null'):newAsgObj.External_ID__c;
                            
                            if(!externalIdskeys.contains(newAsgObj.External_ID__c)){                            
                              externalIdskeys.add(newAsgObj.External_ID__c);
                              AssignSerialUpsertFinal.add(newAsgObj);
                            
                                
                            }

                        }
                    }
                    }
                    
                }
                
            }
            
            system.debug('UpdateAsset===================='+UpdateAsset);
            //Update Asset
            if(!UpdateAsset.isEmpty()){
                UPSERT UpdateAsset;
            }
            system.debug('SubUpdate===================='+SubUpdate);
            //Update Subscription
            if(!SubUpdate.isEmpty()){
                UPDATE SubUpdate;
            }
            system.debug('AssignSerialUpsertFinal===================='+AssignSerialUpsertFinal);
            //Upsert Assign Serial
            if(!AssignSerialUpsert.isEmpty()){
                if(AssignSerialUpsertFinal.isEmpty()){
                    AssignSerialUpsertFinal.addAll(AssignSerialUpsert);
                    
                }
                UPSERT AssignSerialUpsertFinal;
            }
            //Update Status to Completed for Serial tracking object:Jumbled_Serial_Tracking__c
            UPDATE LegacySerialList;
            
        }Catch(Exception e){
            log.addExceptionLog(e);
            System.debug('Exception' +e.getMessage()+'occurred at'+e.getStackTraceString());
        }
    }
    
}