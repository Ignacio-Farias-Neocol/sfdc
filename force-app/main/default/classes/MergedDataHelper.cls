/**
*
*
* @Author IY
* @Date  1/15/19.
* @group Helper class to handle merged data
* @description  model after Cuda Gold Salesforce instance 's SNAP_AccountTriggerHandler
*/
public with sharing class MergedDataHelper {

    private static Integer MAX_FIELD_SIZE = 131072;

    // Log: 1/4/2018 Eric He - Added, after merging accounts, the external ID of duplicate accounts
    // should be stored in the master related list (External ID History)
    public static void reserveDupAccountsExternalID(List <SObject> lObjects){
        List<SObject> duplicates = new List<SObject>();
        for(SObject obj : lObjects){
            // When a record is deleted after losing a merge operation,
            // its MasterRecordId field is set to the ID of the winning record
            if(obj.Id  != null && obj.get('MasterRecordId') != null){
                duplicates.add(obj);
            }
        }

        if(!duplicates.isEmpty()){
            saveDuplicates(duplicates);
        }
    }

    @TestVisible
    private static void saveDuplicates(List<SObject> duplicates){
        List<External_ID_History__c> externalIDs = new List<External_ID_History__c>();
        for(SObject obj : duplicates)
        {
            String sObjName = obj.Id.getSObjectType().getDescribe().getName();
            Id accountId;
            Id contactId;
            if (sObjName == 'Account'){
                accountId = (Id) obj.get('MasterRecordId');
            } else if (sObjName == 'Contact'){
                contactId = (Id) obj.get('MasterRecordId');
            }

            externalIDs.add(new External_ID_History__c(
                    Name = obj.Id,
                    Account__c = accountId,
                    Contact__c = contactId,
                	type__c = 'Deletion',
                    Object_Name__c = sObjName,
                    Record_Content__c = JSON.serialize(obj).left(MAX_FIELD_SIZE)
            ));
        }
        DML.save(externalIDs);
    }
    
    //directly called from AccountTriggerHandler with undelete event.
    @TestVisible
    public static void unMergeRecords(List<SObject> unmergeRecords){
        
        Map<Id,SObject> unmergeRecordsMap = new Map<Id,Sobject>();
        for(SObject sobj: unmergeRecords){
            unmergeRecordsMap.put((Id)sobj.get('Id'),sobj);
        }
        List<External_ID_History__c> externalIdCreateForUnMerge = new List<External_ID_History__c>();
        List<External_ID_History__c> externalIds = new List<External_ID_History__c>([Select id,type__c,Account__c,Contact__c,Name,Object_Name__c from External_ID_History__c where name in: unmergeRecordsMap.keyset() AND Type__c = 'Deletion']);
        if(!externalIds.isEmpty()){
            for(External_ID_History__c externalIdObj: externalIds){
                External_ID_History__c ext = new External_ID_History__c();
                ext.Account__c = externalIdObj.Name;
                ext.Name = externalIdObj.Account__c;
                ext.Object_Name__c = externalIdObj.Object_Name__c;
                ext.type__c = 'Un-Merge';
                ext.Record_Content__c = JSON.serialize(unmergeRecordsMap.get(Id.valueof(externalIdObj.Name)));
                externalIdCreateForUnMerge.add(ext);
            }
        }
        if(!externalIdCreateForUnMerge.isEmpty()){
            DML.save(externalIdCreateForUnMerge);
        }
    }
}