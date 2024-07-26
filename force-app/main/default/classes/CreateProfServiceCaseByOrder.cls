/**
* @author        Keerthi Atluri       
* @date          2020-07-19
* @description   Creating Prof Service Case when a Prof Service Product is added to the OrderItem on an Order and the Order is placed
*
* @group         Handler
*/

public inherited sharing class CreateProfServiceCaseByOrder implements DynamicBusinessRuleAction
{
    public static boolean fired = false;
    public void processRecords(Map<Id,SObject> newRecordMap, Map<Id,SObject> oldRecordMap, List<SObject> records, String jsonParameter, String triggerOrder, String triggerContext) {        
        List<User> userList = [Select Id from User where Name = 'Integration Mulesoft'];
        if(!userList.isEmpty() && userList[0].Id == UserInfo.getUserId()){
            return;
        }
        //map<string, string> orderLineWithProductNameMap = new map<string, string>();
        System.debug('##CreateProfServiceCaseByOrder');
        if(!fired){
            if (records == null || records.size() == 0 ) {
                return;
            }
            LogModel log = LogModel.startLog('CreateProfServiceCaseByOrder', 'processRecords');
            try {
                fired = true;
                String objectName =  records[0].getSObjectType().getDescribe().getName();
                
                if (objectName == 'Order') {                                                                                                 
                    Set<Id> sOrders = new Set<Id>();
                    List<Professional_Service_Case_Creation__e> peList = new List<Professional_Service_Case_Creation__e>();
                    for(Sobject s:records) {
                        sOrders.add((Id)s.get('Id'));
                        Professional_Service_Case_Creation__e pe = new Professional_Service_Case_Creation__e();
                        pe.Order_Id__c = (Id) s.get('Id');
                        peList.add(pe);
                    }
                    
                    List<Database.SaveResult> results = EventBus.publish(peList);
                    
                    // Inspect publishing result for each event
                    for (Database.SaveResult sr : results) {
                        if (sr.isSuccess()) {
                            System.debug('Successfully published event.');
                        } else {
                            for(Database.Error err : sr.getErrors()) {
                                System.debug('Error returned: ' +
                                             err.getStatusCode() +
                                             ' - ' +
                                             err.getMessage());
                            }
                        }       
                    }
                    
                    System.debug('##method stop here');
                } 
            } Catch (Exception e) {
                log.addExceptionLog(e);
                system.debug('@@Error occured: '+e.getMessage());
            }			
        }		
    }
    
    @future
    public static void ProfessionalCaseSubjectUpdation(Set<Id> caseIds){
        if(!caseIds.isEmpty()){
            List<Case> caseList = [SELECT Id, Order_Product__r.Prof_Service_Product_Name__c, Serial__r.Primary_Product_Family_2__c, CaseNumber FROM Case WHERE Id IN :caseIds];
            for(Case c: caseList){
                c.Subject = 'Professional Service Case ' + c.caseNumber + ' ' + c.Order_Product__r.Prof_Service_Product_Name__c;
               // c.Product_Family_List__c = c.Serial__r.Primary_Product_Family_2__c;
            }
            system.debug('@@Case subject updated records: '+caseList);
            DML.save(caseList);
        }        
    }    
}