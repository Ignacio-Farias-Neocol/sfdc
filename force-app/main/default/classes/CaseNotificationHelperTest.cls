/* @Modification
* SFDC-13763: Changed code to replace From_Address__c to From_Address_New__c
*/

@isTest
public class CaseNotificationHelperTest {
    
    @isTest
    static void testMethod1(){
        CaseNotificationHelper.sendCaseNotificationsForAmericas();
    }
}