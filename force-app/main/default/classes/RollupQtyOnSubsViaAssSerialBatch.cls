/**
 * Created by Bhavesh Jha  on 03/05/20.
 *
 *  @Date 2020/5/3
 *  @group Batchable active assigned seriel with subscription is null 
 */
public class RollupQtyOnSubsViaAssSerialBatch implements Schedulable,Database.Batchable<sObject>,Database.Stateful
{
    
    //(Assigned_Serial__c)Qty_in_Use__c to (SBQQ__Subscription__c)Quantity_in_Use__c
    public Database.QueryLocator start(Database.BatchableContext bc){
        //Query over Assigned_Serial__c where Status = 'Active' and Subscription__c Business Group = 'MSP'
        String query = 'SELECT id,Subscription__c,Qty_in_Use__c,Capacity__c,Serial__c from Assigned_Serial__c where Status__c = \'Active\' AND Subscription__c != null AND Subscription__r.Business_group__c = \'MSP\'';
        System.debug('::RollupQtyOnSubsViaAssSerialBatch :: execute :: query ::'+query);
        return Database.getQuerylocator(query);
    }
    
    public void execute(Database.BatchableContext bc, List<Assigned_Serial__c> scope){
        System.debug('::RollupQtyOnSubsViaAssSerialBatch :: execute :: scope ::'+JSON.serialize(scope));
        
        Set<String> subsSet = new Set<String>();
        Set<String> serialSet = new Set<String>();
        for(Assigned_Serial__c assignedSerial: scope){
            subsSet.add(assignedSerial.Subscription__c);
            serialSet.add(assignedSerial.Serial__c);
        }
        
        List<Assigned_Serial__c> newUniversalScope = new List<Assigned_Serial__c>([SELECT id,Subscription__c,Qty_in_Use__c,Capacity__c,Serial__c from Assigned_Serial__c where Subscription__c != null AND (Serial__c in: serialSet OR Subscription__c in: subsSet)]);
        
        System.debug('::RollupQtyOnSubsViaAssSerialBatch :: execute :: newUniversalScope ::'+JSON.serialize(newUniversalScope));
        
        //creating a map for rollup the Qty_in_Use__c 
        Map<String,List<Assigned_Serial__c>> subscriptionIdVsAssignedSerialsMap = new Map<String,List<Assigned_Serial__c>>();
        Map<String,List<Assigned_Serial__c>> serialIdVsAssignedSerialsMap = new Map<String,List<Assigned_Serial__c>>();
        for(Assigned_Serial__c assignedSerial: newUniversalScope){
            if(!subscriptionIdVsAssignedSerialsMap.containsKey(assignedSerial.Subscription__c)){
                subscriptionIdVsAssignedSerialsMap.put(assignedSerial.Subscription__c,new List<Assigned_Serial__c>());
            }
            subscriptionIdVsAssignedSerialsMap.get(assignedSerial.Subscription__c).add(assignedSerial);
            
            if(!serialIdVsAssignedSerialsMap.containsKey(assignedSerial.Serial__c)){
                serialIdVsAssignedSerialsMap.put(assignedSerial.Serial__c,new List<Assigned_Serial__c>());
            }
            serialIdVsAssignedSerialsMap.get(assignedSerial.Serial__c).add(assignedSerial);
        }
        
        System.debug('::RollupQtyOnSubsViaAssSerialBatch :: execute :: subscriptionIdVsAssignedSerialsMap ::'+JSON.serialize(subscriptionIdVsAssignedSerialsMap));
        System.debug('::RollupQtyOnSubsViaAssSerialBatch :: execute :: serialIdVsAssignedSerialsMap ::'+JSON.serialize(serialIdVsAssignedSerialsMap));
        
        List<SBQQ__Subscription__c> subsListForUpdate = new List<SBQQ__Subscription__c>();
        List<Serial__c> serialListForUpdate = new List<Serial__c>();
        
        //loop through the map and rollup all the Qty_in_Use__c and put it in to the Quantity_in_Use__c of coresponding SBQQ__Subscription__c.
        for(String subId: subscriptionIdVsAssignedSerialsMap.keyset()){
            Decimal qtyInUseCount = 0;
            for(Assigned_Serial__c assignedSerial: subscriptionIdVsAssignedSerialsMap.get(subId)){
                qtyInUseCount += assignedSerial.Qty_in_Use__c != null ? assignedSerial.Qty_in_Use__c : 0;
            }
            SBQQ__Subscription__c sub = new SBQQ__Subscription__c();
            sub.id = subId;
            sub.Quantity_in_Use__c = qtyInUseCount;
            subsListForUpdate.add(sub);
        }
        
        //loop through the map and rollup all the Capacity__c and put it in to the Capacity__c of coresponding Serial__c.
        for(String serialId: serialIdVsAssignedSerialsMap.keyset()){
            Decimal totalCapacity = 0;
            for(Assigned_Serial__c assignedSerial: serialIdVsAssignedSerialsMap.get(serialId)){
                totalCapacity += assignedSerial.Capacity__c != null ? assignedSerial.Capacity__c : 0;
            }
            Serial__c serial = new Serial__c();
            serial.id = serialId;
            serial.Capacity__c = totalCapacity;
            serialListForUpdate.add(serial);
        }
        
        System.debug('::RollupQtyOnSubsViaAssSerialBatch :: execute :: serialListForUpdate ::'+JSON.serialize(serialListForUpdate));
        if(!serialListForUpdate.isEmpty()){
            Database.SaveResult [] updateResult = Database.update(serialListForUpdate, false);
            for (Database.SaveResult sr : updateResult) {
                if (sr.isSuccess()) {
                    // Operation was successful, so get the ID of the record that was processed
                    System.debug('Successfully updated Serial__c. Serial__c ID: ' + sr.getId());
                }
                else {
                    // Operation failed, so get all errors                
                    for(Database.Error err : sr.getErrors()) {
                        System.debug('The following error has occurred.');
                        System.debug(err.getStatusCode() + ': ' + err.getMessage());
                        System.debug('Serial__c fields that affected this error: ' + err.getFields());
                    }
                }
            }
        }
        
        System.debug('::RollupQtyOnSubsViaAssSerialBatch :: execute :: subsListForUpdate ::'+JSON.serialize(subsListForUpdate));
        if(!subsListForUpdate.isEmpty()){
            Database.SaveResult [] updateResult = Database.update(subsListForUpdate, false);
            for (Database.SaveResult sr : updateResult) {
                if (sr.isSuccess()) {
                    // Operation was successful, so get the ID of the record that was processed
                    System.debug('Successfully updated SBQQ__Subscription__c. SBQQ__Subscription__c ID: ' + sr.getId());
                }
                else {
                    // Operation failed, so get all errors                
                    for(Database.Error err : sr.getErrors()) {
                        System.debug('The following error has occurred.');
                        System.debug(err.getStatusCode() + ': ' + err.getMessage());
                        System.debug('SBQQ__Subscription__c fields that affected this error: ' + err.getFields());
                    }
                }
            }
        }
    }
    
    public void finish(Database.BatchableContext bc){
        System.debug(':::::RollupQtyOnSubsViaAssSerialBatch:FINISH:::::');
    }
    
    //To direct schedule this batch from ANY other context.
    public void execute(SchedulableContext scon) {
        System.debug('::RollupQtyOnSubsViaAssSerialBatch :: SchedulableContext :: execute :: subsListForUpdate ::');
        Database.executeBatch(new RollupQtyOnSubsViaAssSerialBatch(), Test.isRunningTest() ? 10 : 200);
    }
}