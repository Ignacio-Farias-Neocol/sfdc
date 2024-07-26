public class TriggerContextVariables {	
    Public static Boolean RUN_ACCOUNT_TRIGGER = true; 
    Public static Boolean RUN_CASE_TRIGGER = true;    
    public static Boolean RUN_ORDERLINE_TRIGGER = true;
    public static Boolean RUN_ORDER_TRIGGER = true;
    public static Boolean RUN_OPPORTUNITY_TRIGGER = true;
    
    public static Boolean IS_1ST_RUN_updateComplianceStatus_COMPLETED = false;
    public static Boolean IS_1ST_RUN_afterUpdateClosedCaseReason_COMPLETED = false;
    
    public static List<User> mulesoftUserRecords;
    
    public static List<User> getMulesoftUsers(){
        if(mulesoftUserRecords != null){
            return mulesoftUserRecords;
        } else {
            mulesoftUserRecords = [SELECT Id FROM User WHERE Name = 'Integration Mulesoft' LIMIT 1];
            return mulesoftUserRecords;
        }
    }
}