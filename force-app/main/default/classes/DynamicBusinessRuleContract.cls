/**
* @author Yuli Fintescu
* @date 2019
*
* @group DynmaicBusinessRuleAction
*
* @description implementation of DynamicBusinessRuleAction interface to contract triggers
* Change: SFDC_14344: Changing Oppty name to Account Name - Upsell Oppty - Contract Number for upsell opportunity
*/
public class DynamicBusinessRuleContract implements DynamicBusinessRuleAction {
    public void processRecords(Map<Id,SObject> newRecordMap, Map<Id,SObject> oldRecordMap, List <SObject> records, String jsonParameter, String triggerOrder, String triggerContext) {
        if (triggerOrder == 'PRE') {
            checkMasterContract(newRecordMap, oldRecordMap);
            autoRenewPrimaryContact(records, oldRecordMap);
            checkRenewalEligible(records, oldRecordMap);     
       
         if(triggerContext.contains('Update'))
         {       
            checkDistributorRemoved(records,oldRecordMap);
         }
            /**
            * Added as part of SFDC-20558: START
			*/
            if(triggerContext.contains ('Insert')){
                assignACVToContract(records,oldRecordMap);
            }
            /**
            * Added as part of SFDC-20558: END
			*/
        } 
        
        if (triggerOrder == 'POST') {
           
            contractNaming(records, oldRecordMap);
            updateOrder(records, oldRecordMap);

            if(triggerContext.contains('Insert') || triggerContext.contains('Update')) {
                Map<Id, Contract> recordsToUpdate = new Map<Id, Contract>();
                List<Id> contractIds = new List<Id>();

                for (Contract c : (List<Contract>)records){
                    contractIds.add(c.Id);
                }

                List<Contract> contractRecords = [SELECT Id, 
                                                         Business_Group__c,
                                                         Distributor__c,
                                                         Auto_Renewal_Status_Core__c,
                                                         Auto_Renewal_Eligible_Core__c,                                                        
                                                         SBQQ__Order__c
                                                 FROM Contract 
                                                 WHERE Id IN : contractIds];    

           // if(triggerContext.contains('Insert') ) {
                recordsToUpdate.putAll(checkDistributorAddedAndSetAutoRenewal(contractRecords));
                
                if(!recordsToUpdate.isEmpty()) {
                    update recordsToUpdate.values();
                }
            }

            // Commented Based on discussion with Business  that Contract will never be updated manually to add a Distributor
             //  This means Distributor can only be added when a Contract is being created
             // This means there will never be an existing Renewal Opp , which needs to run through this logic

            // if(triggerContext.contains('Update')) {

            //   //  checkDistributorOnRenewalOpp(records,oldRecordMap);             
              
            //  }
        }
    } 

    private Map<Id, Contract> checkDistributorAddedAndSetAutoRenewal(List<Contract> records){
  
        System.debug('checkDistributorAdded');
        List<Id>  cIds = new List<Id>();
        Map<Id, Contract> contractsToUpdate = new Map<Id, Contract>();
        List<Id> orderIds = new List<Id>();
        
        for (Contract c : records){
            if(c.SBQQ__Order__c != null) {
                orderIds.add(c.SBQQ__Order__c);
            }
        }        

        Map<Id, Order> ordersMap = new Map<Id, Order>([SELECT Id, Portal_Placed_Order__c, Auto_Renewal_Flag__c FROM Order WHERE Id IN :orderIds]);

        for (Contract c : records){                                
            System.debug('Distributor__c::'+c.Distributor__c);
            System.debug('Auto_Renewal_Status_Core__c::'+c.Auto_Renewal_Status_Core__c);           

             Order orderRecord = ordersMap.get(c.SBQQ__Order__c);   

        if(c.Business_Group__c=='Core'  && c.Distributor__c!=null  &&  c.Auto_Renewal_Status_Core__c!='Excluded - Automatically' && c.Auto_Renewal_Eligible_Core__c)               
            {              
             
                c.Auto_Renewal_Status_Core__c='Excluded - Automatically';
                c.Auto_Renewal_Status_Reason_Core__c='Excluded - Distribution Deal';

                contractsToUpdate.put(c.Id, c);
         
           } else if(c.Auto_Renewal_Status_Core__c!='Excluded - Automatically' && c.Auto_Renewal_Status_Core__c!='Included - Automatically'  && orderRecord != null && orderRecord?.Portal_Placed_Order__c && orderRecord?.Auto_Renewal_Flag__c) {      
                
                c.Auto_Renewal_Status_Core__c='Included - Automatically';
                contractsToUpdate.put(c.Id, c);
            }
        }
        
        return contractsToUpdate;
    }    

    private void checkDistributorRemoved(List<SObject> records, Map<Id,SObject> oldRecordMap){
    
        System.debug('checkDistributorRemoved');
        List<Id>  cIds = new List<Id>();
        List<Contract>  contoUpdate = new List<Contract>();

        for (Contract c : (List<Contract>)records){
            Contract cOld = oldRecordMap == null ? new Contract() : (Contract)oldRecordMap.get(c.Id);
            if (cOld == null)
            cOld = new Contract();

            System.debug('Distributor__c::'+c.Distributor__c);
            System.debug('OldDistributor__c::'+cOld.Distributor__c);
            System.debug('Auto_Renewal_Status_Core__c::'+c.Auto_Renewal_Status_Core__c);
            System.debug('Auto_Renewal_Status_Core__c::'+c.Auto_Renewal_Status_Reason_Core__c);
            System.debug('SBQQ__ExpirationDate__c::'+c.SBQQ__ExpirationDate__c);

            Date coreExpDate   = Date.today().addDays(60);

            System.debug('coreExpDate::'+coreExpDate);

            if(c.SBQQ__ExpirationDate__c>coreExpDate)
               System.debug('SBQQ__ExpirationDate__c is True');

            if(c.Business_Group__c=='Core'  && (c.Distributor__c==null && cOld.Distributor__c!=null)  
               && (c.Auto_Renewal_Status_Core__c=='Excluded - Automatically' && c.Auto_Renewal_Status_Reason_Core__c=='Excluded - Distribution Deal')
               && (c.SBQQ__ExpirationDate__c>coreExpDate))
            {              
              
                System.debug('checkDistributorRemoved-cId::'+ c.Id);              
                c.Auto_Renewal_Status_Core__c= 'Included - Automatically';
                c.Auto_Renewal_Status_Reason_Core__c='Included - based on Account Flag';
            }        
        }          
    }   

    private static void checkRenewalEligible(List <SObject> records, Map<Id,SObject> oldRecordMap){
     
        Set<String> renOppsIds = new Set<String>();
        Set<String> accIds = new Set<String>();
        List<Contract>  cIds = new List<Contract>();
        Boolean hasCustomPermission = FeatureManagement.checkPermission('By_Pass_Renewal_and_Amendment_Opp_Validation');
         if(!hasCustomPermission) {

        for (Contract c : (List<Contract>)records){
            Contract cOld = oldRecordMap == null ? new Contract() : (Contract)oldRecordMap.get(c.Id);
            if (cOld == null)
            cOld = new Contract();
          // 
         
          System.debug('Current User Id - '+UserInfo.getUserId());
          System.debug('hasCustomPermission - '+hasCustomPermission);
          System.debug('SBQQ__RenewalOpportunity__c - '+c.SBQQ__RenewalOpportunity__c);
          System.debug('AccountId - '+c.AccountId);
         
         
          if(c.AccountId != null && c.SBQQ__RenewalOpportunity__c!=null && 
           ((c.SBQQ__RenewalQuoted__c == true && cOld.SBQQ__RenewalQuoted__c != c.SBQQ__RenewalQuoted__c) ||
          (c.SBQQ__RenewalForecast__c == true && cOld.SBQQ__RenewalForecast__c != c.SBQQ__RenewalForecast__c))){
           
           
            cIds.add(c);
            renOppsIds.add(c.SBQQ__RenewalOpportunity__c);
            accIds.add((c.AccountId));
          }
        }

        System.debug('cIds - '+cIds.size());
        System.debug('renOppsIds - '+renOppsIds.size());      

          if (cIds.size() > 0 && renOppsIds.size() > 0) {
            Map<String, Opportunity> renOpps = new Map<String, Opportunity>();
            for (Opportunity o : [Select ID, AccountId,StageName, Business_Group__c From Opportunity Where id in: renOppsIds ]) {
                if (!renOpps.containsKey(o.AccountId)) {
                    renOpps.put(o.AccountId, o);
                }
            }
            
            System.debug('renOpps - '+renOpps.size());

            for (Contract c : cIds) {
                Opportunity renOpp = renOpps.get(c.AccountId);
                System.debug('renOpp - '+renOpp);
                if (renOpp != null && renOpp.StageName=='Closed Won' && renOpp.Business_Group__c=='Core'
                     && c.RMA_Detected__c ==false) {
                    c.addError(System.Label.CPQAmend_Renew_Validation);
                }
                   
            }
          }
    }        
    }

    /*******************************************************************************************************
    * @description SFDC-10007 auto populate missing primary contact with primary contact of the latest oppty. auto renew only
    */
    private static void autoRenewPrimaryContact(List <SObject> records, Map<Id,SObject> oldRecordMap){
        List<Contract> candidates = new List<Contract>();

        Set<String> acctIds = new Set<String>();
        for (Contract c : (List<Contract>)records){
            Contract cOld = oldRecordMap == null ? new Contract() : (Contract)oldRecordMap.get(c.Id);
            if (cOld == null)
                cOld = new Contract();
            
            if (c.AccountId != null && c.Business_Group__c == 'Core' && c.Primary_Contact__c == null && 
                    ((c.SBQQ__RenewalQuoted__c == true && cOld.SBQQ__RenewalQuoted__c != c.SBQQ__RenewalQuoted__c) ||
                    (c.SBQQ__RenewalForecast__c == true && cOld.SBQQ__RenewalForecast__c != c.SBQQ__RenewalForecast__c))) {
                candidates.add(c);
                acctIds.add(c.AccountId);
            }
        }

        if (candidates.size() > 0 && acctIds.size() > 0) {
            Map<String, Opportunity> latestOpps = new Map<String, Opportunity>();

            for (Opportunity o : [Select ID, AccountId, Primary_Contact__c From Opportunity Where AccountId in: acctIds and Primary_Contact__c <> NULL Order By CreatedDate DESC]) {
                if (!latestOpps.containsKey(o.AccountId)) {
                    latestOpps.put(o.AccountId, o);
                }
            }

            for (Contract o : candidates) {
                Opportunity latestOpp = latestOpps.get(o.AccountId);
                if (latestOpp != null)
                    o.Primary_Contact__c = latestOpp.Primary_Contact__c;
            }
        }
    }

    /*******************************************************************************************************
    * @description check SBQQ__MasterContract__c on contract if the contract is Opp's SBQQ__RenewedContract__c
    * @param trigger.new map
    * @return none, the result should be set to the records itself
    * @example
    */
    private static void checkMasterContract(Map<Id,SObject> newRecordMap, Map<Id,SObject> oldRecordMap){
        Set<String> opptyIds = new Set<String>();
        for (Contract c : (List<Contract>)newRecordMap.values()){
            Contract cOld = oldRecordMap == null ? new Contract() : (Contract)oldRecordMap.get(c.Id);
            if (cOld == null)
                cOld = new Contract();
                
            if (c.SBQQ__RenewalOpportunity__c != cOld.SBQQ__RenewalOpportunity__c || c.SBQQ__MasterContract__c != cOld.SBQQ__MasterContract__c) {
                if (c.SBQQ__RenewalOpportunity__c == null) {
                   c.SBQQ__MasterContract__c = false;
                } else {
                    opptyIds.add(c.SBQQ__RenewalOpportunity__c);
                }
            }
        }

        if (opptyIds.size() > 0) {
            for (Opportunity o : [Select ID, SBQQ__RenewedContract__c From Opportunity Where ID in: opptyIds and SBQQ__RenewedContract__c <> NULL]) {
                Contract c = (Contract)newRecordMap.get(o.SBQQ__RenewedContract__c);
                if (c != null) {
                 //   c.SBQQ__MasterContract__c = true; Commented out due to SFDC-11140
                }
            }
        }
    }
  
    
    /*******************************************************************************************************
    * @description update contract related fields on order when contract generaion
    * @param trigger.new map
    * @return none, the result should be set to the records itself
    * @example
    */
    private static void updateOrder(List <SObject> records, Map<Id,SObject> oldRecordMap) {
        Map<String, String> orderContractIds = new Map<String, String>();

        for (Contract c : (List<Contract>)records){
            Contract cOld = oldRecordMap == null ? new Contract() : (Contract)oldRecordMap.get(c.Id);
            if (cOld == null)
                cOld = new Contract();
            
            if (c.SBQQ__Order__c != null && c.SBQQ__Order__c != cOld.SBQQ__Order__c) {
                if (!orderContractIds.containsKey(c.SBQQ__Order__c))
                    orderContractIds.put(c.SBQQ__Order__c, c.Id);
            }
        }

        if (orderContractIds.size() > 0) {
            List<Order> orders = new List<Order>();
            for (String orderId : orderContractIds.keySet()) {
                orders.add(new Order(ID = orderId, Active_Contract__c = orderContractIds.get(orderId), Contracted_Date_Time__c = System.now()));
            }

            if (orders.size() > 0) {
                update orders;
            }
        }
    }

    /*******************************************************************************************************
    * @description if related renewal opp contains more than one contract, add co-term to oppty name and all contracts' name
    * @param trigger.new map
    * @return none, the result should be set to the records itself
    * @example
    */
    private static void contractNaming(List <SObject> records, Map<Id,SObject> oldRecordMap) {
        List<Contract> candidates = new List<Contract>();
        Set<String> opptyIds = new Set<String>();

        for (Contract c : (List<Contract>)records){
            Contract cOld = oldRecordMap == null ? new Contract() : (Contract)oldRecordMap.get(c.Id);
            if (cOld == null)
                cOld = new Contract();
            
            if (c.SBQQ__RenewalOpportunity__c != cOld.SBQQ__RenewalOpportunity__c || 
                    c.AccountId != cOld.AccountId || c.Distributor__c != cOld.Distributor__c || c.Reseller__c != cOld.Reseller__c || 
                    c.EndDate != cOld.EndDate) {
                candidates.add(c);

                if(c.SBQQ__RenewalOpportunity__c != null) {
                    opptyIds.add(c.SBQQ__RenewalOpportunity__c);
                }

                if(cOld.SBQQ__RenewalOpportunity__c != null) {
                    opptyIds.add(cOld.SBQQ__RenewalOpportunity__c);
                }
            }
        }

        if (candidates.size() > 0) {
            Map<String, List<Contract>> contractsByOpptyId = new Map<String, List<Contract>>();
            Map<String, Opportunity> opptys = new Map<String, Opportunity>();

            for (Contract c : [Select ID, Name, 
                                SBQQ__RenewalOpportunity__c,
                                SBQQ__RenewalOpportunity__r.Id, 
                                SBQQ__RenewalOpportunity__r.Name, 
                                SBQQ__RenewalOpportunity__r.AccountId, 
                                SBQQ__RenewalOpportunity__r.Account.Name,
                                SBQQ__RenewalOpportunity__r.SBQQ__RenewedContract__c,
                                SBQQ__RenewalOpportunity__r.SBQQ__RenewedContract__r.ContractNumber,
                                SBQQ__RenewalOpportunity__r.SBQQ__RenewedContract__r.SBQQ__MasterContract__c,
                                SBQQ__RenewalOpportunity__r.SBQQ__RenewedContract__r.Most_Recent_Upsell_Hot_List__c, //SFDC-14344
                                AccountId, Account.Name, 
                                Reseller__c, Reseller__r.Name, 
                                Distributor__c, Distributor__r.Name,
                                SBQQ__ExpirationDate__c
                            From Contract 
                            Where ID in: candidates or SBQQ__RenewalOpportunity__c in: opptyIds]) {
                String opptyId = '*None*';//contracts that don't have SBQQ__RenewalOpportunity__c
                if (c.SBQQ__RenewalOpportunity__c != null) {
                    opptyId = c.SBQQ__RenewalOpportunity__c;
                    opptys.put(c.SBQQ__RenewalOpportunity__c, c.SBQQ__RenewalOpportunity__r);
                }
                
                List<Contract> contracts = contractsByOpptyId.get(opptyId);
                if (contracts == null) {
                    contracts = new List<Contract>();
                    contractsByOpptyId.put(opptyId, contracts);
                }
                contracts.add(c);
            } 

            List<Contract> contractsToUpdate = new List<Contract>();
            List<Opportunity> opptysToUpdate = new List<Opportunity>();

            for (String opptyId : contractsByOpptyId.keySet()) {
                Opportunity oppty;
                if (opptyId != '*None*') {
                    oppty = opptys.get(opptyId);
                }
                List<Contract> contracts = contractsByOpptyId.get(opptyId);

                //Oppty Name: Account.Name - Renewal Oppty - ContractNumber - Co-Term
                if (oppty != null) {
                    //Initialize length
                    Integer remainLength = 100;

                    //START SFDC-14344
                    //check if this is an upsell renewal oppty. 
                    // An oppty is an upsell renewal if Renewed contract is populated and the contract's Most Recent Upsell Hotlist field is populated
                    String opptyType = '';
                    if(String.isNotBlank(oppty.SBQQ__RenewedContract__c) && 
                       String.isNotBlank(oppty.SBQQ__RenewedContract__r.Most_Recent_Upsell_Hot_List__c)){
                        opptyType = System.Label.Upsell_Oppty_Name_Component;
                    }
                    else{
                        opptyType = System.Label.Renewal_Oppty_Name_Component;
                    }

                    //Update remainLength
                    remainLength = remainLength - opptyType.length(); 

                    //END SFDC-14344                  

                    //if more than 1 renewed contracts. append co-term to oppty name
                    String cotermPart = '';
                    if (contracts.size() > 1) {
                        cotermPart = ' - Co-Term' ;
                        remainLength = remainLength - ' - Co-Term'.length();
                    }

                    //Contract number
                    String contnumPart = '';
                    if (!String.isEmpty(oppty.SBQQ__RenewedContract__c)) {
                        contnumPart = ' - ' + oppty.SBQQ__RenewedContract__r.ContractNumber;
                        remainLength = remainLength - 3 - contnumPart.length();
                    }

                    String namepart = '';
                    if (!String.isEmpty(oppty.AccountId) && !String.isEmpty(oppty.Account.Name)) {
                        remainLength = remainLength - 3;
                        namepart = oppty.Account.Name.left(remainLength) + ' - ';
                    }

                    // String newName = namepart + 'Renewal Oppty' + contnumPart + cotermPart;
                    String newName = namepart + opptyType + contnumPart + cotermPart; //SFDC-14344
                    if (oppty.Name != newName) {
                        oppty.Name = newName;
                        opptysToUpdate.add(oppty);
                    }
                }

                //Contract Name: 2 of (Distributor.Name - Reseller.Name - Account.Name) - SBQQ__ExpirationDate__c - Co-Term
                for (Contract c : contracts) {
                    Integer remainLength = 80;

                    //if more than 1 renewed contracts. append co-term to contract name
                    String cotermPart = '';
                    if (opptyId != '*None*' && contracts.size() > 1) {
                        cotermPart = ' - Co-Term' ;
                        remainLength = remainLength - ' - Co-Term'.length();
                    }
                    
                    String dtPart = '';
                    Date expDate = Test.isRunningTest() ? System.today() : c.SBQQ__ExpirationDate__c;
                    if (expDate != null) {
                        String yyyy = String.valueOf(expDate.Year());
                        String mm = String.valueOf(expDate.Month()).LeftPad(2, '0');
                        String dd = String.valueOf(expDate.Day()).LeftPad(2, '0');
                        
                        dtPart = ' - ' + YYYY+'-'+MM+'-'+DD;
                        remainLength = remainLength - 3 - dtPart.length();
                    }

                    String namepart = '';
                    Integer nameparts = 0;
                    if (!String.isEmpty(c.Distributor__c) && !String.isEmpty(c.Distributor__r.Name)) {
                        String n = c.Distributor__r.Name.left(remainLength);

                        nameparts++;
                        remainLength = remainLength - n.length();
                        namepart = namepart + n;
                    }

                    if (remainLength > 3 && !String.isEmpty(c.Reseller__c) && !String.isEmpty(c.Reseller__r.Name)) {
                        if (nameparts > 0) {
                            remainLength = remainLength - 3;
                            namepart = namepart + ' - ';
                        }

                        String n = c.Reseller__r.Name.left(remainLength);

                        nameparts++;
                        remainLength = remainLength - n.length();
                        namepart = namepart + n;
                    }

                    if (nameparts < 2 && remainLength > 3 && !String.isEmpty(c.AccountId) && !String.isEmpty(c.Account.Name)) {
                        if (nameparts > 0) {
                            remainLength = remainLength - 3;
                            namepart = namepart + ' - ';
                        }

                        String n = c.Account.Name.left(remainLength);
                        namepart = namepart + n;
                    }

                    String newName = namepart + dtPart + cotermPart;
                    if (c.Name != newName) {
                        c.Name = newName;
                        contractsToUpdate.add(c);
                    }
                }
            }
            
            if (opptysToUpdate.size() > 0)
                update opptysToUpdate;

            if (contractsToUpdate.size() > 0)
                update contractsToUpdate;
        }
    }
    /**
    * Added as part of SFDC-20558: START
	*/
    private static void assignACVToContract(List <SObject> records, Map<Id,SObject> oldRecordMap){
        Set<ID> oppIDs = new Set<ID>();
        //Map<ID, ID> mapConOpp = new Map<ID, ID>();
        Map<Id, Opportunity> mapOpp = new Map<Id, Opportunity>();
        try{
            for(Contract contr : (List<Contract>)records){
                Contract cOld = oldRecordMap == null ? new Contract() : (Contract)oldRecordMap.get(contr.Id);
                if (cOld == null)
                cOld = new Contract();
                if(contr.SBQQ__Opportunity__c != NULL){
                    oppIDs.add(contr.SBQQ__Opportunity__c);
                }else{
                    contr.Annual_Contract_Value__c = 0.00;
                }
            }if(!oppIDs.isEmpty()){
                for(Opportunity opp : [select id, SBCF_Annual_Contract_Value2__c from Opportunity where id in :oppIDs]){
                    mapOpp.put(opp.id, opp);
                }
                for(Contract c : (List<Contract>)records){
                    Contract cOld = oldRecordMap == null ? new Contract() : (Contract)oldRecordMap.get(c.Id);
                    if (cOld == null)
                    cOld = new Contract();
                    if(mapOpp.containsKey(c.SBQQ__Opportunity__c) && mapOpp.get(c.SBQQ__Opportunity__c).SBCF_Annual_Contract_Value2__c != NULL){
                        c.Annual_Contract_Value__c = mapOpp.get(c.SBQQ__Opportunity__c).SBCF_Annual_Contract_Value2__c;
                    }else{
                        c.Annual_Contract_Value__c = 0.00;
                    }
                }
            }
        }Catch(Exception e){
            System.debug('Exception'+e.getMessage()+'Occurred at'+e.getStackTraceString());
        }
    }
    /**
    * Added as part of SFDC-20558: END
	*/
}
/*
IF(NOT([Contract].SBQQ__MasterContract__c), 
    IF(NOT(ISBLANK([Contract].Distributor__c)) && NOT(ISBLANK([Contract].Reseller__c )), TRIM(LEFT([Contract].Distributor__c.Name + " - " +  [Contract].Reseller__c.Name, 67)) + " - " + TEXT([Contract].SBQQ__ExpirationDate__c), 
        IF(NOT(ISBLANK([Contract].Distributor__c)) && ISBLANK([Contract].Reseller__c ), TRIM(LEFT([Contract].Distributor__c.Name + " - " + [Contract].Account.Name, 67)) + " - " + TEXT([Contract].SBQQ__ExpirationDate__c),
            IF(ISBLANK([Contract].Distributor__c) && NOT(ISBLANK([Contract].Reseller__c )), TRIM(LEFT([Contract].Reseller__c.Name, 67)) + " - " + TEXT([Contract].SBQQ__ExpirationDate__c), 
                TRIM(LEFT([Contract].Account.Name, 57)) + " - " + TEXT([Contract].SBQQ__ExpirationDate__c)))),
    IF(NOT(ISBLANK([Contract].Distributor__c)) && NOT(ISBLANK([Contract].Reseller__c )), TRIM(LEFT([Contract].Distributor__c.Name + " - " +  [Contract].Reseller__c.Name, 57)) + " - " + TEXT([Contract].SBQQ__ExpirationDate__c)  + " - Co-Term", 
        IF(NOT(ISBLANK([Contract].Distributor__c)) && ISBLANK([Contract].Reseller__c ), TRIM(LEFT([Contract].Distributor__c.Name + " - " + [Contract].Account.Name, 57)) + " - " + TEXT([Contract].SBQQ__ExpirationDate__c)  + " - Co-Term",
            IF(ISBLANK([Contract].Distributor__c) && NOT(ISBLANK([Contract].Reseller__c )), TRIM(LEFT([Contract].Reseller__c.Name, 57)) + " - " + TEXT([Contract].SBQQ__ExpirationDate__c) + " - Co-Term", 
                TRIM(LEFT([Contract].Account.Name, 57)) + " - " + TEXT([Contract].SBQQ__ExpirationDate__c)  + " - Co-Term")))
)





IF(NOT([Opportunity].SBQQ__RenewedContract__c.SBQQ__MasterContract__c), [Opportunity].Account.Name + " - Renewal Oppty - " + [Opportunity].SBQQ__RenewedContract__c.ContractNumber, [Opportunity].Account.Name + " - Renewal Oppty - " + [Opportunity].SBQQ__RenewedContract__c.ContractNumber + " - Co-term")
 */