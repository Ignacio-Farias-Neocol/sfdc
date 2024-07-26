/****
 * Class Name: DynamicBusinessRuleReselDistValidateOnOp
 * Description:
 *  This class performs below validation on Opportunity records based on Reseller & Distributor Accounts
 *  and thier respective contacts.
 * 
 * @author Dilowar Hussain
 * @createdDate 19-10-2022
 *  
 *  Jira ticket: SFDC-18052
 */
public without sharing class DynamicBusinessRuleReselDistValidateOnOp implements DynamicBusinessRuleAction{
   /**
    * Method description:
    * @param
    * @Return
    * This has been added as a part of SFDC-18052 
    */
    public static Boolean avoidRecurr = FALSE;
    public void processRecords(Map<Id,SObject> newRecordMap, 
                                                            Map<Id,SObject> oldRecordMap,
                                                            List <SObject> records, 
                                                            String jsonParameter, 
                                                            String triggerOrder, 
                                                            String triggerContext) {

        LogModel log = LogModel.startLog('DynamicBusinessRuleReselDistValidateOnOp', 'processRecords', LogModel.LOG_CATEGORY_APEX);
        Map<Id, Opportunity> distiAccIdOpp = new Map<Id, Opportunity>();
        Set<Id> distiConIds = new Set<ID>();
        Map<Id, Opportunity> resellerAccIdOpp = new Map<Id, Opportunity>();
        Set<Id> reselConIds = new Set<ID>();
        String errorMessage = '';
        try{
            if(triggerContext.contains('Update') && !avoidRecurr){
                //SetAutoRenewalfieldsonOpp(records);
                for(SObject rec: records){
                    Opportunity opp = (Opportunity)rec;
                    Opportunity opp2 = oldRecordMap == null ? null : (Opportunity)oldRecordMap.get(opp.Id);
                    if (opp2 == null){opp2 = new Opportunity();}
                    //system.debug('Test main condition' +Label.Reseller_Distributor_validation_Opp_stages.contains(String.valueOf(opp.StageName)));
                    //system.debug('Test main condition' +!Label.Reseller_Distributor_validation_Opp_stages.contains(String.valueOf(opp.StageName)));
                    if(!Label.Reseller_Distributor_validation_Opp_stages.contains(String.valueOf(opp.StageName))){
                        //Distributor check
                        //system.debug('Main condition check passed');
                        if(opp.Distributor__c != null && opp.Distributor_Contact__c != null){
                            //System.debug('Distributor and Contacts available');
                            distiAccIdOpp.put(opp.Distributor__c, opp);
                            distiConIds.add(opp.Distributor_Contact__c);
                        }else if(opp.Distributor__c == null && opp.Distributor_Contact__c != null){
                            //System.debug('Distributor not available but Contact is available');
                            errorMessage = Label.Distributor_Validation_Error_Message;
                            opp.addError(errorMessage);
                        }else if(opp.Distributor__c != null && opp.Distributor_Contact__c == null){
                            //System.debug('Distributor available but Contact is not available');
                            errorMessage = errorMessage + Label.Distributor_Validation_Error_Message;
                            opp.addError(errorMessage);
                        }
                        //Reseller Check
                        if(opp.Reseller__c != null && opp.Reseller_Contact__c != null){
                            //System.debug('Reseller and Contacts available');
                            resellerAccIdOpp.put(opp.Reseller__c, opp);
                            reselConIds.add(opp.Reseller_Contact__c);
                        }else if(opp.Reseller__c == null && opp.Reseller_Contact__c != null){
                            //System.debug('Reseller Account not available');
                            errorMessage = errorMessage + Label.Reseller_Validation_Error_Message;                            
                            opp.addError(errorMessage);
                        }else if(opp.Reseller__c != null && opp.Reseller_Contact__c == null){
                            //System.debug('Reseller Contact not available');
                            errorMessage = errorMessage + Label.Reseller_Validation_Error_Message;   
                            opp.addError(errorMessage);
                        }
                    }
                }
                //For Distributor
                Set<String> conAccRelListDist = new Set<String>();
                If (!distiAccIdOpp.isEmpty() && !distiConIds.isEmpty()) {
                    // get distributor account contact relationships
                    List<AccountContactRelation> accConRelD = [select AccountId, ContactId from AccountContactRelation where AccountId in :distiAccIdOpp.keySet() and ContactId in :distiConIds];
                    for (AccountContactRelation acr : accConRelD) {
                        conAccRelListDist.add((String)acr.ContactId+(String)acr.AccountId);
                    }
                }
                //For Reseller
                Set<String> conAccRelListResell = new Set<String>();
                If (!resellerAccIdOpp.isEmpty() && !reselConIds.isEmpty()) {
                    // get reseller account contact relationships
                    List<AccountContactRelation> accConRelR = [select AccountId, ContactId from AccountContactRelation where AccountId in :resellerAccIdOpp.keySet() and ContactId in :reselConIds];
                    for (AccountContactRelation acr : accConRelR) {
                        conAccRelListResell.add((String)acr.ContactId+(String)acr.AccountId);
                    }
                }
                //Final Check for Account and Contact association
                for(SObject o : records) {
                    Opportunity opp02 = (Opportunity) o;
                    if (!Label.Reseller_Distributor_validation_Opp_stages.contains(String.valueOf(opp02.StageName)) && opp02.Distributor__c != null && opp02.Distributor_Contact__c != null && conAccRelListDist.contains((String)opp02.Distributor_Contact__c+(String)opp02.Distributor__c) == false) {
                        //System.debug('Distributor and Contact are not associated');
                        errorMessage = errorMessage + Label.Distributor_Validation_Error_Message;
                        opp02.addError(errorMessage);
                    }
                    if (!Label.Reseller_Distributor_validation_Opp_stages.contains(String.valueOf(opp02.StageName)) && opp02.Reseller__c != null && opp02.Reseller_Contact__c != null && conAccRelListResell.contains((String)opp02.Reseller_Contact__c+(String)opp02.Reseller__c) == false) {
                        //System.debug('Reseller and Contact are not associated');
                        errorMessage = errorMessage + Label.Reseller_Validation_Error_Message;  
                        opp02.addError(errorMessage);
                    }
                } 
            }
            avoidRecurr = TRUE;
        }Catch(Exception e){
            log.addExceptionLog(e);
            system.debug('Exception occurred:' +e.getStackTraceString());
        }
    } 
    /**
     * Description: Method added from Flow "Opportunity After Save Operations".
     * 
     * This method has been added as a part of SFDC-19100
     * Migration of opportunity update logic for the ticket SFDC-15315.
     * 
     */
    /*public void SetAutoRenewalfieldsonOpp(List <SObject> records){
        LogModel log = LogModel.startLog('DynamicBusinessRuleReselDistValidateOnOp', 'SetAutoRenewalfieldsonOpp', LogModel.LOG_CATEGORY_APEX);
        try{
            Id oRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('New Business').getRecordTypeId();
            for(SObject rec: records){
                Opportunity opp = (Opportunity)rec;
                if(Opp.RecordTypeId == oRecordTypeId && opp.Hot_List__c!='' && opp.SBQQ__RenewedContract__c!='' &&
                    opp.Hot_List__c!=null && opp.SBQQ__RenewedContract__c!=null){
                        opp.Auto_Renewal_Status_Core__c = '';
                        opp.Auto_Renewal_Status_Reason_Core__c = '';
                 }
            }
        }Catch(Exception e){
            log.addExceptionLog(e);
            system.debug('Exception occurred:' +e.getStackTraceString());
        }
    }*/
}