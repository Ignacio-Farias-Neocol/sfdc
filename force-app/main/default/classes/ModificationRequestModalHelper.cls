public without sharing class ModificationRequestModalHelper {
    
    @AuraEnabled
    public static void createRequest(Map<String, String> fields) {
        Schema.DescribeSObjectResult caseDescribe = Schema.SObjectType.Case; 
        Map<String,Schema.RecordTypeInfo> rtMapByName = caseDescribe.getRecordTypeInfosByDeveloperName();

        Case caseRecord = new Case();
        // Aditya - Added logic to check Community User
        if(!Boolean.valueOf(fields.get('isCommunityUser'))){
            caseRecord.Opportunity_for_SE_Cases__c = fields.get('Opportunity_for_SE_Cases__c');
        }
        caseRecord.AccountId = fields.get('AccountId');
        if(fields.containsKey('Related_Account__c') && String.isNotBlank(fields.get('Related_Account__c'))) {
            caseRecord.Related_Account__c = fields.get('Related_Account__c');
        }
        caseRecord.RecordTypeId = rtMapByName.get('Community_Quote').getRecordTypeId();
        caseRecord.Subject = fields.get('Subject');

        if(fields.containsKey('g_Change_User_Count__c') && Boolean.valueOf(fields.get('g_Change_User_Count__c'))) {
            caseRecord.g_Change_User_Count__c = true;
            caseRecord.g_Change_User_Count_Details__c = Integer.valueOf(fields.get('g_Change_User_Count_Details__c'));
        }

        if(fields.containsKey('g_Co_Term_Modify_End_Date__c') && Boolean.valueOf(fields.get('g_Co_Term_Modify_End_Date__c'))) {
            caseRecord.g_Co_Term_Modify_End_Date__c = true;
            caseRecord.g_Co_Term_Modify_End_Date_Details__c = Date.valueOf(fields.get('g_Co_Term_Modify_End_Date_Details__c'));
        }

        if(fields.containsKey('g_Modify_Subscriptions__c') && Boolean.valueOf(fields.get('g_Modify_Subscriptions__c'))) {
            caseRecord.g_Modify_Subscriptions__c = true;
            caseRecord.g_Modify_Subscriptions_Detail__c = fields.get('g_Modify_Subscriptions_Detail__c');
        }

        if(fields.containsKey('g_Will_Not_Renew__c') && Boolean.valueOf(fields.get('g_Will_Not_Renew__c'))) {
            caseRecord.g_Will_Not_Renew__c = true;
            caseRecord.g_Will_Not_Renew_Details__c = fields.get('g_Will_Not_Renew_Details__c');
        }

        if(fields.containsKey('g_Other__c') && Boolean.valueOf(fields.get('g_Other__c'))) {
            caseRecord.g_Other__c = true;
            caseRecord.g_Other_Details__c = fields.get('g_Other_Details__c');
        }

        try {
            //Aditya's Change
            List<AssignmentRule> assignRules = new List<AssignmentRule>();
            assignRules = [select id from AssignmentRule where SobjectType = 'Case' and Active = true and Name ='Case - Community Quote Assignment'];
            Database.DMLOptions dmlOpts = new Database.DMLOptions();
            if(assignRules != null && assignRules.size()>0){
                dmlOpts.assignmentRuleHeader.assignmentRuleId= assignRules[0].id;
                caseRecord.setOptions(dmlOpts);
            }
            insert caseRecord;
        } catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }

}