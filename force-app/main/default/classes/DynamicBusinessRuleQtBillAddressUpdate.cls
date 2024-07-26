/**
 * Class Name: DynamicBusinessRuleQtBillAddressUpdate
 * 
 * Description: 
 * This class gets invoked on before quote record update. 
 * Then, it checks, if Bill-To-Account field values gets changed,
 * it updates the Billing Address details on the same record. 
 * 
 * @author Dilowar Hussain
 * @createDate  22-10-2022
 * 
 * This has been added as a part of SFDC-18177
 */
public with sharing class DynamicBusinessRuleQtBillAddressUpdate implements DynamicBusinessRuleAction{
    /**
     * Process Method
     * 
     * @return void
     */
    public void processRecords(Map<Id,SObject> newRecordMap, 
                                Map<Id,SObject> oldRecordMap, 
                                List <SObject> records, 
                                String jsonParameter, 
                                String triggerOrder, 
                                String triggerContext) {
        //Instantiate the log class to capture logs for error conditions
        LogModel log = LogModel.startLog('DynamicBusinessRuleQtBillAddressUpdate', 'processRecords', LogModel.LOG_CATEGORY_APEX);
        try{
            if(triggerContext.contains('Update')){
                populateBillingAddPostAccountChange(records, oldRecordMap);
            }
        }Catch(Exception e){
            log.addExceptionLog(e);
            system.debug('Exception occurred:' +e.getStackTraceString());
        }
    }
    /***
     * Method Name: populateBillingAddPostAccountChange
     * 
     * Description: 
     * This method will populate the Billing Address fields based on the 
     * SBCF_Bill_To_Account__c field on Quote record.
     * 
     * This has been added as a part of SFDC-18177
     * 
     * @param : 
     * @return : None
     */
    private static void populateBillingAddPostAccountChange(List<SObject> records, Map<Id, SObject> oldRecordMap) {
        //Instantiate the log class to capture logs for error conditions
        LogModel log = LogModel.startLog('DynamicBusinessRuleQuoteBefore', 'populateBillingAddPostAccountChange', LogModel.LOG_CATEGORY_APEX);
        Map<Id,List<SBQQ__Quote__c>> billToAccountChangedQtMap = new Map<Id,List<SBQQ__Quote__c>>();
        Set<Id> acctIds = new Set<Id>();
        try{
            for (SBQQ__Quote__c newQt : (List<SBQQ__Quote__c>)records){
                //Get old Opp
                SBQQ__Quote__c oldQt = oldRecordMap == null ? new SBQQ__Quote__c() : (SBQQ__Quote__c)oldRecordMap.get(newQt.Id);
          
                //if old opp is null, initialize it to a blank opportunity
                if (oldQt == null){
                    oldQt = new SBQQ__Quote__c();
                }
                //Check if the bill to account has changed. This will change if End User/Reseller/Disti has changed.
                //This will be used to populate billing address
                
                /*Modified by: Sonal Agrawal 13-04-2023
                SFDC-19107: Opportunity Billing/ Shipping Address is not in Sync with Primary Quote
                Added the check of non primary quote and only make it work when SBCF_Bill_To_Account__c is changed*/
                if (!newQt.SBQQ__Primary__c && newQt.SBCF_Bill_To_Account__c != null && oldQt.SBCF_Bill_To_Account__c != null && newQt.SBCF_Bill_To_Account__c != oldQt.SBCF_Bill_To_Account__c) {
                    if(billToAccountChangedQtMap.containsKey(newQt.SBCF_Bill_To_Account__c)){
                        billToAccountChangedQtMap.get(newQt.SBCF_Bill_To_Account__c).add(newQt);
                    }
                    else{
                        billToAccountChangedQtMap.put(newQt.SBCF_Bill_To_Account__c, new List<SBQQ__Quote__c>{newQt});
                    }
                    acctIds.add(newQt.SBCF_Bill_To_Account__c);
                }
            }
            if (!acctIds.isEmpty()) {
                //Loop through these accounts and populate related information in the opportunity
                for(Account currentAccount: [SELECT Id, (SELECT Id,Street__c,City__c,State_Name__c,Zip_Postal_Code__c,Country_Name__c,Country_ISO__c,Type__c FROM Addresses__r  WHERE Primary__c = TRUE) FROM Account WHERE Id in: acctIds]){
                    //Get the billing address and shipping address for the given account
                    Address__c billingAddress;
                    Address__c shippingAddress;

                    for(Address__c addr: currentAccount.Addresses__r){
                        if(addr.Type__c == 'Billing' && billingAddress==null){
                            billingAddress = addr;
                        }
                        else if(addr.Type__c == 'Shipping' && shippingAddress==null){
                            shippingAddress = addr;
                        }
                        if(billingAddress!=null && shippingAddress!=null){
                            break;
                        }
                    }
                    //For each account find the related oppties and update applicable address field
                    //Opportunities with changed bill to account
                    if(billToAccountChangedQtMap.containsKey(currentAccount.Id)){
                        for(SBQQ__Quote__c billToAccountQt: billToAccountChangedQtMap.get(currentAccount.Id)){
                        if(billingAddress!=null){
                            //Billing Address update
                            billToAccountQt.Billing_Address__c = billingAddress.Id;
                            billToAccountQt.SBQQ__BillingStreet__c = billingAddress.Street__c;
                            billToAccountQt.SBQQ__BillingCity__c = billingAddress.City__c;
                            billToAccountQt.SBQQ__BillingState__c = billingAddress.State_Name__c;
                            billToAccountQt.SBQQ__BillingPostalCode__c = billingAddress.Zip_Postal_Code__c;
                            billToAccountQt.SBQQ__BillingCountry__c = billingAddress.Country_Name__c;
                            //billToAccountQt.Country_ISO_Code__c = billingAddress.Country_ISO__c;
                        }
                        }
                    }
                }
            }

        }Catch(Exception e){
            log.addExceptionLog(e);
            system.debug('Exception occurred:' +e.getStackTraceString());
        }
    }
    
}