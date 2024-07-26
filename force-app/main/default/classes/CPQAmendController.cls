public with sharing class CPQAmendController {
    public class CPQAmendControllerException extends Exception {}


@AuraEnabled
public static CPQAmendController.CPQAmendResult checkAmendEligible(Id recordId) {

    Map<Id,List<Opportunity>> mapUpAmendOps=new Map<Id,List<Opportunity>>();
    CPQAmendController.CPQAmendResult updateResult = new CPQAmendController.CPQAmendResult(); 
    updateResult.result  = true;  
    updateResult.message='';

    // if (String.isEmpty(recordId)) {
    //     System.debug(recordId);
    //     updateResult.result  = false;
    //     updateResult.message='Invalid input Record Id.';
    //    throw new CPQAmendControllerException('Invalid input Record Id.');
    // }

    Contract myContract=[Select Id,Most_Recent_Upsell_Hot_List__c,SBQQ__RenewalQuoted__c,
    SBQQ__RenewalForecast__c,SBQQ__RenewalOpportunity__c,SBQQ__RenewalOpportunity__r.StageName,
    SBQQ__RenewalOpportunity__r.Business_Group__c,RMA_Detected__c,
    (Select Id,StageName,Hot_List__c,SBQQ__RenewedContract__c from SBQQ__RenewalOpportunities__r),
    (Select Id,StageName,Hot_List__c,SBQQ__AmendedContract__c from SBQQ__AmendmentOpportunities__r)
    from Contract where ID =:recordId];

    System.debug(myContract);
    System.debug('Current User Id - '+UserInfo.getUserId());

    Boolean hasCustomPermission = FeatureManagement.checkPermission('By_Pass_Renewal_and_Amendment_Opp_Validation');

    System.debug('hasCustomPermission - '+hasCustomPermission);
   // mapUpAmendOps.put(myContract.Id,myContract.SBQQ__AmendmentOpportunities__r);
    
    if(!hasCustomPermission) {
    if( myContract.SBQQ__RenewalOpportunity__r!=null && myContract.SBQQ__RenewalOpportunity__r.Business_Group__c=='Core'
    && myContract.SBQQ__RenewalOpportunity__r.StageName=='Closed Won'  && myContract.RMA_Detected__c ==false)
    {
        
        updateResult.result  = false;  
        updateResult.message=System.Label.CPQAmend_Renew_Validation;
       
    }
    
}
    // for(Opportunity op: mapUpAmendOps.get(recordId))
    // {
    //     if(op.StageName=='Accepted')
    //  {
    //      updateResult.result  = false; 
      

    //  }
    // }

    //updateResult.result = true;
    return updateResult;
}

public class CPQAmendResult {

    @AuraEnabled
    public String message;
  
    @AuraEnabled
    public Boolean result;    
  }   

}