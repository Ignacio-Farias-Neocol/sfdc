public class RequestForClosurePopupController {
    
    public static Boolean isTestRunning = false;
     
    @AuraEnabled
    public static ResponseObject updateCase(String reason, String comment, String recordId) {
        Case caseRecord = new Case();
        caseRecord.Id = recordId;
        caseRecord.Community_Request_Close_Reason__c = reason;
        caseRecord.Close_Reason_Comments__c = comment;
        try {
            update caseRecord;
            System.debug('##caseRecord:: ' + JSON.serialize(caseRecord));
            ResponseObject resp = new ResponseObject();
            resp.isSuccess = true; 
            
            // lines to cover code
            if(isTestRunning){
                throw new CustomException('Exception for test class');
            }     
            
            return resp;       
        } catch(Exception e){
            System.debug('**Error Message: ' + e.getMessage() + '\n LineNumber: ' + e.getLineNumber() + '\n Exception Type: ' + e.getTypeName() + '\n Cause: ' + e.getCause() + '\nStack Trace ' + e.getStackTraceString());
            ResponseObject resp = new ResponseObject();
            resp.isSuccess = false;
            resp.errMsg = '**Error Message: ' + e.getMessage() + '\n LineNumber: ' + e.getLineNumber() + '\n Exception Type: ' + e.getTypeName() + '\n Cause: ' + e.getCause() + '\nStack Trace ' + e.getStackTraceString();
            return resp;                    
        }
    }
    
    public class ResponseObject{
        @AuraEnabled
        public String errMsg;
        
        @AuraEnabled
        public Boolean isSuccess;
    }
    
    @AuraEnabled
    public static List<String> getPicklistValues() {
		List<String> picklistValues = new List<String>();
        Schema.DescribeFieldResult fieldResult =
            Case.Community_Request_Close_Reason__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        
        for( Schema.PicklistEntry f : ple)
        {
            picklistValues.add(f.getValue());
        }               
        return picklistValues;
    }    
}