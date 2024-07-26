public with sharing class CaseCustomButtonActions {


    private final static String CASE_TYPE_DPAAS = 'DPAAS Cases';
    private static Id theCaseId = null;

    private static Case pCase = null;
    public static Case theCase{
        get {
            if (pCase == null) {
                for (Case c: [select Id, Closed_Case_Reason__c,  Case_Reason__c,
                        Sub_Reason__c,  Product_Family_List__c, DPaaS_Problem__c, // Case_Sub_Reason__c,
                        Status, recordTypeId, RecordType.Name  from Case where id = :theCaseId ]){
                    pCase = c;
                }
            }
            return pCase;
        }
    }


	@AuraEnabled
	public static Case_Quick_Action_Button__mdt[] getCustomButtonActionOptions(Id recordId) {

        // find the record type of the case
        theCaseId = recordId;
        String theCaseType = '';
        if (theCase != null){
            theCaseType = theCase.RecordType.Name;
        }
		return  [SELECT Id, Label FROM Case_Quick_Action_Button__mdt where Record_Type__c =:theCaseType ];
	}

    @AuraEnabled
    public static void performQuickAction(Id caseId, Id caseQuickActionButton) {

        Case_Quick_Action_Button__mdt cqab = [SELECT Case_Comment__c, Status__c, Problem__c, Level_1__c, Level_2__c,
                Level_3__c, Level_4__c, Level_5__c
        FROM Case_Quick_Action_Button__mdt WHERE Id = :caseQuickActionButton];

        createCaseComment(caseId, cqab.Case_Comment__c);

        theCaseId = caseId;
        theCase.Status = cqab.Status__c;
        theCase.DPaaS_Problem__c = cqab.Problem__c;
        theCase.Product_Family_List__c = cqab.Level_1__c;
        theCase.Case_Reason__c = cqab.Level_2__c;
        // theCase.Case_Sub_Reason__c = cqab.Level_3__c;
        theCase.Sub_Reason__c = cqab.Level_3__c;
        theCase.Closed_Case_Reason__c = cqab.Level_4__c;
        update theCase;
    }
  
    private static void createCaseComment(Id caseId, String comment) {
        CaseComment cc = new CaseComment(
            CommentBody = comment,
            ParentId = caseId
        );
        insert cc;
    }
	
//    @AuraEnabled
//    public static void shutdown(Id caseId) {
//    	createCaseComment(caseId, 'Bring this machine back online and make sure it isn\'t shut down during future backups.');
//    	/*
//    	Case supportCase = [SELECT Status, Problem__c, Level_1__c, Level_2__c, Level_3__c, Level_4__c, Level_5__c FROM CASE WHERE Id = :caseId];
//		supportCase.Status = 'Pending';
//		supportCase.Problem__c = 'The agent received a computer shutdown notification';
//		supportCase.Level_1__c = 'DPaaS';
//		supportCase.Level_2__c = 'Backup';
//		supportCase.Level_3__c = 'B-Files & Folders';
//		supportCase.Level_4__c = 'System Shutdown';
//		supportCase.Level_5__c = 'System Unavailable';
//		update supportCase;
//		*/
//    }
//
//    @AuraEnabled
//    public static void systemDate(Id caseId) {
//        createCaseComment(caseId, 'Make sure the scratch drive has enough free space and does not contain critical data. Check the Windows Event Viewer and Windows Server Backup logs for additional information on the errors. You can also run \'wbadmin get status\' in command prompt while the backup is running to see what errors are reported by Windows.');
//        /*
//    	Case supportCase = [SELECT Status, Problem__c, Level_1__c, Level_2__c, Level_3__c, Level_4__c, Level_5__c FROM CASE WHERE Id = :caseId];
//		supportCase.Status = 'Pending';
//		supportCase.Problem__c = 'System State failed with Exit Code -3';
//		supportCase.Level_1__c = 'DPaaS';
//		supportCase.Level_2__c = 'Backup';
//		supportCase.Level_3__c = 'B-System State';
//		supportCase.Level_4__c = 'Failing - System State';
//		supportCase.Level_5__c = 'Exit Code 3';
//		update supportCase;
//		*/
//    }
//
//    @AuraEnabled
//    public static void dpass(Id caseId) {
//        createCaseComment(caseId, 'Please make sure the backup agent service is started. If not, please start it. If the agent is running, please check the up time of this machine, as it needs to be active for our backups to run.');
//        /*
//		Case supportCase = [SELECT Status, Problem__c, Level_1__c, Level_2__c, Level_3__c, Level_4__c, Level_5__c FROM CASE WHERE Id = :caseId];
//		supportCase.Status = 'Pending - DPaaS MB';
//		supportCase.Problem__c = 'Missed Backup';
//		supportCase.Level_3__c = 'B-Files & Folders';
//		supportCase.Level_4__c = 'Missed Backup';
//		supportCase.Level_5__c = 'System Unavailable';
//		update supportCase;
//		*/
//    }
//
//    @AuraEnabled
//    public static void localVault(Id caseId) {
//        createCaseComment(caseId, 'Make sure the local vault is online and credentials are set correctly in the share manager.');
//        /*
//		Case supportCase = [SELECT Status, Problem__c, Level_1__c, Level_2__c, Level_3__c, Level_4__c, Level_5__c FROM CASE WHERE Id = :caseId];
//		supportCase.Status = 'Pending';
//		supportCase.Problem__c = 'Local Vault Disconnected';
//		supportCase.Level_1__c = 'DPaaS';
//		supportCase.Level_2__c = 'Backup';
//		supportCase.Level_3__c = 'B-Files & Folders';
//		supportCase.Level_4__c = 'Other Errors';
//		update supportCase;
//		*/
//    }

}