// Test Class - DynamicBusinessRuleFeedCommentTest
public class RelatedListController {  
    
    @AuraEnabled  
    public static List<Case> fetchRecs() {  
        Id professionalServiceRTId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Professional Services').getRecordTypeId();
        //Id webCaseRTId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Web Message').getRecordTypeId();
        Id technicalSupportRTId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Technical Support').getRecordTypeId();
        User userRecord = [Select Id, AccountId from User where Id =: UserInfo.getUserId()];
        List<Case> caseList = [Select Id, CreatedDate, Contact.Name, Status, Serial_Number__c, Product_Family__c, RecordType.Name, 
                               ContactId, RecordTypeId, Table_Source__c,
                               CaseNumber, Subject, Origin, Priority from Case 
                               where (RecordTypeId =: technicalSupportRTId or RecordTypeId =: professionalServiceRTId) 
                               and AccountId =: userRecord.AccountId order by CreatedDate desc]; 
        for(Case caseRecord: caseList){
            caseRecord.Table_Source__c = caseRecord.CreatedDate.format('MM/dd/yyyy hh:mm a');
        }
        return caseList;
    }      
  
}