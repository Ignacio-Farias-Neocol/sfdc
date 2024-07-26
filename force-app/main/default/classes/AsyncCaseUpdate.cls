// Test Class: CaseModelTest
public class AsyncCaseUpdate implements Queueable {
    
    // get the case id
    public Set<Id> caseIdSet;
        
    public void execute(QueueableContext context) {
        System.debug('##caseIdSet:: ' + JSON.serialize(caseIdSet));
		List<Case> listOfCase = [Select Id, Callback_Date_Time__c, Callback_TimeZone__c, Send_Email_Alert_Before_30__c from Case where Id =: caseIdSet];   
        System.debug('##listOfCase:: ' + JSON.serialize(listOfCase));
        if(listOfCase.size() > 0){
            List<PicklistEntry> entries = Schema.SObjectType.User.fields.TimeZoneSidKey.picklistValues;
            System.debug(entries);
            Map<String, String> timeZoneMap = new Map<String, String>();
            for(PicklistEntry pe: entries){
                timeZoneMap.put(pe.getLabel().substring(0,11), pe.getValue());
            }
            
            for(Case objCase : listOfCase){
                if(objCase.Callback_Date_Time__c != null && objCase.Callback_TimeZone__c != null){
                    DateTime callBackTime = objCase.Callback_Date_Time__c.addMinutes(30);
                    DateTime dt = DateTime.newInstanceGMT(callBackTime.year(), callBackTime.month(), callBackTime.day(), callBackTime.hour(), callBackTime.minute(), callBackTime.second());
                    System.debug('##gmt time:: ' + dt);
                    String timeZoneString = timeZoneMap.get(objCase.Callback_TimeZone__c.substring(0, 11));    
                    if(objCase.Callback_TimeZone__c == '(GMT-05:00) Eastern Time (US and Canada)'){
                        timeZoneString = 'America/New_York';
                    } else if(objCase.Callback_TimeZone__c == '(GMT-06:00) Central Time (US and Canada'){
                        timeZoneString = 'America/Chicago';
                    } else if(objCase.Callback_TimeZone__c == '(GMT-08:00) Pacific Time (US and Canada); Tijuana'){
                        timeZoneString = 'America/Los_Angeles';
                    }     
                    System.debug('##timeZoneString:: ' + timeZoneString);  
                    if(!String.isBlank(timeZoneString)){
                    Timezone tz = Timezone.getTimeZone(timeZoneString); 
                    System.debug('##offset:: ' + tz.getOffset(dt));
                    DateTime callBack = DateTime.newInstance(dt.getTime() - tz.getOffset(dt));
                    System.debug('##callBack:: ' + callBack);
                    objCase.Send_Email_Alert_Before_30__c = callBack;  
                    objCase.Callback_Date__c = objCase.Callback_Date_Time__c.date();
                    objCase.Callback_Time__c = objCase.Callback_Date_Time__c.time();   
                    objCase.Agent_Callback_Date_Time__c = callBack.addMinutes(-30);
                    System.debug('##AgentCallback:: ' + objCase.Agent_Callback_Date_Time__c);
                    }
                }
            }            
        }
        
        update listOfCase;
    }
}