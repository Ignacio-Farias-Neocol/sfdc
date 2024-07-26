/**
 * 
 * @File Name          : ComplianceDPLCheckController.apxc
 * @Description        : This controller will take the field names in the Fieldset defined in the component attribute, build a dynamic query to query the Opportunity to get those fields.
 * @Author             : Bhavesh Jha
 * 
**/
public class ComplianceDPLCheckController {
    
    private static final String ACCOUNT_PREFIX = '001';
    private static final String CONTACT_PREFIX = '003';
    
    @AuraEnabled
    public static Object getRecords(String recordId, String fieldSetName) {
        try{
            if(fieldSetName != null && fieldSetName != '' && recordId != null){
                
                List<ResponseWrapper> responseWrapperList = new List<ResponseWrapper>();
                List<Opportunity> mOpportunityList = Database.query(getDynamiCSOQL(fieldSetName,recordId));
                Set<String> relatedRecordIds = new Set<String>();
                Set<String> accIds = new Set<String>();
                Set<String> conIds = new Set<String>();
                for(Opportunity opp: mOpportunityList){
                    for(Schema.FieldSetMember fieldMember : readFieldSet(fieldSetName)) {
                        if(opp.get(fieldMember.getFieldPath()) != null){
                            relatedRecordIds.add(String.valueof(opp.get(fieldMember.getFieldPath())).subString(0,18));
                            if(String.valueof(opp.get(fieldMember.getFieldPath())).startswith(ComplianceDPLCheckController.ACCOUNT_PREFIX)){
                                accIds.add(String.valueof(opp.get(fieldMember.getFieldPath())).subString(0,18));
                            }
                            if(String.valueof(opp.get(fieldMember.getFieldPath())).startswith(ComplianceDPLCheckController.CONTACT_PREFIX)){
                                conIds.add(String.valueof(opp.get(fieldMember.getFieldPath())).subString(0,18));
                            }
                        }
                    }
                }
                Map<String,String> relatedObjectIdVsNameMap = new Map<String,String>();
                if(!accIds.isEmpty()){
                    for(Account mAccount: [Select id,Name from Account where Id in: accIds]){
                        relatedObjectIdVsNameMap.put(mAccount.Id,mAccount.Name);
                    }
                }
                if(!conIds.isEmpty()){
                    for(Contact mContact: [Select id,Name from Contact where Id in: conIds]){
                        relatedObjectIdVsNameMap.put(mContact.Id,mContact.Name);
                    }
                }
                System.debug('getRecords :: relatedObjectIdVsNameMap::'+JSON.serialize(relatedObjectIdVsNameMap));
                /*
                 * assuming that Result stored in 
                 * `{"result" : "SUCCESS || FAILURE", "message" : "Error or Success Message."}` format.
                **/
                //
                System.debug('relatedObjectIdVsNameMap:::::::'+JSON.serialize(relatedObjectIdVsNameMap));
                System.debug('relatedObjectIdVsNameMap:::::::'+JSON.serialize(relatedObjectIdVsNameMap));
                System.debug('relatedRecordIds:::::::'+JSON.serialize(relatedRecordIds));
                if(!relatedRecordIds.isEmpty()){
                    for(Compliance_Log__c mComplianceLog: [Select id, Result__c, Record_ID__c from Compliance_Log__c where Record_ID__c in: relatedRecordIds]){
                        System.debug('getRecords :: mComplianceLog::'+JSON.serialize(mComplianceLog));
                        ComplianceLogResultWrapper mComplianceLogResultWrapper = new ComplianceLogResultWrapper();
                        try{
                            System.debug('getRecords :: mComplianceLog.Result__c::'+mComplianceLog.Result__c);
                            if(mComplianceLog.Result__c != null && !String.isEmpty(mComplianceLog.Result__c)){
                                mComplianceLogResultWrapper = (ComplianceLogResultWrapper)JSON.deserialize(mComplianceLog.Result__c, ComplianceLogResultWrapper.class);
                            }
                        }catch(Exception e){
                            System.debug(':::::::::::::Unable to parse Result String:::::::::::::');
                            mComplianceLogResultWrapper = new ComplianceLogResultWrapper();
                        }
                        if(mComplianceLogResultWrapper != null && mComplianceLogResultWrapper.result != null){
                            if(mComplianceLogResultWrapper.result.equals('FAILURE')){
                                responseWrapperList.add(new ResponseWrapper(relatedObjectIdVsNameMap.get(mComplianceLog.Record_ID__c),mComplianceLogResultWrapper.message));
                            }
                        }
                    }
                }
                return responseWrapperList;
            }else{
                return new List<Compliance_Log__c>();
            }
        }catch(Exception e){
            System.debug('There is error while Fetching Opportunity while getRecords, Error Detail - '+e.getMessage());
        }
        return null;
    }
    
    private static List<Schema.FieldSetMember> readFieldSet(String fieldSetName){
        
        Map<String, Schema.SObjectType> mGlobalDescribeMap = Schema.getGlobalDescribe(); 
        Schema.SObjectType mSObjectTypeObj = mGlobalDescribeMap.get('Opportunity');
        Schema.DescribeSObjectResult describeSObjectResultObj = mSObjectTypeObj.getDescribe();
        Schema.FieldSet fieldSetObj = describeSObjectResultObj.FieldSets.getMap().get(fieldSetName);
        return fieldSetObj.getFields(); 
    }  
    
    /**
    * On basis of field set, Create Dynamic SOQL
    **/
    private static String getDynamiCSOQL(String fieldSetName,String recordId) {
        try{
            Set<String> queryFields = new Set<String>();
            for(Schema.FieldSetMember f : readFieldSet(fieldSetName)) {
                queryFields.add(f.getFieldPath());
            }
            String query = 'SELECT '+String.join(new List<String>(queryFields), ',')+' FROM Opportunity WHERE Id = \''+recordId+'\'';
            return query;
        }
        catch(Exception e){
            System.debug('There is error while Fetching Opportunity using Dynamic SOQL in Field Set. Error Detail - '+e.getMessage()); //This is Utility Method to display error message on VF Page
        }
        return null;
    }
    
    /**
     * Modify as per result format :: assumed stored `Result__c` format.
    **/
    public class ComplianceLogResultWrapper{
        public String result;
        public String message;
    }
    
    /**
     * To give response to aura component in form of `List<ResponseWrapper>`
    **/
    public class ResponseWrapper{
        @AuraEnabled public String name;
        @AuraEnabled public String errorMessage;
        responseWrapper(String name,String errormessage){
            this.name = name;
            this.errorMessage = errormessage;
        }
    }
}