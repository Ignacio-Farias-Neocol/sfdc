/****
 * Class Name: DynamicBusinessRuleReselDistValidateOnQt
 * Description:
 *  This class performs below validation on Quote records based on Reseller & Distributor Accounts
 *  and thier respective contacts.
 * 
 * @author Dilowar Hussain
 * @createdDate 19-10-2022
 * 
 * Jira ticket: SFDC-18052 
 */
public without sharing class DynamicBusinessRuleReselDistValidateOnQt implements DynamicBusinessRuleAction{
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

        LogModel log = LogModel.startLog('DynamicBusinessRuleReselDistValidateOnQt', 'processRecords', LogModel.LOG_CATEGORY_APEX);
        Map<Id, SBQQ__Quote__c> distiAccIdQt = new Map<Id, SBQQ__Quote__c>();
        Set<Id> distiConIDs = new Set<ID>();
        Set<Id> reselConIDs = new Set<ID>();
        Map<Id, SBQQ__Quote__c> resellAccIdQt = new Map<Id, SBQQ__Quote__c>();
        String errorMessage = '';
        try{
            if(triggerContext.contains('Update')  && !avoidRecurr){
                for(SObject rec: records){
                    SBQQ__Quote__c qt01 = (SBQQ__Quote__c)rec;
                    SBQQ__Quote__c qt02 = oldRecordMap == null ? null : (SBQQ__Quote__c)oldRecordMap.get(qt01.Id);
                    if (qt02 == null){qt02 = new SBQQ__Quote__c();}
                    //Distributor Check
                    if(qt01.SBQQ__Distributor__c != null && qt01.SBCF_Distributor_Contact__c != null){
                        //System.debug('Distributor and Contacts available');
                        distiAccIdQt.put(qt01.SBQQ__Distributor__c, qt01);
                        distiConIDs.add(qt01.SBCF_Distributor_Contact__c);
                    }else if(qt01.SBQQ__Distributor__c == null && qt01.SBCF_Distributor_Contact__c != null){
                        //System.debug('Distributor not available but Contact is available');
                        errorMessage = Label.Distributor_Validation_Error_Message;
                        qt01.addError(errorMessage);
                    }else if(qt01.SBQQ__Distributor__c != null && qt01.SBCF_Distributor_Contact__c == null){
                        //System.debug('Distributor available but Contact is not available');
                        errorMessage = errorMessage + Label.Distributor_Validation_Error_Message;
                        qt01.addError(errorMessage);
                    }
                    //Reseller Check
                    if(qt01.SBCF_Reseller__c != null && qt01.SBCF_Reseller_Contact__c != null){
                        //System.debug('Reseller and Contacts available');
                        resellAccIdQt.put(qt01.SBCF_Reseller__c, qt01);
                        reselConIDs.add(qt01.SBCF_Reseller_Contact__c);
                    }else if(qt01.SBCF_Reseller__c == null && qt01.SBCF_Reseller_Contact__c != null){
                        //System.debug('Reseller Account not available');
                        errorMessage = errorMessage + Label.Reseller_Validation_Error_Message; 
                        qt01.addError(errorMessage);
                    }else if(qt01.SBCF_Reseller__c != null && qt01.SBCF_Reseller_Contact__c == null){
                        //System.debug('Reseller Contact not available');
                        errorMessage = errorMessage + Label.Reseller_Validation_Error_Message;
                        qt01.addError(errorMessage);
                    }
                }
                //For Distributor
                Set<String> conAccRelLstDist = new Set<String>();
                if (!distiAccIdQt.isEmpty() && !distiConIDs.isEmpty()) {
                    // get distributor account contact relationships
                    //System.debug('Get Account and contact relation for Distri');
                    List<AccountContactRelation> accConRelDist = [select AccountId, ContactId from AccountContactRelation where AccountId in :distiAccIdQt.keySet() and contactId in :distiConIDs];
                    for (AccountContactRelation acr : accConRelDist) {
                        conAccRelLstDist.add((String)acr.ContactId+(String)acr.AccountId);
                    }
                }
                //For Reseller
                Set<String> conAccRelLstResell = new Set<String>();
                if (!resellAccIdQt.isEmpty() && !reselConIDs.isEmpty()) {
                    // get distributor account contact relationships
                    //System.debug('Get Account and contact relation');
                    List<AccountContactRelation> accConRelRes = [select AccountId, ContactId from AccountContactRelation where AccountId in :resellAccIdQt.keySet() and ContactId in :reselConIDs];
                    for (AccountContactRelation acr : accConRelRes) {
                        conAccRelLstResell.add((String)acr.ContactId+(String)acr.AccountId);
                    }
                }
                //Final Check for Account and Contact association
                for (SObject q2 : records) {
                    SBQQ__Quote__c qt2 = (SBQQ__Quote__c) q2;
                    //Opportunity opp = (Opportunity) o;
                    //For Distributor
                    if (qt2.SBCF_Distributor_Contact__c != null && qt2.SBQQ__Distributor__c != null && conAccRelLstDist.contains((String)qt2.SBCF_Distributor_Contact__c+(String)qt2.SBQQ__Distributor__c) == false) {
                        //System.debug('Distributor and Contact are not associated');
                        errorMessage = errorMessage + Label.Distributor_Validation_Error_Message;
                        qt2.addError(errorMessage);
                    }
                    //For Reseller
                    if (qt2.SBCF_Reseller_Contact__c != null && qt2.SBCF_Reseller__c != null && conAccRelLstResell.contains((String)qt2.SBCF_Reseller_Contact__c+(String)qt2.SBCF_Reseller__c) == false) {
                        //System.debug('Distributor and Contact are not associated');
                        errorMessage = errorMessage + Label.Reseller_Validation_Error_Message; 
                        qt2.addError(errorMessage);
                    }
                }
            }
            avoidRecurr = TRUE;
        }Catch(Exception e){
            log.addExceptionLog(e);
            system.debug('Exception occurred:' +e.getStackTraceString());
            //return null;
        }
    }
}