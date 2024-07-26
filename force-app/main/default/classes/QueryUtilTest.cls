@isTest
public class QueryUtilTest {
    @isTest static void unitTest(){
        String queryALLFieldsWithAccountPayload = '';
                    
        string additionalAccountALLFields = QueryUtil.getWholeParentAdditionalFields('Account','Account__r');
        
        queryALLFieldsWithAccountPayload = QueryUtil.getWholeFieldsQuery('Address__c','id != null',additionalAccountALLFields);
    }
}