/**
* @author IY
* @date 
*
* @group DynmaicBusinessRuleAction
* @group-content a relative path to a static html file that provides content about the group
*
* @description implementation of DynamicBusinessRuleAction interface to auto populate Account Employee count
*/
public with sharing class DynamicBusinessRuleAccountUpdate implements DynamicBusinessRuleAction {


    /*******************************************************************************************************
    * @description auto populate Account Employee count
    * @param trigger.new map
    * @return none, the result should be set to the records itself
    * @example
    */
    public void processRecords(Map<Id,SObject> newRecordMap, Map<Id,SObject> oldRecordMap, List <SObject> records, String jsonParameter, String triggerOrder, String triggerContext) {
        List<Account> listAccounts = new List<Account>();
        System.debug('Here***'+records);
        listAccounts = (List<Account>) newRecordMap.values();
        Set<Id> DnBCompanyrecords = new Set<Id>();
        
        //Map<String, Object> parameters =  (Map<String, Object>) JSON.deserializeUntyped(jsonParameter);
        try{
            for(Account oAcc:listAccounts){
              DnBCompanyrecords.add(oAcc.DNBoptimizer__DnBCompanyRecord__c);
            }
            
            //String strsoql = 'Select '+String.Valueof(parameters.get(fields)) +' from DNBoptimizer__DnBCompanyRecord__c where Id IN :DnBCompanyrecords';
            
            Map<Id,DNBoptimizer__DnBCompanyRecord__c> mapcompanyrecords = new Map<Id,DNBoptimizer__DnBCompanyRecord__c>([Select Id,DNBoptimizer__EmployeeCountTotal__c
            from DNBoptimizer__DnBCompanyRecord__c where Id IN :DnBCompanyrecords]);  
            
            for(Account oAcc:listAccounts){
              if(!mapcompanyrecords.IsEmpty() && mapcompanyrecords.get(oAcc.DNBoptimizer__DnBCompanyRecord__c)!=null){
                
                 oAcc.Employee_Count_DnB__c =  mapcompanyrecords.get(oAcc.DNBoptimizer__DnBCompanyRecord__c).DNBoptimizer__EmployeeCountTotal__c;
              }
              else{
                  oAcc.Employee_Count_DnB__c = 0;
                  
              }
            }
        }catch (Exception Ex){
             AppLog__c log = new AppLog__c(Is_Error__c=true,message__c = Ex.getMessage(),apexClassName__c = 'DynamicBusinessRuleAccountUpdate');
            
            Insert log;
        }
        
    }
}