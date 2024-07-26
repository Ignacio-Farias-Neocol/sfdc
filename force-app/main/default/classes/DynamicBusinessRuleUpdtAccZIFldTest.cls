/**
* @author Dilowar Hussain
* @date 2023-07-11
*
* @description 
* 
* Test Class for the main class, DynamicBusinessRuleUpdateAccZIField
* 
* This has been added as a part of SFDC-19424
*/
@isTest
public class DynamicBusinessRuleUpdtAccZIFldTest {
	/**
     * TestMethod
     */
    public testMethod static void testAccZIEnrichChecked(){
        try{
            List<Account> newAccount = TestDataFactory.customers;
            List<Contact> cusCon = TestDataFactory.customerContacts;
            Test.startTest();
                cusCon[0].accountId = newAccount[0].id;
                cusCon[0].DOZISF__ZoomInfo_Id__c = '12345';
                update cusCon;
            Test.stopTest();
        }Catch(Exception e){
            system.debug('Exception occurred at:' +e.getStackTraceString());
        }
    }
    public testMethod static void testAccZIEnrichUnChecked(){
        try{
            List<Account> newAccount = TestDataFactory.customers;
            List<Contact> cusCon = TestDataFactory.customerContacts;
            Test.startTest();
                cusCon[0].accountId = newAccount[0].id;
                cusCon[0].DOZISF__ZoomInfo_Id__c = NULL;
                update cusCon;
            Test.stopTest();
        }Catch(Exception e){
            system.debug('Exception occurred at:' +e.getStackTraceString());
        }
    }
}