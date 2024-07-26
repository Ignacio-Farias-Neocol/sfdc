/* @Modification
* SFDC-13763: Changed code to replace From_Address__c to From_Address_New__c

*/
public class CaseNotificationHelper {
    
    public static void sendCaseNotificationsForAmericas(){
        Integer a = 5;
        Integer b = 5;
        Integer c = a + b;
        /*
        try {
            System.debug('##em:: ' + JSON.serialize(emList));            
            // send Email to the group
            PremiumSupportNotification.sendEmail(emList[0], fromAddressNew);
            
            /*
            // Send bell notification
            Messaging.CustomNotification obj = new Messaging.CustomNotification();
            List<CustomNotificationType> notificationTypeList = [SELECT Id, CustomNotifTypeName, DeveloperName from CustomNotificationType where CustomNotifTypeName = 'Chatter Post'];
            obj.setNotificationTypeId(notificationTypeList[0].Id);
            obj.setTargetId(emList[0].Id);
            obj.setTitle('New Premium Support Web Message – Case ' + emList[0].CaseNumber__c);
            String strBody = 'From Address : ' + emList[0].FromAddress + '\n' + 'Case Number : ' + emList[0].CaseNumber__c + '\n' + 'Subject : ' + emList[0].Subject;
            obj.setBody(strBody);
            List<Group> groupList = [Select Id from Group where DeveloperName = 'Americas_Premium'];
            Set<String> groupIdSet = new Set<String>{groupList[0].Id};
                obj.send(groupIdSet); 
			
        } catch(Exception e){
            System.debug('**Error Message: ' + e.getMessage() + '\n LineNumber: ' + e.getLineNumber() + '\n Exception Type: ' + e.getTypeName() + '\n Cause: ' + e.getCause() + '\nStack Trace ' + e.getStackTraceString());            
        }
    	*/
    }
}