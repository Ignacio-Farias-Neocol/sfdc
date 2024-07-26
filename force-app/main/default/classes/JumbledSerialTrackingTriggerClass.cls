/**
* @author        Rajesh Wani
* @date          2024-02-02
* @description   Class for JumbledSerialTrackingTrigger,JumbledSerialTrackingTrigger 
* @group         To populate Serial and Contract End date
*
*/
public class JumbledSerialTrackingTriggerClass { 
    
    public static void afterInsertAction(List<Jumbled_Serial_Tracking__c> newJumbelSerials){
    Set<String> serNums = new Set<string>();
    Map<String,Serial__c>  serMap = New Map<String,Serial__c>();
    Boolean executeBatch=false;
    for(Jumbled_Serial_Tracking__c jum:newJumbelSerials){
        if(jum.Serial_1__c!=null){
            serNums.add(jum.Serial_1__c);
        }
         if(jum.Final_Serial_For_Serial1__c!=null){
            serNums.add(jum.Final_Serial_For_Serial1__c);
        }
        
    }
    
    for(Serial__c serial:[SELECT id,Serial_Number__c,Status__c,Account__c, Is_Terminated__c,(SELECT id,Serial__c,Subscription__c,Subscription__r.SBQQ__Contract__r.enddate,Status__c,Parent_Subscription__c,Order_Order_Line_ID_Text__c,Asset__c,Order__c,Contract__c,Fulfillment_Date2__c,External_ID__c,Expire_Date__c,Qty_in_Use__c,Capacity__c,Business_Group__c,Date_Of_Replacement__c,Data_Reporting_Field__c FROM Assigned_Serials__r ORDER BY Subscription__r.SBQQ__Contract__r.enddate) FROM Serial__c WHERE Serial_Number__c IN :serNums ]){
        serMap.put(serial.Serial_Number__c,serial);
    }
    for(Jumbled_Serial_Tracking__c jum:newJumbelSerials){
         if(jum.Serial_1__c!=null && serMap.containskey(jum.Serial_1__c)){
           jum.Serial__c=serMap.get(jum.Serial_1__c).id;
               
               if(!serMap.get(jum.Serial_1__c).Assigned_Serials__r.IsEmpty()){
                   jum.Assign_Serial_Id__c='Present';
                   for(Assigned_Serial__c asg: serMap.get(jum.Serial_1__c).Assigned_Serials__r){
                       if(asg.Subscription__c!=null && asg.Subscription__r.SBQQ__Contract__r.enddate!=null && asg.Subscription__c!=null){
                           jum.Contract_End_Date__c =asg.Subscription__r.SBQQ__Contract__r.enddate;
                           
                       }
                   }
               }
             
        }
         if(jum.Final_Serial_For_Serial1__c!=null && serMap.containskey(jum.Final_Serial_For_Serial1__c)){
           jum.Final_Serial__c=serMap.get(jum.Final_Serial_For_Serial1__c).id;
                if(!serMap.get(jum.Final_Serial_For_Serial1__c).Assigned_Serials__r.IsEmpty()){
                   jum.Subscription_Id__c='Present';
               }
        }
       
    }

    }//End of method afterInserAction

}