/**
* @author HZ
* @date 2019
*
* @description helper class for querying multiple AppLogDetail__c records in flows
*   2019-11-25 : Initial creation
*/

global with sharing class AppLogDetailHelper {

    global class GetAppLogDetailParams {
        
        @InvocableVariable (required=true)
        global String recIds;
    }
    
    @InvocableMethod(label = 'Get Display AppLogDetail')
    public static List<List<AppLogDetail__c>> getAppLogDetail(List<GetAppLogDetailParams> params){
        
        //return list of lists for flow
        List<List<AppLogDetail__c>> wrapper = new List<List<AppLogDetail__c>>();        
        List<AppLogDetail__c> appLogDisplay = [SELECT Id, RefRecordID__c, display__c FROM AppLogDetail__c
                                                   WHERE display__c =TRUE AND RefRecordID__c IN: params[0].recIds.split(',')];

        wrapper.add(appLogDisplay);
        return wrapper;
    }
}