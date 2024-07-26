public class DuplicateCaseTitleController {
	
    @AuraEnabled
    public static Boolean checkIfDuplicate(Id recordId){
        Boolean isDuplicate = false;
        Id webCaseRTId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Web Message').getRecordTypeId();
        List<Case> caseRecordList = [Select Id, ContactId, Subject from Case where 
                           Id =: recordId and 
                           RecordTypeId =: webCaseRTId and
                           CreatedDate = TODAY];
        if(caseRecordList.isEmpty()){
            return isDuplicate;
        } 
        Case caseRecord = caseRecordList[0];
        List<Case> caseList = [Select Id from Case where 
                               CreatedDate = TODAY and ContactId != null and
                               ContactId =: caseRecord.ContactId and
                               Subject =: caseRecord.Subject and 
                               RecordTypeId =: webCaseRTId and 
                               Id !=: caseRecord.Id];
        if(!caseList.isEmpty()){
            isDuplicate = true;
        }
        return isDuplicate;
    }
}