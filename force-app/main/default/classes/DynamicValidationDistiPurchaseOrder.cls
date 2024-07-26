public class DynamicValidationDistiPurchaseOrder implements DynamicBusinessRuleAction{

    public void processRecords(Map<Id,SObject> newRecordMap, Map<Id,SObject> oldRecordMap, List <SObject> records, String jsonParameter, String triggerOrder, String triggerContext) {
        findOpptyPONumberDupes(records, oldRecordMap,triggerContext);
    }
    
    public static void findOpptyPONumberDupes(List<sObject> newOpptyList,Map<Id,sObject> oldOpptyMap,String context){
        map<String,String> purcahseOrderMap = new map<String,String>();
        Id loggedInUserId = UserInfo.getProfileId();
        String loggedInUserProfileName = [Select Name from Profile where Id =: loggedInUserId].Name;
        Set<Id> acctIdSet = new Set<Id>();
        
        for(Opportunity eachOppty : (List<Opportunity>)newOpptyList){
            acctIdSet.add(eachOppty.AccountId);
        }
        
        for(Opportunity eachOppty : [Select Id,PurchaseOrderID__c,Name FROM Opportunity WHERE AccountId IN: acctIdSet AND StageName = 'Closed Won' AND PurchaseOrderID__c != NULL AND Id NOT IN : (List<Opportunity>)newOpptyList]){
            purcahseOrderMap.put(eachOppty.PurchaseOrderID__c,eachOppty.Id);
        }
       
        for (Opportunity o : (List<Opportunity>)newOpptyList) {
            Opportunity oppt = new Opportunity();
            if(oldOpptyMap.containsKey(o.id)){
              oppt = (Opportunity)oldOpptyMap.get(o.id);
            }
            if((context.contains('Insert') && o.StageName == 'Closed Won' && oppt.StageName != 'Closed Won') || (context.contains('Update'))){
                if (o.StageName == 'Closed Won' && loggedInUserProfileName == 'Apollo: Custom- Customer Services' && o.PurchaseOrderID__c != null && purcahseOrderMap.keyset().contains(o.PurchaseOrderID__c) && o.PO_OK__c == False ) {
                    String baseUrl = URL.getSalesforceBaseUrl().toExternalForm();
                    baseUrl += '/';
                    baseUrl += purcahseOrderMap.get(o.PurchaseOrderID__c);
                    o.addError('You have provided a Duplicate PO Number for the following Opportunity . Please double-check the accuracy for PO Number. "' +baseUrl+
                              '" Check \"PO Ok \" to continue to close won Opp or hit cancel and change the PO Number.');
                }
            }
        }
    }
}