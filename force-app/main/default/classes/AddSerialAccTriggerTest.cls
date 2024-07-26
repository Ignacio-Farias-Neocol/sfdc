/**
* @author Dilowar Hussain
* @date 2022-08-22
*
* @description : Test Class for Additional_Serial_Access__c Trigger.
* 
*
* 
* This has been added as a part of SFDC-16682 
*/
@isTest
public with sharing class AddSerialAccTriggerTest {
    public testMethod static void testJudgeAPIMethod(){
        try{
            List<Case> caseRecordListUpdate = new List<Case>(); 
            List<Additional_Serial_Access__c> addSerAccList = new List<Additional_Serial_Access__c>();
            List<Additional_Serial_Access__c> addSerAccUpdateList = new List<Additional_Serial_Access__c>();
            Map<id, Additional_Serial_Access__c> mapAddSerAcc = new Map<id, Additional_Serial_Access__c>();
            Map<Id, Case> mapCase = new Map<Id, Case>();
            Case caseRec = TestDataFactory.webCases[0];
            //System.debug('caseRec is:' +caseRec);
            Id CaseRecordID = caseRec.id;
            //System.debug('CaseRecordID is:' +CaseRecordID);
            
            if(CaseRecordID != NULL){
                List<Case> caseRecordList = [select id, caseNumber, serial_number__c, status, Case_Owner_Person__c, Engineering_Escalated_By__c, Escalated_To__c, Escalation_Approver__c, Escalated_to_support_escalations_by__c, RMA_Submitted_By__c, RMA_Approval_1__c, RMA_Approval_2__c from Case where id = :CaseRecordID];
                //system.debug('caseRecordList is:' +caseRecordList);
                for(Case cs02 : caseRecordList){
                    mapCase.put(cs02.id, cs02);
                    caseRecordListUpdate.add(cs02);
                }
                //system.debug('caseRecordListUpdate is:' +caseRecordListUpdate); 
            }
            List<Serial__c> lstSerials = new List<Serial__c>();
            Serial__c serial01 = new Serial__c();
            serial01.Activation_Date__c = Date.today();
            serial01.Serial_Number__c = 'S-4321';
            serial01.Status__c = 'Active';
            lstSerials.add(serial01);
            insert lstSerials;
            List<Serial__c> lstSerialsV02 = new List<Serial__c>(); 
            Serial__c serial = new Serial__c();
            serial.Activation_Date__c = Date.today();
            serial.Serial_Number__c = 'S-1234';
            serial.Status__c = 'Active';
            lstSerialsV02.add(serial);
            insert lstSerialsV02;

            Additional_Serial_Access__c addSerAcc = new Additional_Serial_Access__c();
            addSerAcc.Case__c = caseRecordListUpdate[0].id;
            addSerAcc.Additional_Serial__c = lstSerials[0].id;
            addSerAccList.add(addSerAcc);
            if(!addSerAccList.isEmpty()){
                insert addSerAccList;
            }
            //system.debug('addSerAccList is:' +addSerAccList);
            for(Additional_Serial_Access__c adSAcc: addSerAccList){
                mapAddSerAcc.put(adSAcc.id, adSAcc);
                adSAcc.Additional_Serial__c = lstSerialsV02[0].id;
                addSerAccUpdateList.add(adSAcc);
            }
            update addSerAccUpdateList;
            //system.debug('addSerAccUpdateList is:' +addSerAccUpdateList);
            //system.debug('mapAddSerAcc is:' +mapAddSerAcc);
            if(!addSerAccUpdateList.isEmpty() && !mapAddSerAcc.isEmpty()){
                DynamicBusinessRuleAddSeriAccHelper  inst01 = new DynamicBusinessRuleAddSeriAccHelper();
                //inst01.publishEvent = FALSE;
                inst01.processRecords(null, mapAddSerAcc, addSerAccUpdateList, null, null, 'Insert');
            }
        }Catch(Exception e){
            System.debug('Exception occurred:' +e.getStackTraceString());
        }
    }
}