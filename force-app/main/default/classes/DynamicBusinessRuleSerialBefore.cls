/**
* @author Yuli
* @date 04/01/2020
*
* SFDC-10890: populate Business Group on serial
* SFDC-12389: Adding logic to flag the serial when License Token or Tracking information is updated on Serials
* SFDC-13192: Tagging only active serials with no RMA Date for emails
*/
public class DynamicBusinessRuleSerialBefore implements DynamicBusinessRuleAction {
    public void processRecords(Map<Id,SObject> newRecordMap, Map<Id,SObject> oldRecordMap, List <SObject> records, String jsonParameter, String triggerOrder, String triggerContext) {
        SetBusinessGroup(records, oldRecordMap);

        //If License Token or Tracking information has been updated then flag the serial to send email to customer
        if (triggerOrder == 'PRE') {
            if(triggerContext.contains('Insert') || triggerContext.contains('Update')){
                flagSerialForEmail(newRecordMap, oldRecordMap, records, triggerContext);
            }
        }
    }

    //SFDC-10890
    private static void SetBusinessGroup(List <SObject> records, Map<Id,SObject> oldRecordMap) {
        List<Serial__c> candidates = new List<Serial__c>();
        Set<String> orderIds = new Set<String>();

        for (Serial__c s : (List<Serial__c>)records){
            Serial__c sOld = oldRecordMap == null ? new Serial__c() : (Serial__c)oldRecordMap.get(s.Id);
            if (sOld == null)
                sOld = new Serial__c();

            if (String.isEmpty(s.Business_Group__c) && s.Order__c != null && s.Order__c != sOld.Order__c) {
                candidates.add(s);
                orderIds.add(s.Order__c);
            }
        }

        if (!candidates.isEmpty()) {
            Map<String, Order> ordres = new Map<String, Order>([Select ID, SBQQ__Quote__r.Business_Group__c From Order Where ID in: orderIds]);
            for (Serial__c s : candidates) {
                Order o = ordres.get(s.Order__c);
                s.Business_Group__c = o.SBQQ__Quote__r.Business_Group__c;
            }
        }
    }

    //SFDC-12389: Method to flag a serial when License Token or Tracking information is updated on Serials
    private static void flagSerialForEmail(Map<Id,SObject> newRecordMap, Map<Id,SObject> oldRecordMap, List <SObject> records, String triggerContext){
        //Start the log
        LogModel log = LogModel.startLog('DynamicBusinessRuleSerialBefore', 'flagSerialForEmail');
        try{
            
            //Loop through records and determine which serials satisfy the condition
            for(SObject obj: records){
                Serial__c currentSerial = (Serial__c)obj;

                //Check if License Token or Tracking information is populated or not
                //SFDC_12825
                if(currentSerial.Business_Group__c == 'MSP' && 
                   currentSerial.Status__c == 'Active' && 
                   currentSerial.RMA_Date__c == null){
                    if(String.isNotBlank(currentSerial.License_Token_Information__c) || 
                       String.isNotBlank(currentSerial.Tracking_Number__c) || 
                       String.isNotBlank(currentSerial.Popkey__c)){
                        if(triggerContext.contains('Insert')){
                            //Set the flag on Serial
                            currentSerial.Send_Fulfillment_Email__c = true;
                        }
                        else if(triggerContext.contains('Update')){
                            //get the old record
                            Serial__c oldSerial = (Serial__c)oldRecordMap.get(currentSerial.Id);
                            if(oldSerial!=null){
                                if(currentSerial.License_Token_Information__c != oldSerial.License_Token_Information__c || 
                                    currentSerial.Tracking_Number__c != oldSerial.Tracking_Number__c || 
                                    currentSerial.Popkey__c != oldSerial.Popkey__c){
                                    //Set the flag on Serial
                                    currentSerial.Send_Fulfillment_Email__c = true;
                                }
                            }
                        }
                    }
                }

            } //END FOR
        }
        catch (Exception e) {
            System.debug('Exception setting Email flag on serial' + e.getMessage());
            log.addExceptionLog(e);
        }
    }    
}