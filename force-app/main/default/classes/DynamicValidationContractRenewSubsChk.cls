/**
 * Created by: Anmol Bakshi
 * Date: 08/02/2021
 * 
 * Description: JIRA - 15400 - Dynamic Validation Rule to check if there are any 
 *              Subscriptions related to contract where 'Annotation Reason' is set to null. 
 *  */
public with sharing class DynamicValidationContractRenewSubsChk implements DynamicValidationRule{
   
    
    public DynamicValidationContractRenewSubsChk() {
    }

    public Set<String> getExpectedFields(){
        //Do Nothing
        return new Set<String>();
    }

    public Map<SObject,Boolean> evaluateRule(List<SObject> records){
        
        Map<Sobject,Boolean> contractsWithAnnotatedSubscriptions = new Map<Sobject,Boolean>();
        Map<ID,Contract> contractRecById = new Map<ID,Contract>();

        for(sobject sobj : records){

            Contract cont = (Contract)sobj;
            if(cont.Business_Group__c == 'Core' && (cont.SBQQ__RenewalForecast__c == true || cont.SBQQ__RenewalQuoted__c == true || cont.Auto_Renewal_Flag__c == true))
                contractRecById.put(cont.Id,cont);
        }

        for(Contract contr : [Select Id, Name, (Select Id, Name, AnnotationReason__c from SBQQ__Subscriptions__r)
                                               From Contract 
                                               Where Id IN: contractRecById.keySet()]){
            
            if(contr.SBQQ__Subscriptions__r != null && contr.SBQQ__Subscriptions__r.size() > 0){
                Boolean allSubsAnnotated = true;
                for(SBQQ__Subscription__c sub : contr.SBQQ__Subscriptions__r){
                    if(sub.AnnotationReason__c == null || sub.AnnotationReason__c == ''){
                        allSubsAnnotated = false;
                        break;
                    }
                }
                if(allSubsAnnotated){
                    Contract contractWithAnnotatedSub = contractRecById.get(contr.Id);
                    contractsWithAnnotatedSubscriptions.put(contractWithAnnotatedSub,false);    
                }
            }
        
        }

        return contractsWithAnnotatedSubscriptions;
    }
}