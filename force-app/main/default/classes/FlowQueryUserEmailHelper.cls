/**
* @author HZ
* @date 2020
*
* @description helper class for querying user emails using collections of user ids in flows
*   2020-02-04 : Initial creation
*/

global with sharing class FlowQueryUserEmailHelper {

    global class GetParams {        
        @InvocableVariable (required=true)
        global List<Id> recIds;
    }
    
    @InvocableMethod(label = 'Get Emails')
    public static List<List<String>> getRecords(List<GetParams> params){
        
        //return list of lists for flow
        List<List<String>> wrapper = new List<List<String>>();        
        List<String> emails = new List<String>();
        for(User users : [SELECT Email FROM User WHERE Id IN: params[0].recIds]){
            emails.add(users.email);
        }

        wrapper.add(emails);
        return wrapper;
    }
}