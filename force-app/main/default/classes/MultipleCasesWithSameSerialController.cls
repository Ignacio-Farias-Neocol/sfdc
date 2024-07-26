public with Sharing class MultipleCasesWithSameSerialController {
    @AuraEnabled(cacheable=false)
    public static List<Case> getFilteredCases(String serialNumber, String pickProduct) {
        
        List<Case> executingCases = new List<Case>();
        List<Case> serialCaseslst = new List<Case>();


        
        //System.debug('missingSerialNumber:: '+missingSerialNumber);
        System.debug('serial Number:: '+serialNumber);
        if((serialNumber != null && serialNumber!= '') && (pickProduct != null && pickProduct != '' )){
              serialCaseslst = [SELECT Id, CaseNumber,RecordType.Name,Status, Subject, Pick_Product_only_if_Essentials__c,
                                  Account_Name__c,Serial_Number__c,
                                  Contact_Name__c,
                                  CreatedDate, Open_Date_time_Formatted__c,
                                  Case_Owner_Person__c
                                  FROM Case
                                  WHERE
                                  (RecordType.DeveloperName = 'Technical_Support' 
                                  OR  RecordType.DeveloperName = 'Professional_Services')
                                  AND(Status != 'Resolved' AND Status != 'Closed' AND Status != '')
                                  AND((Serial_Number__c = :serialNumber ) AND (Pick_Product_only_if_Essentials__c = :pickProduct))
                                 ];
            
        }
        if (!serialCaseslst.isEmpty()) {            
            executingCases.addAll(serialCaseslst);
            return executingCases;
        }else return null;
    } 
   
}