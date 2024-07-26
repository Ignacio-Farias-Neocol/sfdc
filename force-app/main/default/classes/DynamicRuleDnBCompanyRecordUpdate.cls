/**
* @author IY
* @date 
*
* @group DynmaicBusinessRuleAction
* @group-content a relative path to a static html file that provides content about the group
*
* @description implementation of DynamicBusinessRuleAction interface to auto populate Account Employee count
*/
public with sharing class DynamicRuleDnBCompanyRecordUpdate implements DynamicBusinessRuleAction {


    /*******************************************************************************************************
    * @description auto populate Account Employee count
    * @param trigger.new map
    * @return none, the result should be set to the records itself
    * @example
    */
    public void processRecords(Map<Id,SObject> newRecordMap, Map<Id,SObject> oldRecordMap, List <SObject> records, String jsonParameter, String triggerOrder, String triggerContext) {
        //List<DNBoptimizer__DnBCompanyRecord__c> listcompanyrecords = new List<DNBoptimizer__DnBCompanyRecord__c>();
        //listcompanyrecords = (List<DNBoptimizer__DnBCompanyRecord__c>) newRecordMap.values();
        Set<Id> listcompanyrecIds = (Set<Id>) newRecordMap.keyset();
        Set<Id> DnBCompanyrecords = new Set<Id>();
        List<Account> listaccountupd = new List<Account>();
        
        for(Account oAcc:[Select Id,Employee_Count_DnB__c,DNBoptimizer__DnBCompanyRecord__c from Account where DNBoptimizer__DnBCompanyRecord__c IN : listcompanyrecIds]){
            DNBoptimizer__DnBCompanyRecord__c orec = (DNBoptimizer__DnBCompanyRecord__c) newRecordMap.get(oAcc.DNBoptimizer__DnBCompanyRecord__c);
            if(oAcc.Employee_Count_DnB__c != orec.DNBoptimizer__EmployeeCountTotal__c){
                oAcc.Employee_Count_DnB__c = orec.DNBoptimizer__EmployeeCountTotal__c;
                listaccountupd.add(oAcc);
                
            }
        }
        
        if(!listaccountupd.IsEmpty()){
          Database.update(listaccountupd,false);
        }
              
    }
}