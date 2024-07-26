/**
* @author IY
* @date 2018
*
* @group DynmaicBusinessRuleAction
* @group-content a relative path to a static html file that provides content about the group
*
* @description implementation of DynamicBusinessRuleAction interface to terminate subscripton when serial is terminated
*/
public with sharing class DynamicBusinessRuleSerialTerminated implements DynamicBusinessRuleAction {


    /*******************************************************************************************************
    * @description terminate the subscripton records for serials
    * @param trigger.new map
    * @return none, the result should be set to the records itself
    * @example
    */
    public void processRecords(Map<Id,SObject> newRecordMap, Map<Id,SObject> oldRecordMap, List <SObject> records, String jsonParameter, String triggerOrder, String triggerContext) {

        LogModel log = LogModel.startLog('DynamicBusinessRuleSerialTerminated', 'processRecords');

        System.debug('DynamicBusinessRuleSerialTerminated records:' + records);
        try {

            Set <Id> serialIds = new Set <Id>();
            for (SObject obj : records) {
                Serial__c s = (Serial__c) obj;
                if (s.Is_Terminated__c == true){
                    serialIds.add(s.Id);
                }
            }

            Set <Id> subIds = new Set <Id>();
            Set <Id> contractIds = new Set <Id>();
            For (Assigned_Serial__c a: [select  Parent_Subscription__c, Parent_Subscription__r.SBQQ__Contract__c, Serial__c,
                    Serial_Number__c, Status__c, Subscription__c, Subscription__r.SBQQ__Contract__c from Assigned_Serial__c
                  where Serial__c in :serialIds and Status__c = 'Active']){

                if (a.Subscription__c != null){
                    subIds.add(a.Subscription__c);
                }

                if (a.Subscription__r.SBQQ__Contract__c != null){
                    contractIds.add(a.Subscription__r.SBQQ__Contract__c);
                }

            }

            if (subIds.size() > 0 ){
                List <SBQQ__Subscription__c> subscriptions = [ select Active__c, SBQQ__SubscriptionEndDate__c, SBQQ__TerminatedDate__c , id , status__c,
                        SBQQ__SubscriptionType__c from SBQQ__Subscription__c where id in: subIds ];

                For (SBQQ__Subscription__c s: subscriptions){

                }
                DML.save(subscriptions);
            }

            if (contractIds.size() > 0 ){
                List <Contract> contracts = [select id, SBQQ__ActiveContract__c , Status , EndDate , StartDate , SBQQ__ExpirationDate__c from Contract];

                For (Contract c: contracts){

                }

                DML.save(contracts);
            }


        } Catch (Exception e){
            System.debug('#### Exceptions: ' + e.getMessage());
            log.addExceptionLog(e);
        }


    }
}