/**
* @author Yuli
* @date 11/08/2019
*
* @group DynamicBusinessRuleAction
* @group-content a relative path to a static html file that provides content about the group
*
* @description implementation of DynamicBusinessRuleAction interface to Subscription
* SFDC-9382: reparent renewed subs that are not part of co-term contracts (pulled in by using renew sub button in line editor) to the master renewal contract, detaching from their old contract. 
                This way the old contract only contains the subs that have not yet been renewed. 
            Also populate renewed by field in renewed sub
* SFDC-9859: populate Subscription End Date when created. needed to preserve sub end date when reparent sub to another contract
* SFDC-9975: move logics from Sub PB to trigger
* SFDC-10328: Update current quantity field and Display history of revisions
* SFDC-10538: Update number of revisions field
* SFDC-6311: Update Product Sales Group Owned field on account
* SFDC-13294: Added logic to determine Has SaaS products value on Contract
* SFDC-13091: Added logic to set RMA detected on Contract
* SFDC-15852 : Automatically trigger Auto-Renew for all Core Contracts with only an End User
* SFDC-17001 : SFDC Event to Mulesoft to update End Dates in BOS based on Fulfillment Date
*/
public class DynamicBusinessRuleSubscription implements DynamicBusinessRuleAction {
    public void processRecords(Map<Id,SObject> newRecordMap, Map<Id,SObject> oldRecordMap, List <SObject> records, String jsonParameter, String triggerOrder, String triggerContext) {
        if (triggerOrder == 'POST') { 
            if (triggerContext.contains('Insert')) {
                updateRenewedSubscriptions(records);
                updateAmendedSubscriptions(records, oldRecordMap);
                updateAccountPSGOwned(records, oldRecordMap);                
                
            }
            if (triggerContext.contains('Update')) {
                updateAmendedSubscriptions(records, oldRecordMap);
                updateAccountPSGOwned(records, oldRecordMap);
              
            }
            if(triggerContext.contains('Insert') || triggerContext.contains('Update')){
                postInsertORUpdateNotifyPEOnSubscription(newRecordMap, oldRecordMap, records, jsonParameter, triggerOrder, triggerContext);
                identifyContractsToUpdate(records, oldRecordMap, triggerContext);
                updateAREligibeContracts(records,oldRecordMap,triggerContext);             
                sendPEEnddateUpdate(records, oldRecordMap,triggerContext);
            }
        }

        if (triggerOrder == 'PRE') {
            if (triggerContext.contains('Insert')) {
                updateSubEndDate(records);
                updateARFlag(records);
                //updateReleventOrderFields(records, oldRecordMap);
            }
            //if (triggerContext.contains('Update')) {
            //    updateReleventOrderFields(records, oldRecordMap);
            //}
        }
    }

   // SFDC-15852

      private static void updateAREligibeContracts(List<SObject> records, Map<Id,SObject> oldRecordMap, String triggerContext)
      {
        System.Debug('updateAREligibeContracts');
        Set<Id> contractIds = new Set<Id>();
        Set<Id> cEndTermDateIds = new Set<Id>();
       
        for (SBQQ__Subscription__c record : (List<SBQQ__Subscription__c>)records) {

        if(triggerContext.contains('Update'))
        {
         SObject oldRecord = oldRecordMap.get((Id)record.get('Id'));
        
         if(oldRecord!=null){
           
             if(((record.get('SBQQ__Quantity__c')!=oldRecord.get('SBQQ__Quantity__c')) || System.isBatch())          
                  && !String.isEmpty(record.SBQQ__Contract__c)){
                    
                    contractIds.add(record.SBQQ__Contract__c);
            }

            if(((record.get('SBQQ__TerminatedDate__c')!=oldRecord.get('SBQQ__TerminatedDate__c')) || System.isBatch()  //// SFDC-15686
            || (record.get('SBQQ__EndDate__c')!=oldRecord.get('SBQQ__EndDate__c')))  // SFDC-15686
            && !String.isEmpty(record.SBQQ__Contract__c)){
                   
                cEndTermDateIds.add(record.SBQQ__Contract__c);
           }
          }
         }
         else if(triggerContext.contains('Insert'))
         {
            if (!String.isEmpty(record.SBQQ__Contract__c))
            contractIds.add(record.SBQQ__Contract__c);
         }
              
        }

        contractIds.addAll(cEndTermDateIds);

        System.debug('contractIds::'+ contractIds);

        if(contractIds!=null && !contractIds.isEmpty())
        updateAllSubsRMAContracts(contractIds);      

      }      

      private static void updateAllSubsRMAContracts(Set<Id> contractIds)
      {
        Map<Id,List<SBQQ__Subscription__c>> consubMap = new Map<Id,List<SBQQ__Subscription__c>>();
        Map<String,Decimal> prodQuantityMap=new Map<String,Decimal>();
        Map<Id,Boolean> conOldAllSubRMA=new Map<Id,Boolean>();
        Set<String> prodName=new Set<String>();
        Decimal subqty=0;
        Boolean isAllRMA=true;
        List<SBQQ__Subscription__c> subProd=new List<SBQQ__Subscription__c>();
        List<Contract> contractstoUpdate=new List<Contract>();      

        LogModel log = LogModel.startLog('DynamicBusinessRuleSubcription',
        'updateAREligibeContracts');    

        try {         

        for( SBQQ__Subscription__c s :[Select Id,SBQQ__Contract__c,SBQQ__Contract__r.All_Subs_RMA__c, Product_Code__c ,SBQQ__Quantity__c from SBQQ__Subscription__c where 
                                       SBQQ__Contract__c in :contractIds]) {
       
            List<SBQQ__Subscription__c> sublst = consubMap.get(s.SBQQ__Contract__c);
            if(sublst == null)
               sublst = new List<SBQQ__Subscription__c>();
            sublst.add(s);

            consubMap.put(s.SBQQ__Contract__c,sublst);

            prodName.add(s.Product_Code__c );

            conOldAllSubRMA.put(s.SBQQ__Contract__c,s.SBQQ__Contract__r.All_Subs_RMA__c);
           
        }

        for(Id cId : consubMap.keySet()){ 

            for(String prod : prodName) {
        
                for (SBQQ__Subscription__c s : consubMap.get(cId)) {
                    if(prod==s.Product_Code__c ){
                        subqty=subqty+s.SBQQ__Quantity__c;
                    }
                }
                prodQuantityMap.put(prod, subqty);
                subqty=0;              
             }

            for(String p : prodQuantityMap.keySet()) {         
               if(prodQuantityMap.get(p)>0)
               {
                 isAllRMA=false;
                 break;
               }
             }

           if(isAllRMA && !conOldAllSubRMA.get(cId)) {
             contractstoUpdate.add (new Contract(Id=cId,All_Subs_RMA__c=true)); 
           }
           else if(!isAllRMA && conOldAllSubRMA.get(cId)){
            contractstoUpdate.add (new Contract(Id=cId,All_Subs_RMA__c=false)); 
           }
           else {
            contractstoUpdate.add (new Contract(Id=cId)); 
           }
        }

       System.debug(':prodQuantityMap.keySet:'+ prodQuantityMap.keySet());
       System.debug(':prodQuantityMap:'+ prodQuantityMap);
       System.debug(':isAllRMA:'+ isAllRMA);
         
       Set<Id> conIds=new Set<Id>();    
       Set<Id> contoUpdateIds=new Set<Id>();
       if((contractstoUpdate!=null && !contractstoUpdate.isEmpty()))
       {        
        Database.SaveResult[] srList = Database.update(contractstoUpdate, false);
        for(Database.SaveResult sr: srList){
            if(!sr.isSuccess()){
              String errorMessage =  'Error updating Contract ' + sr.getId() + ' : ';
              for(Database.Error error: sr.getErrors()){
                errorMessage += error.getMessage();
              }
              log.addLog(errorMessage);
            }
            else{
              log.addLog('Contract updated: ' + sr.getId());
              System.debug(':contractstoUpdate:'+ contractstoUpdate);             
            }
          }
        }      

        if((contractIds!=null && !contractIds.isEmpty()))
          {
              for(Contract con :[Select Id,Business_Group__c,Region__c,Theater__c,Reseller__c,Distributor__c,All_Subs_RMA__c,
                                 Account.RecordType.DeveloperName,Auto_Renewal_Status_Core__c
                                 from Contract where Id in : contractIds]) {
                            
                                  if(con.Business_Group__c=='Core' && con.Theater__c=='AMERICAS' && con.Region__c!='LATAM - REGION'
                                     && con.Account.RecordType.DeveloperName=='Customer' && con.Reseller__c==null
                                     && con.Distributor__c==null && con.All_Subs_RMA__c==false 
                                     && con.Auto_Renewal_Status_Core__c!='Included - Automatically')
                                     {                                      
                                      con.Auto_Renewal_Status_Core__c='Included - Automatically';
                                      contoUpdateIds.add(con.Id);  
                                     }
                            }
          }       

       if((contoUpdateIds!=null && !contoUpdateIds.isEmpty()))
          updateContractARStatusCoreFieldFuture(contoUpdateIds);

           // SFDC-15686
        if((contractstoUpdate!=null && contractstoUpdate.size()>0))
        {               
            updateContracts(contractstoUpdate, null);
        }
         // SFDC-15686 

      }
      catch(DmlException de){
            log.addExceptionLog(de);
          }
          catch(Exception ex){
            log.addExceptionLog(ex);
          }
      }

      public static void updateContracts(List<SObject> records, Map<Id,SObject> oldRecordMap){

        System.debug('updateContracts');
        List<Contract>   cIds = new List<Contract>();
        List<VContract>  VCons = new List<VContract>();
        
        for (Contract c : (List<Contract>)records){
            Contract cOld = oldRecordMap == null ? new Contract() : (Contract)oldRecordMap.get(c.Id);
            if (cOld == null)
              cOld = new Contract();
            cIds.add(c);
        }

        List<VContract> listVContract=new List<Vcontract>();
        List<VSubscription> listVSubscription=new List<VSubscription>();
        
         for(Contract c : [Select Id, name , Business_Group__c,All_Subs_RMA__c,Status, ( Select Id , Active__c,SBQQ__TerminatedDate__c,SBQQ__EndDate__c,SBQQ__Quantity__c
          from SBQQ__Subscriptions__r ) from contract where Id in :cIds]) {
                   
          VContract vc= new VContract();
          vc.con=c;
          vc.AllSubsRMA=c.All_Subs_RMA__c;
          vc.AllSubsInactive=false;
          vc.subs=new List<VSubscription>();
          vc.BusinessGroup=c.Business_Group__c;
                    
          for(SBQQ__Subscription__c sb: c.SBQQ__Subscriptions__r){
            VSubscription vs=new VSubscription();        
            vs.sub=sb;               
            vs.subActive=false;      
            vc.subs.add(vs);                                
         }           
         
          listVContract.add(vc);                   
        }
             
        Boolean flagAllSubsInActive = true;

        for(VContract vCon : listVContract) {

         for(VSubscription vSub : vCon.subs) {

            if(vSub.sub.SBQQ__TerminatedDate__c>=Date.today())
               // vSub.subActive=false;  // As in the Tech Design , but from the Active__c formula on Subscription it see,s it should be true
               vSub.subActive=true;
            if(vSub.sub.SBQQ__TerminatedDate__c==null && vSub.sub.SBQQ__EndDate__c>Date.today())
              //  vSub.subActive=false;
                 vSub.subActive=true;
            if(vSub.sub.SBQQ__Quantity__c==null)
                vSub.subActive=false;

            if( vSub.subActive) 
                 flagAllSubsInActive=false;           
         }

         System.debug('flagAllSubsInActive::'+ flagAllSubsInActive);

         if(!flagAllSubsInActive)
            vCon.AllSubsInactive=false;
         else 
           vCon.AllSubsInactive=true;
        }

        for(VContract vCon : listVContract) {

          if (vCon.AllSubsRMA==false && vCon.AllSubsInactive==false)
              vCon.con.Status='Activated';
          else if(vCon.AllSubsRMA==false && vCon.AllSubsInactive==true)
              vCon.con.Status='InActive';
          else if(vCon.AllSubsRMA==true && vCon.AllSubsInactive==true)
              vCon.con.Status='InActive';
          else if(vCon.AllSubsRMA==true && vCon.AllSubsInactive==false)
              vCon.con.Status='InActive';

              System.debug('vCon.con.Status::' + vCon.con.Status);
        }        
              
        List<Contract> contoUpdate=new List<Contract>();
        for (Contract c : (List<Contract>)records){
         
            for(VContract vCon : listVContract) {           
             if((c.Id==vCon.con.Id) && (vCon.BusinessGroup=='Core')) {

                c.Status=vCon.con.Status;
                contoUpdate.add(c);
                break;
             }
            }
        }      
        
       // update contoUpdate;

        if((contoUpdate!=null && !contoUpdate.isEmpty()))
        {        
         Database.SaveResult[] srList = Database.update(contoUpdate, false);
         for(Database.SaveResult sr: srList){
             if(!sr.isSuccess()){
               String errorMessage =  'Error updating Contract ' + sr.getId() + ' : ';
               for(Database.Error error: sr.getErrors()){
                 errorMessage += error.getMessage();
               }

               System.debug(':errorMessage:'+ errorMessage); 
             }
             else{
           
               System.debug(':contractstoUpdate:'+ contoUpdate);             
             }
           }
         }
    } 
          
     // @future // Can we do future here for Trigger and synchronous for Batch Job
      private static void updateContractARStatusCoreFieldFuture(Set<Id> contractstoUpdateIds)
      {
        List<Contract> contractstoUpdate=new List<Contract>();

        LogModel log = LogModel.startLog('DynamicBusinessRuleSubscription','updateContractARStatusCoreFieldFuture');
        
        try{

        for(Id conId: contractstoUpdateIds){           
                contractstoUpdate.add(new Contract(Id = conId,
                                                   Auto_Renewal_Status_Core__c = 'Included - Automatically')); 
                                            }

        Database.SaveResult[] srList = Database.update(contractstoUpdate, false);
        for(Database.SaveResult sr: srList){
            if(!sr.isSuccess()){
              String errorMessage =  'Error updating Contract ' + sr.getId() + ' : ';
              for(Database.Error error: sr.getErrors()){
                errorMessage += error.getMessage();
              }
              log.addLog(errorMessage);
            }
            else{
              log.addLog('Contract updated: ' + sr.getId());
            }
          }
          log.endLog('End of method for updating Core AR Eligible Contracts');

        }
        catch(DmlException de){
            log.addExceptionLog(de);
          }
          catch(Exception ex){
            log.addExceptionLog(ex);
          }

      }
      

   // SFDC-15852

    //SFDC-9382
    private static void updateRenewedSubscriptions(List<SObject> records) {
        //collect through related quote line of subscription
        Set<String> qlIds = new Set<String>();
        for (SBQQ__Subscription__c s : (List<SBQQ__Subscription__c>)records) {
            if (!String.isEmpty(s.SBQQ__QuoteLine__c))
                qlIds.add(s.SBQQ__QuoteLine__c);
        }

        if (qlIds.isEmpty()) 
            return;

        //SBQQ__RenewedSubscription__c on the related quote line is the subscription renewed by current subscription
        //Also reparent current sub to the related quote line's SBQQ__Quote__r.SBQQ__Opportunity2__r.SBQQ__RenewedContract__c, 
        //if current sub's contract is not one of co-termed contracts of the related quote line's SBQQ__Quote__r.SBQQ__Opportunity2__c
        Map<String, SBQQ__QuoteLine__c> quotelines = new Map<String, SBQQ__QuoteLine__c>([SELECT ID, SBQQ__RenewedSubscription__c, 
                                                                                            SBQQ__Quote__c, 
                                                                                            SBQQ__Quote__r.SBQQ__Opportunity2__c, 
                                                                                            SBQQ__Quote__r.SBQQ__Opportunity2__r.SBQQ__RenewedContract__c 
                                                                                        FROM SBQQ__QuoteLine__c 
                                                                                        WHERE Id in: qlIds]);
        
        //collect co-termed contracts of SBQQ__Quote__r.SBQQ__Opportunity2__c
        Set<String> opptyIds = new Set<String>();
        for (SBQQ__QuoteLine__c ql : quotelines.values()) {
            if (!String.isEmpty(ql.SBQQ__Quote__r.SBQQ__Opportunity2__c))
                opptyIds.add(ql.SBQQ__Quote__r.SBQQ__Opportunity2__c);
        }

        Map<String, Set<String>> contractsByOppty = new Map<String, Set<String>>();
        if (!opptyIds.isEmpty()) {
            for (Contract c : [Select ID, SBQQ__RenewalOpportunity__c From Contract Where SBQQ__RenewalOpportunity__c in: opptyIds]) {
                Set<String> cIds = contractsByOppty.get(c.SBQQ__RenewalOpportunity__c);
                if (cIds == null) {
                    cIds = new Set<String>();
                    contractsByOppty.put(c.SBQQ__RenewalOpportunity__c, cIds);
                }

                cIds.add(c.Id);
            }
        }
        
        Map<String, SBQQ__Subscription__c> subsToUpdate = new Map<String, SBQQ__Subscription__c>();

        for (SBQQ__Subscription__c s : (List<SBQQ__Subscription__c>)records) {
            if (!String.isEmpty(s.SBQQ__QuoteLine__c)) {
                SBQQ__QuoteLine__c ql = quotelines.get(s.SBQQ__QuoteLine__c);

                if (String.isEmpty(ql.SBQQ__RenewedSubscription__c)) 
                    continue;

                SBQQ__Subscription__c sub = new SBQQ__Subscription__c(ID = ql.SBQQ__RenewedSubscription__c, Renewed_By_Subscription__c = s.Id);
                subsToUpdate.put(sub.Id, sub);
                
                if (!String.isEmpty(ql.SBQQ__Quote__r.SBQQ__Opportunity2__c)) {
                    Set<String> cIds = contractsByOppty.get(ql.SBQQ__Quote__r.SBQQ__Opportunity2__c);

                    if(cIds == null || !cIds.contains(s.SBQQ__Contract__c))
                        sub.SBQQ__Contract__c = ql.SBQQ__Quote__r.SBQQ__Opportunity2__r.SBQQ__RenewedContract__c;
                }
            }
        }

        if (subsToUpdate.size() > 0)
            update subsToUpdate.values();
    }

    private static void postInsertORUpdateNotifyPEOnSubscription(Map<Id,SObject> newRecordMap, Map<Id,SObject> oldRecordMap, List <SObject> records, String jsonParameter, String triggerOrder, String triggerContext){
        //new PlatformEventHelper().processRecords(newRecordMap, oldRecordMap, records, jsonParameter, triggerOrder, triggerContext);
        
    }
    
    //SFDC-9859
    private static void updateSubEndDate(List<SObject> records) {
        Set<String> contractIds = new Set<String>();
        for (SBQQ__Subscription__c s : (List<SBQQ__Subscription__c>)records) {
            if (!String.isEmpty(s.SBQQ__Contract__c) && s.SBQQ__SubscriptionEndDate__c == null)
                contractIds.add(s.SBQQ__Contract__c);
        }

        if (!contractIds.isEmpty()) {
            Map<String, Contract> contracts = new Map<String, Contract>([SELECT ID, EndDate, Business_Group__c FROM Contract WHERE Id in: contractIds and Business_Group__c = 'Core']);

            for (SBQQ__Subscription__c s : (List<SBQQ__Subscription__c>)records) {
                if (!String.isEmpty(s.SBQQ__Contract__c) && s.SBQQ__SubscriptionEndDate__c == null) {
                    Contract c = contracts.get(s.SBQQ__Contract__c);
                    if (c != null)
                        s.SBQQ__SubscriptionEndDate__c = c.EndDate;
                }
            }
        }
    }
    
    private void updateARFlag(List<SObject> records){

        Set<String> qlIds = new Set<String>();
        for (SBQQ__Subscription__c s : (List<SBQQ__Subscription__c>)records) {
            if (!String.isEmpty(s.SBQQ__QuoteLine__c))
                qlIds.add(s.SBQQ__QuoteLine__c);
        }

        if (qlIds.isEmpty()) 
            return;

        Map<String, SBQQ__QuoteLine__c> qlMap = new Map<String, SBQQ__QuoteLine__c>([Select id,SBQQ__Quote__r.SBQQ__Opportunity2__r.Auto_Renewal_Eligible_Core__c from SBQQ__QuoteLine__c 
        WHERE Id in: qlIds]);

        for (SBQQ__Subscription__c s : (List<SBQQ__Subscription__c>)records) {
            if (!String.isEmpty(s.SBQQ__QuoteLine__c)) {
                  SBQQ__QuoteLine__c ql = qlMap.get(s.SBQQ__QuoteLine__c);
                  
                  if (!String.isEmpty(ql.SBQQ__Quote__r.SBQQ__Opportunity2__c)) {
                   s.Auto_Renewal_Flag__c = ql.SBQQ__Quote__r.SBQQ__Opportunity2__r.Auto_Renewal_Eligible_Core__c;
                  }
               
                }            
        }
    } 

    /*SFDC-9975 
    public static void updateReleventOrderFields(List<SObject> records, Map<Id,SObject> oldRecordMap) {
        List<SBQQ__Subscription__c> candidates = new List<SBQQ__Subscription__c>();
        Set<String> contractIds = new Set<String>();
        Set<String> quoteLineIds = new Set<String>();
        Set<String> orderItemIds = new Set<String>();

        for (SBQQ__Subscription__c s : (List<SBQQ__Subscription__c>)records){
            SBQQ__Subscription__c sold = oldRecordMap == null ? new SBQQ__Subscription__c() : (SBQQ__Subscription__c)oldRecordMap.get(s.Id);
            if (sold == null)
                sold = new SBQQ__Subscription__c();
            
            if (s.SBQQ__OrderProduct__c != null && 
                    (s.Original_Order_Number__c == null ||
                    s.SBQQ__OrderProduct__c != sold.SBQQ__OrderProduct__c ||
                    s.SBQQ__Contract__c != sold.SBQQ__Contract__c ||
                    s.SBQQ__QuoteLine__c != sold.SBQQ__QuoteLine__c)) {
                
                if (s.Original_Order_Number__c != null && !String.isEmpty(s.SBQQ__Contract__c))
                    contractIds.add(s.SBQQ__Contract__c);

                if (s.Original_Order_Number__c != null && !String.isEmpty(s.SBQQ__QuoteLine__c))
                    quoteLineIds.add(s.SBQQ__QuoteLine__c);
                
                orderItemIds.add(s.SBQQ__OrderProduct__c);
                candidates.add(s);
            }
        }

        if (candidates.isEmpty()) 
            return;

        Map<String, OrderItem> orderProducts = new Map<String, OrderItem>([SELECT ID, OrderId, Order.OrderNumber FROM OrderItem WHERE Id in: orderItemIds]);

        Map<String, Contract> contracts;
        Map<String, SBQQ__QuoteLine__c> quoteLines;
        if (!contractIds.isEmpty())
            contracts = new Map<String, Contract>([SELECT ID, SBQQ__Quote__c, SBQQ__Quote__r.SBQQ__Type__c FROM Contract WHERE Id in: contractIds and SBQQ__Quote__r.SBQQ__Type__c = 'Renewal']);
        if (!quoteLineIds.isEmpty())
            quoteLines = new Map<String, SBQQ__QuoteLine__c>([SELECT ID, SBQQ__Quote__c, SBQQ__Quote__r.SBQQ__Type__c FROM SBQQ__QuoteLine__c WHERE Id in: quoteLineIds and SBQQ__Quote__r.SBQQ__Type__c = 'Renewal']);
        
        for (SBQQ__Subscription__c s : candidates){
            OrderItem oi = orderProducts.get(s.SBQQ__OrderProduct__c);
            
            if (oi != null) {
                s.Related_Order__c = oi.OrderId;

                Boolean isRenewal = s.Original_Order_Number__c == null;
                if (isRenewal == false && !String.isEmpty(s.SBQQ__Contract__c)) {
                    Contract contract = contracts.get(s.SBQQ__Contract__c);
                    if (contract != null)
                        isRenewal = true;
                }

                if (isRenewal == false && !String.isEmpty(s.SBQQ__QuoteLine__c)) {
                    SBQQ__QuoteLine__c quoteLine = quoteLines.get(s.SBQQ__QuoteLine__c);
                    if (quoteLine != null)
                        isRenewal = true;
                }

                if (isRenewal == true) {
                    s.Original_OrderItem_Id__c = oi.Id;
                    s.Original_Order_Id__c = oi.OrderId;
                    s.Original_Order_Number__c = oi.Order.OrderNumber;
                }
            }
        }
    }
    */
    //SFDC-10328, SFDC-10538
    public static void updateAmendedSubscriptions(List <SObject> records, Map<Id,SObject> oldRecordMap) {
        Set<String> subIds = new Set<String>();

        for (SBQQ__Subscription__c s : (List<SBQQ__Subscription__c>)records){
            SBQQ__Subscription__c sold = oldRecordMap == null ? new SBQQ__Subscription__c() : (SBQQ__Subscription__c)oldRecordMap.get(s.Id);
            if (sold == null)
                sold = new SBQQ__Subscription__c();
                
            if (s.SBQQ__QuoteLine__c != sold.SBQQ__QuoteLine__c || 
                    s.SBQQ__RevisedSubscription__c != sold.SBQQ__RevisedSubscription__c || 
                    s.SBQQ__Quantity__c != sold.SBQQ__Quantity__c || 
                    s.New_Monthly_Total__c != sold.New_Monthly_Total__c || 
                    s.ExtendedMonthlyPrice__c != sold.ExtendedMonthlyPrice__c) {
                subIds.add(s.Id);
            }
        }

        if (subIds.isEmpty())
            return;
        
        for (SBQQ__Subscription__c s : [SELECT SBQQ__RevisedSubscription__c FROM SBQQ__Subscription__c WHERE Id in: subIds]) {
            if (s.SBQQ__RevisedSubscription__c <> NULL)
                subIds.add(s.SBQQ__RevisedSubscription__c);
        }

        List<SBQQ__Subscription__c> subs = [SELECT ID, Name, 
                                                SBQQ__ProductName__c, 
                                                SBQQ__Quantity__c, 
                                                OverageRate__c, 
                                                SBQQ__StartDate__c,
                                                Monthly_Unit_Price__c, 
                                                ExtendedMonthlyPrice__c, //twined from quote line; New_Monthly_Total__c * SBQQ__EffectiveQuantity__c
                                                SBQQ__EndDate__c, 
                                                SBQQ__ListPrice__c, 
                                                SBCF_Serial_Number__c,
                                                SBQQ__RevisedSubscription__c,
                                                SBQQ__RevisedSubscription__r.SBQQ__Quantity__c,
                                                SBQQ__RevisedSubscription__r.ExtendedMonthlyPrice__c,
                                                SBQQ__QuoteLine__c,
                                                SBQQ__QuoteLine__r.SBQQ__Bundled__c,
                                                SBQQ__QuoteLine__r.SBQQ__RenewedSubscription__c,
                                                SBQQ__QuoteLine__r.SBQQ__RenewedSubscription__r.SBQQ__RevisedSubscription__c,
                                                SBQQ__TerminatedDate__c,
                                                CurrencyISOCode,
                                                Revision_History__c,
                                                Current_Quantity__c,
                                                CreatedDate,
                                                Business_Group__c,
                                                SBQQ__RenewalQuantity__c,
                                                SBQQ__RenewalPrice__c,
                                                Number_of_Revisions__c
                                            FROM SBQQ__Subscription__c
                                            WHERE Id in: subIds or SBQQ__RevisedSubscription__c in: subIds
                                            Order By SBQQ__RevisedSubscription__c NULLS FIRST, CreatedDate];

        //collect master subs
        Map<String, SBQQ__Subscription__c> masterSubs = new Map<String, SBQQ__Subscription__c>();
        //collect subs that revised the master sub
        Map<String, List<SBQQ__Subscription__c>> revisionsByMaster = new Map<String, List<SBQQ__Subscription__c>>();

        for(SBQQ__Subscription__c sub : subs) {
            if (String.isEmpty(sub.SBQQ__RevisedSubscription__c)) {
                masterSubs.put(sub.Id, sub);
            } else {
                List<SBQQ__Subscription__c> revisions = revisionsByMaster.get(sub.SBQQ__RevisedSubscription__c);
                if (revisions == null) {
                    revisions = new List<SBQQ__Subscription__c>();
                    revisionsByMaster.put(sub.SBQQ__RevisedSubscription__c, revisions);
                }
                revisions.add(sub);
            }
        }

        Map<String, SBQQ__Subscription__c> subsToUpdate = new Map<String, SBQQ__Subscription__c>();
        for (String key : masterSubs.keySet()) {
            SBQQ__Subscription__c master = masterSubs.get(key);
            List<SBQQ__Subscription__c> revisions = revisionsByMaster.get(key);

            if (master != null) {
                Integer qty = master.SBQQ__Quantity__c == null ? 0 : Integer.valueOf(master.SBQQ__Quantity__c);
                Decimal ext = master.Business_Group__c == 'MSP' ? (master.ExtendedMonthlyPrice__c == null ? 0 : master.ExtendedMonthlyPrice__c) :
                                                                    ((master.SBQQ__RenewalPrice__c == null ? 0 : master.SBQQ__RenewalPrice__c) * (master.SBQQ__RenewalQuantity__c == null ? 0 : master.SBQQ__RenewalQuantity__c));
                String direction = '';
                //{0}: {1}{2} @{3} {4}. Current - Qty: {5}, Ext.: {6} {7}
                //master.CreatedDate.format() + ': ' + direction + qty + ' @ ' + master.CurrencyISOCode + ' ' + master.Monthly_Unit_Price__c + ' - Current Qty: ' + qty + ', Ext. ' + master.CurrencyISOCode + ' ' + master.ExtendedMonthlyPrice__c;
                String history = String.format(System.Label.CPQ_Subscription_Revision_History, new List<Object> {master.CreatedDate.format('MM/dd/yyyy'), 
                                                                                                                direction, 
                                                                                                                qty, 
                                                                                                                master.CurrencyISOCode, 
                                                                                                                master.Business_Group__c == 'MSP' ? (master.Monthly_Unit_Price__c == null ? 0 : master.Monthly_Unit_Price__c) : 
                                                                                                                                                    (master.SBQQ__RenewalPrice__c == null ? 0 : master.SBQQ__RenewalPrice__c), 
                                                                                                                qty, 
                                                                                                                master.CurrencyISOCode, 
                                                                                                                ext});

                if (revisions != null) {
                    for (SBQQ__Subscription__c sub : revisions) {
                        Integer revisionQty = sub.SBQQ__Quantity__c == null ? 0 :  Integer.valueOf(sub.SBQQ__Quantity__c);
                        Decimal revisionExt = master.Business_Group__c == 'MSP' ? (sub.ExtendedMonthlyPrice__c == null ? 0 :  sub.ExtendedMonthlyPrice__c) :
                                                                                    ((sub.SBQQ__RenewalPrice__c == null ? 0 : sub.SBQQ__RenewalPrice__c) * (sub.SBQQ__RenewalQuantity__c == null ? 0 : sub.SBQQ__RenewalQuantity__c));
                        qty = qty + revisionQty;
                        ext = ext + revisionExt;
                        
                        String revisionDirection = revisionQty == 0 ? '' : (revisionQty > 0 ? '↑' : '↓');
                        history = history + '\n' + String.format(System.Label.CPQ_Subscription_Revision_History, new List<Object> {sub.CreatedDate.format('MM/dd/yyyy'), 
                                                                                                                                revisionDirection, 
                                                                                                                                Math.abs(revisionQty), 
                                                                                                                                sub.CurrencyISOCode, 
                                                                                                                                master.Business_Group__c == 'MSP' ? (sub.Monthly_Unit_Price__c == null ? 0 : sub.Monthly_Unit_Price__c) : 
                                                                                                                                                                    (sub.SBQQ__RenewalPrice__c == null ? 0 : sub.SBQQ__RenewalPrice__c), 
                                                                                                                                qty, 
                                                                                                                                sub.CurrencyISOCode, 
                                                                                                                                ext});
                    }
                    
                    if (master.Number_of_Revisions__c != revisions.size()) {
                        master.Number_of_Revisions__c = revisions.size();
                        subsToUpdate.put(master.Id, master);
                    }
                }    

                if (master.Current_Quantity__c != qty) {
                    master.Current_Quantity__c = qty;
                    subsToUpdate.put(master.Id, master);
                }

                if (Test.isRunningTest() == true || (/*master.Business_Group__c == 'MSP' && */master.Revision_History__c != history)) {
                    master.Revision_History__c = history;
                    subsToUpdate.put(master.Id, master);
                }
            }
        }
        System.Debug('*** subsToUpdate ' + subsToUpdate);
        
        if (subsToUpdate.size() > 0) {
            update subsToUpdate.values();
        }
    }
    
    //SFDC-6311: Update Product Sales Group Owned field on account
    private static void updateAccountPSGOwned(List<SObject> records, Map<Id,SObject> oldRecordMap) {
        System.Debug('updateAccountPSGOwned');
        Set<String> accountIds = new Set<String>();
        for (SBQQ__Subscription__c s : (List<SBQQ__Subscription__c>)records){
            SBQQ__Subscription__c sold = oldRecordMap == null ? new SBQQ__Subscription__c() : (SBQQ__Subscription__c)oldRecordMap.get(s.Id);
            if (sold == null)
                sold = new SBQQ__Subscription__c();
                
            if (s.Business_Group__c == 'MSP' && 
                    !String.isEmpty(s.SBQQ__Account__c) && 
                    s.SBQQ__RevisedSubscription__c == null &&
                    (s.SBQQ__Account__c != sold.SBQQ__Account__c ||
                    s.SBQQ__RevisedSubscription__c != sold.SBQQ__RevisedSubscription__c ||
                    s.SBQQ__Product__c != sold.SBQQ__Product__c ||
                    s.SBQQ__TerminatedDate__c != sold.SBQQ__TerminatedDate__c)) {
                accountIds.add(s.SBQQ__Account__c);
            }
        }

        if (accountIds.isEmpty())
            return;
        
        Map<String, MSP_Product_Sales_Group_Code__mdt> psgCodes = new Map<String, MSP_Product_Sales_Group_Code__mdt>();
        for (MSP_Product_Sales_Group_Code__mdt p : [Select ID, DeveloperName, MasterLabel, Code__c From MSP_Product_Sales_Group_Code__mdt]) {
            psgCodes.put(p.MasterLabel, p);
        }

        //collect accounts that related to the sub
        Map<String, Account> accounts = new Map<String, Account>([SELECT ID, Product_Sales_Groups_Owned__c ,Type,MSP_Eligible_for_Unlimited_Promo__c
                                        FROM Account 
                                        WHERE Id in: accountIds]);

        //collect active subs by account
        Map<String, List<SBQQ__Subscription__c>> activeSubsByAccount = new Map<String, List<SBQQ__Subscription__c>>();
        /* for (SBQQ__Subscription__c sub : [SELECT ID, Name, 
                                            SBQQ__Account__c,
                                            SBQQ__Account__r.Id,
                                            SBQQ__Account__r.Product_Sales_Groups_Owned__c,
                                            SBQQ__Product__c,
                                            SBQQ__Product__r.Product_Sales_Grouping__c
                                        FROM SBQQ__Subscription__c
                                        WHERE SBQQ__Account__c in: accountIds and 
                                            Business_Group__c = 'MSP' and 
                                            SBQQ__Product__r.Product_Sales_Grouping__c in: psgCodes.keySet() and 
                                            SBQQ__RevisedSubscription__c = NULL and 
                                            (SBQQ__TerminatedDate__c = NULL or SBQQ__TerminatedDate__c > TODAY)])  */
                                            
          for (SBQQ__Subscription__c sub : [Select ID, Name, SBQQ__Account__c,
                                            SBQQ__Account__r.Id,
                                            SBQQ__Account__r.Product_Sales_Groups_Owned__c,
                                            SBQQ__Product__c,
                                            SBQQ__Product__r.Product_Sales_Grouping__c,
                                            SBQQ__QuoteLine__r.SBQQ__RenewedSubscription__c, 
                                            SBQQ__QuoteLine__r.SBQQ__RenewedSubscription__r.SBQQ__RevisedSubscription__c
                                            From  SBQQ__Subscription__c
                                            Where SBQQ__Account__c in: accountIds and Business_Group__c <> 'Core' and 
                                            SBQQ__RequiredById__c = NULL and 
                                            (SBQQ__TerminatedDate__c = NULL or SBQQ__TerminatedDate__c > TODAY) and  
                                            SBQQ__RevisedSubscription__c = null and SBQQ__Contract__r.EndDate >= TODAY and 
                                            SBQQ__ProductOption__r.SBQQ__QuoteLineVisibility__c not in ('Editor Only','Never')
                                             and  
                                            SBQQ__Product__r.Product_Sales_Grouping__c in: psgCodes.keySet()]) {
                                             
                                            
            List<SBQQ__Subscription__c> subs = activeSubsByAccount.get(sub.SBQQ__Account__c);
            if (subs == null) {
                subs = new List<SBQQ__Subscription__c>();
                activeSubsByAccount.put(sub.SBQQ__Account__c, subs);
            }
            subs.add(sub);
        }

        Map<String, Account> acctsToUpdate = new Map<String, Account>();
        
        

        for (String acctId : accounts.keySet()) {
            Account acct = accounts.get(acctId);
            Set<String> psgsSetAccount = new Set<String>();
            if (acct.Product_Sales_Groups_Owned__c != null) {
                for (String psg : acct.Product_Sales_Groups_Owned__c.split(',')) {
                    psgsSetAccount.add(psg.trim());
                }
            }
            System.Debug('*** psgsSetAccount ' + psgsSetAccount);
            List<SBQQ__Subscription__c> subs = activeSubsByAccount.get(acctId);
            Set<String> psgsSetNew = new Set<String>();
            if (subs != null) {
                for (SBQQ__Subscription__c sub : subs) {
                    MSP_Product_Sales_Group_Code__mdt psg = psgCodes.get(sub.SBQQ__Product__r.Product_Sales_Grouping__c);
                    if (psg != null)
                        psgsSetNew.add(psg.Code__c);
                }
            }
            System.Debug('*** psgsSetNew ' + psgsSetNew);

            if (!psgsSetAccount.containsAll(psgsSetNew) || !psgsSetNew.containsAll(psgsSetAccount)) {
                acct.Product_Sales_Groups_Owned__c = String.join(new List<String>(psgsSetNew), ' ');
                acctsToUpdate.put(acctId, acct);
            }
        }

        if (acctsToUpdate.size() > 0)
            update acctsToUpdate.values();  
     
    }

    /**
     * Method to identify contracts that need Has Saas Product field updated
     * This is based on Is_SaaS_Subscription__c on SBQQ__Subscription__c object
     */
    public static void identifyContractsToUpdate(List<SObject> records, Map<Id,SObject> oldRecordMap, String triggerContext){

        //Contract Ids to be evaluated
        Set<String> contractIdSet = new Set<String>();

        //Loop through records
        for(SObject record: records){
            //if this is insert then get the contract Id
            if(triggerContext.contains('Insert') || 
               triggerContext.contains('Delete') || 
               triggerContext.contains('UnDelete')){
                contractIdSet.add('SAAS_' + String.valueOf(record.get('SBQQ__Contract__c')));
                contractIdSet.add('RMA_' + String.valueOf(record.get('SBQQ__Contract__c')));
            }
            else{
                SObject oldRecord = oldRecordMap.get((Id)record.get('Id'));
                //check if Is_SaaS_Subscription__c value changed
                if(oldRecord!=null){
                    //Contract on the Subscription changed
                    if(record.get('SBQQ__Contract__c')!=oldRecord.get('SBQQ__Contract__c')){
                        contractIdSet.add('SAAS_' + String.valueOf(record.get('SBQQ__Contract__c')));
                        contractIdSet.add('RMA_' + String.valueOf(record.get('SBQQ__Contract__c')));
                        //Since contract is added for both scenarios no need to check remaining conditions
                        continue;
                    }
                    
                    //Is_SaaS_Subscription__c on the subscription changed
                    if(record.get('Is_SaaS_Subscription__c')!=oldRecord.get('Is_SaaS_Subscription__c')){
                        contractIdSet.add('SAAS_' + String.valueOf(record.get('SBQQ__Contract__c')));
                    }

                    //Active flag or Terminated date changed
                    if(record.get('Active__c')!=oldRecord.get('Active__c') || 
                       record.get('SBQQ__TerminatedDate__c') != oldRecord.get('SBQQ__TerminatedDate__c')){
                        contractIdSet.add('RMA_' + String.valueOf(record.get('SBQQ__Contract__c')));
                    }                    
                }
            }
        }

        //If Contracts were found then call future method to update Contract
        if(contractIdSet!=null && !contractIdSet.isEmpty()){
          //updateContractHasSaaSProduct(contractIdSet);
          system.debug('No of queable job'+Limits.getQueueableJobs());
          //System.assertequals(1,2);
          if(Limits.getQueueableJobs()==0){
          System.enqueueJob(new UpdContractHasSaaSProductQueueable(contractIdSet));
          }
          system.debug('No of queable job**'+Limits.getQueueableJobs());
          system.debug('No of limit queable job'+Limits.getLimitQueueableJobs());
        }
    }

    

   public static void sendPEEnddateUpdate(List<SObject> records, Map<Id,SObject> oldRecordMap,String triggerContext){

    System.Debug('sendPEEnddateUpdate');
    Set<Id> subIds = new Set<Id>();
    List<Id> subIdList = new List<Id>();

    for (SBQQ__Subscription__c record : (List<SBQQ__Subscription__c>)records) {

        if(triggerContext.contains('Update')) {
            SObject oldRecord = oldRecordMap.get((Id)record.get('Id'));

            if(oldRecord!=null){
                if((record.get('SBQQ__SubscriptionEndDate__c')!=oldRecord.get('SBQQ__SubscriptionEndDate__c')))                
              {
                        subIds.add(record.Id);
              }
            }        
           
        }
        else if(triggerContext.contains('Insert')) {
               if(record.SBQQ__SubscriptionEndDate__c!=null )              
                    {
                        subIds.add(record.Id);               
                    }
        }
    }

    if(subIds!=null && !subIds.isEmpty())
        subIdList.addAll(subIds);
      
        sendPlatformEventtoMS(subIdList,true,triggerContext);
  }

  @AuraEnabled
  public static DynamicBusinessRuleSubscription.sendPlatformEventtoMSResult sendPlatformEventtoMS(List<Id> subIds,Boolean isFromTrigger,String triggerContext){

    //LogModel log = LogModel.startLog('DynamicBusinessRuleSubscription','sendPlatformEventtoMS');
    System.debug('subIds: '  + subIds);
    DynamicBusinessRuleSubscription.sendPlatformEventtoMSResult updateResult = new DynamicBusinessRuleSubscription.sendPlatformEventtoMSResult(); 
    updateResult.result  = true;  
    updateResult.message='';
    List<SBQQ__Subscription__c> subforPENotify=new List<SBQQ__Subscription__c>();   
    String toEmail;
    List<Configured_Email_Addresses__mdt> emails = [Select ID, DeveloperName, MasterLabel, Email__c From Configured_Email_Addresses__mdt];
    Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage>();      

    for (Configured_Email_Addresses__mdt email : emails) {
        if ((email.DeveloperName == 'Barracuda_Support_Email' && (email.Email__c!=null)) ) {
            try {
                toEmail = email.Email__c;
            } catch (Exception e) {}
        }
      }   

    try {        
        for( SBQQ__Subscription__c sub :[Select Id,Name,SBCF_Serial_Number__c ,
        SBQQ__OrderProduct__r.Serial_Available_For_Core__c ,SBQQ__SubscriptionEndDate__c,
        Business_Group__c, SBQQ__OrderProduct__r.Id from SBQQ__Subscription__c where 
        Id in :subIds]) {

        if(sub.SBQQ__SubscriptionEndDate__c!=null && string.isBlank(sub.SBCF_Serial_Number__c)
           && sub.SBQQ__OrderProduct__r.Serial_Available_For_Core__c && sub.Business_Group__c=='Core'){
               
                //log.addlog('SERIAL MISSING');
                updateResult.result =false;

               // Send Failure Mails
               if(String.isNotEmpty(triggerContext) && triggerContext.contains('Update')) // Send Serial Missing Emails only on Update Trigger
                 {
                      Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
                      String[] toAddresses = new String[] {toEmail}; 
                      message.setToAddresses(toAddresses);
                      message.setSenderDisplayName('Salesforce Support');
                      message.setSubject('Missing Serial Number');
                      message.setPlainTextBody('Missing Serial Number for Subcription : ' + sub.Name +' with Id :'+ sub.Id + ' is missing');
                
                      messages.add(message);         
                }
        }                

       if (sub.SBQQ__SubscriptionEndDate__c!=null  && sub.SBQQ__OrderProduct__r.Serial_Available_For_Core__c &&
           sub.Business_Group__c=='Core'){
            // Send PE             
            subforPENotify.add(sub);         
           } 
          // log.endLog();     
    }       

    try {                
        if(!Test.isRunningTest() && messages!=null && !messages.isEmpty()){
            Messaging.sendEmail(messages);
        }
        
     } catch (Exception e) {
        System.debug('**Error Message: ' + e.getMessage() + '\n LineNumber: ' + e.getLineNumber() + '\n Exception Type: ' + e.getTypeName() + '\n Cause: ' + e.getCause() + '\nStack Trace ' + e.getStackTraceString());                    
    }  

    if(subforPENotify!=null && !subforPENotify.isEmpty()) {
      
        new PlatformEventHelper().publishObject('UPDATE',subforPENotify);
    }

    } catch (Exception e) {
        updateResult.result =false;
        System.debug(e.getMessage());
       // log.endLog();
    }
    
    return updateResult; 
  }

  @AuraEnabled  
  public static  DynamicBusinessRuleSubscription.sendPlatformEventtoMSResult syncSubEnddatestoBOS(Id contractId){

    System.debug('contractId: '  + contractId);

    DynamicBusinessRuleSubscription.sendPlatformEventtoMSResult updateResult = new DynamicBusinessRuleSubscription.sendPlatformEventtoMSResult(); 
    updateResult.result  = true;  
    updateResult.message='';

    List<Id> subIdList = new List<Id>();
    for( SBQQ__Subscription__c sub :[Select Id,Name,SBCF_Serial_Number__c ,
        SBQQ__OrderProduct__r.Serial_Available_For_Core__c ,SBQQ__SubscriptionEndDate__c,
        Business_Group__c, SBQQ__OrderProduct__r.Id from SBQQ__Subscription__c where 
        SBQQ__Contract__c = :contractId]) {

            subIdList.add(sub.Id);

        }

        if(subIdList!=null && !subIdList.isEmpty())
         sendPlatformEventtoMS(subIdList,false,'');

         return updateResult; 
  }

  public class sendPlatformEventtoMSResult {
  
    @AuraEnabled
    public String message;
  
    @AuraEnabled
    public Boolean result;    
  }    

  public class VContract{

    public Contract con;
    public Boolean AllSubsRMA;
    public Boolean AllSubsInactive;
    public String BusinessGroup;
    public List<VSubscription> subs;
    }
    
    public class VSubscription{
    
    public SBQQ__Subscription__c sub;
    public Boolean subActive;
    }
}

 
/*
List<SBQQ__Subscription__c> testSubs = new List<SBQQ__Subscription__c> {
    new SBQQ__Subscription__c(SBQQ__Account__c = '001f200001venh1', SBQQ__Contract__c = '8000m000000RHj7', SBQQ__Quantity__c = 1, SBQQ__Product__c = '01tf2000008C5u8', SBQQ__TerminatedDate__c = (System.Today() - 1)), 
    new SBQQ__Subscription__c(SBQQ__Account__c = '001f200001vg0XI', SBQQ__Contract__c = '8000m0000002cnF', SBQQ__Quantity__c = 1, SBQQ__Product__c = '01tf2000008C70u') 
};
insert testSubs;
System.Debug('*** testSubs ' + testSubs);
delete testSubs;

List<SBQQ__Subscription__c> subs = [Select ID, Business_Group__c, SBQQ__Account__c From SBQQ__Subscription__c Where ID = 'a1k0m000000sq3tAAA'];
DynamicBusinessRuleSubscription.updateAccountPSGOwned(subs);
*/