@isTest(SeeAllData=true)
public class RHX_TEST_Assigned_Serial {
	static testMethod void RHX_Testmethod() {
        List<sObject> sourceList = [SELECT Id 
			FROM Assigned_Serial__c LIMIT 1];
        if(sourceList.size() == 0) {
            sourceList.add(
                    new Assigned_Serial__c()
            );
        }
    	rh2.ParentUtil.UpsertRollupTestRecords( sourceList );
    }
}