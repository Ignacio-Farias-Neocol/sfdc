/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 01-26-2023
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public without sharing class SplashPageController {
    @AuraEnabled
    public static Map<String, Object> initData() {
        Map<String, Object> responseObj = new Map<String,Object>();
        responseObj.put('status', true);

        List<String> validProfileList = new List<String>{
            'Barracuda Partner Distributor Admin',
            'Barracuda Partner Affiliate Admin',
            'Barracuda Partner Core Admin',
            'Barracuda Partner Hybrid Admin',
            'Barracuda Partner MSP Admin',
            'Apollo: Barracuda CCPlus Admin Login Profile'
        };
        List<User> currentUserList = 
            [
                SELECT  
                    Id,
                    First_Session_Date__c, 
                    Second_Session_Date__c, 
                    Third_Session_Date__c, 
                    All_Session_Complete_Date__c, 
                    Is_Show_Splash__c, 
                    AccountId,
                    VF_Session_Id__c 
                FROM  User
                WHERE Id=: UserInfo.getUserId()
                AND Profile.Name IN:validProfileList
               // AND Account.Security_Contact_Provided__c = false
            ];
        if(currentUserList.isEmpty() && !Test.isRunningTest()){
            responseObj.put('isShowSplash', false);
            return responseObj;
        }else{
           
            currentUserList = 
                [
                    SELECT  
                        Id,
                        First_Session_Date__c, 
                        Second_Session_Date__c, 
                        Third_Session_Date__c, 
                        All_Session_Complete_Date__c, 
                        Is_Show_Splash__c, 
                        AccountId,
                        VF_Session_Id__c 
                    FROM  User
                    WHERE Id=: UserInfo.getUserId()
                ];
        }
        User currentUserObj = currentUserList[0];
        List<Contact> securitycontactlist = [Select id, Security_Notice_Contact__c from Contact where AccountId =: currentUserObj.AccountId 
                                            and Security_Notice_Contact__c = true];
        if(!securitycontactlist.isEmpty() && !Test.isRunningTest()){
            responseObj.put('isShowSplash', false);
            return responseObj;
        }

       
        Boolean isShowSplash = true;
        Boolean isValidSession = true;
        String sessionId =  LexSessionController.fetchUserSessionId();
        if(sessionId == currentUserObj.VF_Session_Id__c && currentUserObj.Is_Show_Splash__c){
            isValidSession = false;
            isShowSplash = false;
        }else{
            isValidSession = true;
            //currentUserObj.VF_Session_Id__c = sessionId;
            //currentUserObj.Is_Show_Splash__c = true;
        }

        Boolean isOldSessionInavlid = false;
        // Date Logic
        if(currentUserObj.All_Session_Complete_Date__c != null){
            isShowSplash = false;
            isOldSessionInavlid = true;
        }else if(currentUserObj.Third_Session_Date__c != null 
            && (currentUserObj.Third_Session_Date__c.addDays(7) <= Date.today()) ){
                isOldSessionInavlid = true;
                currentUserObj.All_Session_Complete_Date__c = Date.today();
        }else if(currentUserObj.Second_Session_Date__c != null 
            && (currentUserObj.Second_Session_Date__c.addDays(7) <= Date.today()) ){
                isOldSessionInavlid = true;
                currentUserObj.Third_Session_Date__c = Date.today();
        }else if(currentUserObj.First_Session_Date__c != null 
            && (currentUserObj.First_Session_Date__c.addDays(7) <= Date.today()) ){
                isOldSessionInavlid = true;
                currentUserObj.Second_Session_Date__c = Date.today();
        }else if( currentUserObj.First_Session_Date__c == null ){
            isShowSplash = true;
        }

        update currentUserObj;
       responseObj.put('isShowSplash', isShowSplash);

        //responseObj.put('isShowSplash', false);
        return responseObj;
    }

    @AuraEnabled
    public static Map<String, Object> dismissSplash() {
        Map<String, Object> responseObj = new Map<String,Object>();
        responseObj.put('status', true);
        User currentUserObj = 
            [
                SELECT  
                    Id,
                    First_Session_Date__c, 
                    Second_Session_Date__c, 
                    Third_Session_Date__c, 
                    All_Session_Complete_Date__c, 
                    Is_Show_Splash__c, 
                    VF_Session_Id__c 
                FROM  User
                WHERE Id=: UserInfo.getUserId()
            ];
        String sessionId =  LexSessionController.fetchUserSessionId();
        currentUserObj.VF_Session_Id__c = sessionId;
        currentUserObj.Is_Show_Splash__c = true;
        if(currentUserObj.First_Session_Date__c == null){
            currentUserObj.First_Session_Date__c = Date.today();
        }
        update currentUserObj;
        return responseObj;
    }
}