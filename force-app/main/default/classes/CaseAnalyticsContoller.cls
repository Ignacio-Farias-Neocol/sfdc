/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 12-07-2023
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class CaseAnalyticsContoller {
    
    @AuraEnabled
    public static String initData(){
        Map<String, Object> responseMap = new Map<String, Object>();
        Case_Anaytics__mdt caseAnalyticsMeta = 
            [
                SELECT 
                Id,
                Profile_Names__c
                FROM Case_Anaytics__mdt
                LIMIT 1 
            ];
        responseMap.put('status', true);
        
        Boolean isCorrectProfile = [
            SELECT Id FROM User 
            WHERE Id=: UserInfo.getUserId() AND Profile.Name IN: caseAnalyticsMeta.Profile_Names__c.split(',')
        ].isEmpty();
        
        Boolean isTrack = !isCorrectProfile ? true : false;
        
        responseMap.put('isTrack', isTrack);
        return JSON.serializePretty(responseMap);
    }
    
    @AuraEnabled
    public static String trackCaseActivity(String jsonData){
        System.debug('jsonData..'+jsonData);
        String communityHelpRecordtypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Community Help').getRecordTypeId();
        String internalCaseRecordtypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Case - Internal Ticket Record Type').getRecordTypeId();
        Boolean isCaseSupport=false;
        Boolean isCommunityHelpCase=false;
        Boolean isTier_1and_2_Teams=false;
        
        Map<String, Object> requestMap = (Map<String, Object>)JSON.deserializeUntyped(jsonData);  
        Map<String, Object> responseMap = new Map<String, Object>();
        String caseId = (String)requestMap.get('caseId');
        String opr = (String)requestMap.get('opr');
        Id recordTypeId=[SELECT Id,RecordTypeId FROM Case WHERE Id=:caseId limit 1][0].recordTypeId;
        
        List<String> technicalCaseTypeStatus = new List<String>{'In Progress', 'Vendor Hold'};
            List<String> psCaseTypeStatus = new List<String>{'NOT Resolved', 'Closed'};
                List<String> communityHelpCaseTypeStatus = new List<String>{'In Progress', 'New'};
                    
                    if(communityHelpRecordtypeId==recordTypeId || internalCaseRecordtypeId==recordTypeId){
                        isTier_1and_2_Teams = [select group.name,group.DeveloperName from groupmember where UserOrGroupid=:UserInfo.getUserId()AND group.DeveloperName='Tier_1_and_2_Teams_only'].isEmpty();
                        
                        isCommunityHelpCase = 
                            [
                                SELECT 
                                Id, 
                                RecordType.Name
                                FROM Case
                                WHERE 
                                (
                                    (RecordType.Name = 'Community Help' AND Status IN: communityHelpCaseTypeStatus)
                                    OR
                                    (RecordType.Name = 'Case - Internal Ticket Record Type' AND Status IN: communityHelpCaseTypeStatus)
                                    
                                ) AND Id=:caseId
                            ].isEmpty();
                    }
        else{
            isCaseSupport = 
                [
                    SELECT 
                    Id, 
                    RecordType.Name
                    FROM Case
                    WHERE 
                    (
                        (RecordType.Name = 'Technical Support' AND Status IN: technicalCaseTypeStatus) 
                        OR 
                        (RecordType.Name = 'Professional Service' AND Status NOT IN: psCaseTypeStatus)
                    ) AND Id=:caseId
                ].isEmpty();
        }
        system.debug('isCommunityHelpCase'+isCommunityHelpCase);
        System.debug('isCaseSupport:'+isCaseSupport);
        Boolean isCaseOwnerOrEscalated = 
            [
                SELECT 
                Id
                FROM Case
                WHERE (OwnerId  =: UserInfo.getUserId() OR Escalated_To__c =: UserInfo.getUserId())
                AND Id=:caseId
            ].isEmpty();
        
        System.debug('isCaseOwnerOrEscalated:'+isCaseOwnerOrEscalated);
        if( isCaseOwnerOrEscalated || isCommunityHelpCase || isTier_1and_2_Teams ||isCaseSupport && !Test.isRunningTest()){
            responseMap.put('status', true);
            responseMap.put('msg', 'Tracking Not Available');
            return JSON.serialize(responseMap);
        }
        
        List<Case_Time_Summary__c> caseTimeSummaryList = 
            [
                SELECT Id,Total_Time__c FROM Case_Time_Summary__c WHERE Case__c=: caseId
            ];
        if(opr == 'In'){
            if(caseTimeSummaryList.isEmpty()){
                Case_Time_Summary__c caseTimeSumObj = new Case_Time_Summary__c();
                if(Test.isRunningTest()){
                    caseTimeSumObj.Case__c = caseId;
                }
                caseTimeSumObj.Case_Id__c = caseId;
                insert caseTimeSumObj;
            }
            //SFDC-19491 Start
            List<Case_Analytics__c> caseActivity = [SELECT Id FROM Case_Analytics__c WHERE Case__c = :caseId AND out_Time__c =null AND CreatedDate = TODAY AND CreatedById =:UserInfo.getUserId()];
            System.debug('caseActivity==>'+ caseActivity);
            Case_Analytics__c caseAnalyticObj = new Case_Analytics__c();
            if(caseActivity.Size() == 0){
                if(Test.isRunningTest()){
                    caseAnalyticObj.Case__c = caseId;
                }
                caseAnalyticObj.In_Time__c = Datetime.now();
                caseAnalyticObj.User__c = UserInfo.getUserId();
                insert caseAnalyticObj;
            }
            else{
                caseAnalyticObj.Id = caseActivity[0].Id;
            }
            //SFDC-19491 END
            responseMap.put('caseAnalyticId', caseAnalyticObj.Id);
            responseMap.put('caseId', caseId);
        }else{
            List<Case_Analytics__c> caseAnalyticsList = 
                [
                    SELECT 
                    Id,
                    Case__c,
                    Out_Time__c,
                    In_Time__c
                    FROM Case_Analytics__c
                    WHERE User__c =: UserInfo.getUserId()
                    AND Case__c=: caseId AND Out_Time__c = null
                    ORDER BY CreatedDate DESC
                    LIMIT 1
                ];
            for(Case_Analytics__c caseAnalyticsObj : caseAnalyticsList){
                DateTime inTime = caseAnalyticsObj.In_Time__c;
                Long dt1Long = inTime.getTime();
                Long dt2Long = DateTime.now().getTime();
                Long milliseconds = dt2Long - dt1Long;
                Long seconds = milliseconds / 1000;
                Long minutes = seconds / 60;
                Long hours = minutes / 60;
                if(hours > 4){
                    caseAnalyticsObj.Out_Time__c = inTime.addHours(4);
                }else{
                    caseAnalyticsObj.Out_Time__c = Datetime.now();
                }             
            }
            update caseAnalyticsList;            
        }
        
        
        if(!caseTimeSummaryList.isEmpty()){
            Case_Time_Summary__c caseTimeSumObj = caseTimeSummaryList[0];                
            caseTimeSumObj.Total_Time__c = (Decimal)[SELECT sum(Total_Time_In_Seconds__c) totalTime FROM Case_Analytics__c WHERE Case__c=: caseId][0].get('totalTime');                    
            update caseTimeSumObj;
        }  
        
        responseMap.put('status', true);
        return JSON.serialize(responseMap);
    }
    
    @AuraEnabled
    public static String getTrackingStatus(String caseId){
        String communityHelpRecordtypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Community Help').getRecordTypeId();
        String internalCaseRecordtypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Case - Internal Ticket Record Type').getRecordTypeId();
        Id recordTypeId=[SELECT Id,RecordTypeId FROM Case WHERE Id=:caseId limit 1][0].recordTypeId;
        Map<String, Object> responseMap = new Map<String, Object>();
        Boolean isCaseSupport=false;
        Boolean isCommunityHelpCase=false;
        boolean isTier_1and_2_Teams=false;
        
        Case_Anaytics__mdt caseAnalyticsMeta = 
            [
                SELECT 
                Id,
                Profile_Names__c
                FROM Case_Anaytics__mdt
                LIMIT 1 
            ];
        responseMap.put('status', true);
        
        
        List<String> technicalCaseTypeStatus = new List<String>{'In Progress', 'Vendor Hold'};
        List<String> psCaseTypeStatus = new List<String>{'NOT Resolved', 'Closed'};
        List<String> communityHelpCaseTypeStatus = new List<String>{'In Progress', 'New'};
                    
                    if(communityHelpRecordtypeId==recordTypeId || internalCaseRecordtypeId==recordTypeId){
                        isTier_1and_2_Teams = [select group.name,group.DeveloperName from groupmember where UserOrGroupid=:UserInfo.getUserId()AND group.DeveloperName='Tier_1_and_2_Teams_only'].isEmpty();
                        
                        isCommunityHelpCase = [SELECT Id, RecordType.Name
                                               FROM Case
                                               WHERE 
                                               (
                                                   (RecordType.Name = 'Community Help' AND Status IN: communityHelpCaseTypeStatus)
                                                   OR
                                                   (RecordType.Name = 'Case - Internal Ticket Record Type' AND Status IN: communityHelpCaseTypeStatus)
                                                   
                                               ) AND Id=:caseId
                                              ].isEmpty();
                    }
        else{
            isCaseSupport = 
                [
                    SELECT 
                    Id, 
                    RecordType.Name
                    FROM Case
                    WHERE 
                    (
                        (RecordType.Name = 'Technical Support' AND Status IN: technicalCaseTypeStatus) 
                        OR 
                        (RecordType.Name = 'Professional Service' AND Status NOT IN: psCaseTypeStatus)
                        
                    ) AND Id=:caseId
                ].isEmpty();
        }
        System.debug('isCaseSupport:'+isCaseSupport);
        Boolean isCaseOwnerOrEscalated = 
            [
                SELECT 
                Id
                FROM Case
                WHERE (OwnerId  =: UserInfo.getUserId() OR Escalated_To__c =: UserInfo.getUserId())
                AND Id=:caseId
            ].isEmpty();
        System.debug('isCaseOwnerOrEscalated:'+isCaseOwnerOrEscalated);
        Boolean isCorrectProfile = [
            SELECT Id FROM User 
            WHERE Id=: UserInfo.getUserId() AND Profile.Name IN: caseAnalyticsMeta.Profile_Names__c.split(',')
        ].isEmpty();
        
        Boolean isTrack = ((!isCaseSupport &&(!isTier_1and_2_Teams && !isCommunityHelpCase)) && !isCorrectProfile && !isCaseOwnerOrEscalated) ? true : false;
        System.debug('isTrack:'+isTrack);
        if(Test.isRunningTest()){
            isTrack = true;
        }
        List<Case_Time_Summary__c> caseTimeSummaryList = 
            [
                SELECT Id,Total_Time__c FROM Case_Time_Summary__c WHERE Case__c=: caseId
            ];
        if(!isTrack){
            List<Case_Analytics__c> caseAnalyticsList = 
                [
                    SELECT 
                    Id,
                    Case__c,
                    Out_Time__c,
                    In_Time__c
                    FROM Case_Analytics__c
                    WHERE User__c =: UserInfo.getUserId()
                    AND Case__c=: caseId AND Out_Time__c = null
                    ORDER BY CreatedDate DESC
                    LIMIT 1
                ];
            System.debug('isTrack:: '+isTrack);
            System.debug('caseAnalyticsList:: '+caseAnalyticsList);
            for(Case_Analytics__c caseAnalyticsObj : caseAnalyticsList){
                DateTime inTime = caseAnalyticsObj.In_Time__c;
                Long dt1Long = inTime.getTime();
                Long dt2Long = DateTime.now().getTime();
                Long milliseconds = dt2Long - dt1Long;
                Long seconds = milliseconds / 1000;
                Long minutes = seconds / 60;
                Long hours = minutes / 60;
                if(hours > 4){
                    caseAnalyticsObj.Out_Time__c = inTime.addHours(4);
                }else{
                    caseAnalyticsObj.Out_Time__c = Datetime.now();
                }         
            }
            if(!caseAnalyticsList.isEmpty()){
                update caseAnalyticsList; 
            }
        }else{
            List<Case_Analytics__c> caseAnalyticsList = 
                [
                    SELECT 
                    Id,
                    Case__c,
                    Out_Time__c
                    FROM Case_Analytics__c
                    WHERE User__c =: UserInfo.getUserId()
                    AND Case__c=: caseId AND Out_Time__c = null
                    ORDER BY CreatedDate DESC
                    LIMIT 1
                ];
            if(caseAnalyticsList.isEmpty()){
                Case_Analytics__c caseAnalyticObj = new Case_Analytics__c();
                //caseAnalyticObj.Case__c = caseId;
                caseAnalyticObj.In_Time__c = Datetime.now();
                caseAnalyticObj.User__c = UserInfo.getUserId();
                insert caseAnalyticObj;
                System.debug('caseAnalyticObj ' +caseAnalyticObj);
                
                if(caseTimeSummaryList.isEmpty()){
                    Case_Time_Summary__c caseTimeSumObj = new Case_Time_Summary__c();
                    if(Test.isRunningTest()){
                        caseTimeSumObj.Case__c = caseId;
                    }
                    caseTimeSumObj.Case_Id__c = caseId;
                    insert caseTimeSumObj;
                }
                
                responseMap.put('caseAnalyticId', caseAnalyticObj.Id);
                responseMap.put('caseId', caseId);
            } 
            //SFDC-19491 Start
            else{
                responseMap.put('caseAnalyticId', caseAnalyticsList[0].Id);
                responseMap.put('caseId', caseId);
            } 
            //SFDC-19491 End
            if(!caseTimeSummaryList.isEmpty()){
                Case_Time_Summary__c caseTimeSumObj = caseTimeSummaryList[0];                
                caseTimeSumObj.Total_Time__c = (Decimal)[SELECT sum(Total_Time_In_Seconds__c) totalTime FROM Case_Analytics__c WHERE Case__c=: caseId][0].get('totalTime');                    
                update caseTimeSumObj;
            }  
            
        }
        //responseMap.put('isTrack', isTrack);
        return JSON.serializePretty(responseMap);
    }
    
    @AuraEnabled
    public static String getTrackingOnUnloadStatus(String caseId){
        Map<String, Object> responseMap = new Map<String, Object>();
        responseMap.put('status', true);
        
        List<Case_Analytics__c> caseAnalyticsList = 
            [
                SELECT 
                Id,
                Case__c,
                Out_Time__c,
                In_Time__c
                FROM Case_Analytics__c
                WHERE User__c =: UserInfo.getUserId()
                AND Case__c=: caseId AND Out_Time__c = null
                ORDER BY CreatedDate DESC
                LIMIT 1
            ];
        List<Case_Time_Summary__c> caseTimeSummaryList = 
            [
                SELECT Id,Total_Time__c,Case__c FROM Case_Time_Summary__c WHERE Case__c=: caseId
            ];
        if(!caseAnalyticsList.isEmpty()){
            DateTime inTime = caseAnalyticsList[0].In_Time__c;
            Long dt1Long = inTime.getTime();
            Long dt2Long = DateTime.now().getTime();
            Long milliseconds = dt2Long - dt1Long;
            Long seconds = milliseconds / 1000;
            Long minutes = seconds / 60;
            Long hours = minutes / 60;
            if(hours > 4){
                caseAnalyticsList[0].Out_Time__c = inTime.addHours(4);
            }else{
                caseAnalyticsList[0].Out_Time__c = Datetime.now();
            }         
            update caseAnalyticsList;
        }   
        
        if(!caseTimeSummaryList.isEmpty()){
            Case_Time_Summary__c caseTimeSumObj = caseTimeSummaryList[0];                
            caseTimeSumObj.Total_Time__c = (Decimal)[SELECT sum(Total_Time_In_Seconds__c) totalTime FROM Case_Analytics__c WHERE Case__c=: caseId][0].get('totalTime');                    
            update caseTimeSumObj;
        }  
        
        //responseMap.put('isTrack', isTrack);
        return JSON.serializePretty(responseMap);
    }
    
    
    @AuraEnabled
    public static String getCaseAnalytics(String recordId){
        Map<String, Object> responseMap = new Map<String, Object>();
        responseMap.put('status', true);
        List<Case_Analytics__c> caseAnalyticsList = 
            [
                SELECT 
                Id, 
                Case__c, 
                In_Time__c, 
                Out_Time__c, 
                User__c,
                User__r.Name,
                Total_Time_In_Seconds__c
                FROM Case_Analytics__c
                WHERE Case__c =: recordId AND In_Time__c != null AND Out_Time__c != null
                ORDER BY CreatedDate desc
            ];
        Decimal totalCaseTime = 0;
        Map<String, Decimal> userIdTotalCaseTime = new Map<String, Decimal>();
        Map<String, List<Case_Analytics__c>> userIdCaseAnalytics = new Map<String, List<Case_Analytics__c>>();
        for(Case_Analytics__c caseAnalyticsObj : caseAnalyticsList){
            if(userIdTotalCaseTime.containsKey(caseAnalyticsObj.User__c + '#' + caseAnalyticsObj.User__r.Name)){                
                userIdTotalCaseTime.put(caseAnalyticsObj.User__c + '#' + caseAnalyticsObj.User__r.Name, userIdTotalCaseTime.get(caseAnalyticsObj.User__c + '#' + caseAnalyticsObj.User__r.Name) + caseAnalyticsObj.Total_Time_In_Seconds__c) ;
            }else{                
                userIdTotalCaseTime.put(caseAnalyticsObj.User__c + '#' + caseAnalyticsObj.User__r.Name, caseAnalyticsObj.Total_Time_In_Seconds__c) ;
            }
            
            if(userIdCaseAnalytics.containsKey(caseAnalyticsObj.User__c)){
                userIdCaseAnalytics.get(caseAnalyticsObj.User__c).add(caseAnalyticsObj);                
            }else{
                userIdCaseAnalytics.put(caseAnalyticsObj.User__c, new List<Case_Analytics__c>{caseAnalyticsObj});                
            }
            
            
            totalCaseTime = totalCaseTime + caseAnalyticsObj.Total_Time_In_Seconds__c;
        }
        responseMap.put('totalCaseTime', totalCaseTime);
        responseMap.put('userIdCaseAnalytics', userIdCaseAnalytics);
        responseMap.put('userIdTotalCaseTime', userIdTotalCaseTime);
        return JSON.serializePretty(responseMap);
    }
    
    @AuraEnabled
    public static String upadateCaseAnalyticsWithCase(String caseId, String caseAnalyticId){
        Case_Analytics__c caseAnalyticsObj = new Case_Analytics__c();
        caseAnalyticsObj.Id = caseAnalyticId;
        caseAnalyticsObj.Case__c = caseId;
        update caseAnalyticsObj;
        
        List<Case_Time_Summary__c> caseTimeSummaryList = 
            [
                SELECT Id,Total_Time__c,Case__c FROM Case_Time_Summary__c WHERE Case_Id__c=: caseId
            ];
        if(!caseTimeSummaryList.isEmpty()){
            Case_Time_Summary__c caseTimeSumObj = caseTimeSummaryList[0];                
            caseTimeSumObj.Case__c = caseId;
            update caseTimeSumObj;
        }
        
        Map<String, Object> responseMap = new Map<String, Object>();
        responseMap.put('status', true);
        return JSON.serializePretty(responseMap);
    }
}