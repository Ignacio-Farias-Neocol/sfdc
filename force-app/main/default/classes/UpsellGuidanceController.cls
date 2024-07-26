/**
* @author Rahul M
* @date 02/14/2020
*  Draft Mode to be Refactored
* @group Lightning Component Helper
*
* @description Helper class for the UpSellGuidance Component. 
*
*  SFDC-15188 : Removed Check if Hot List already used
*/

public with sharing class UpsellGuidanceController {

public class UpsellGuidanceException extends Exception {}
 
@AuraEnabled
public static UpsellGuidanceController.UpsellGuidanceResult initiateUpsell(Id recordId)
{
    Map<Id,List<Opportunity>> mapUpRenOps=new Map<Id,List<Opportunity>>();
    Map<Id,List<Opportunity>> mapUpAmendOps=new Map<Id,List<Opportunity>>();
    UpsellGuidanceController.UpsellGuidanceResult updateResult = new UpsellGuidanceController.UpsellGuidanceResult(); 
   
    try {
   
        System.debug(recordId);

        if (String.isEmpty(recordId)) {
            updateResult.result  = false;
            throw new UpsellGuidanceException('Invalid input Record Id.');
        }

    // Check Pre
    Contract myContract=[Select Id,Most_Recent_Upsell_Hot_List__c,SBQQ__RenewalQuoted__c,
    SBQQ__RenewalForecast__c,SBQQ__RenewalOpportunity__c,
    (Select Id,Hot_List__c,SBQQ__RenewedContract__c from SBQQ__RenewalOpportunities__r),
    (Select Id,Hot_List__c,SBQQ__AmendedContract__c from SBQQ__AmendmentOpportunities__r)
    from Contract where ID =:recordId];

    System.debug(myContract);

    mapUpRenOps.put(myContract.Id,myContract.SBQQ__RenewalOpportunities__r);
    mapUpAmendOps.put(myContract.Id,myContract.SBQQ__AmendmentOpportunities__r);
   
    for(Opportunity op: mapUpRenOps.get(recordId))
    {
      if(op.Hot_List__c==myContract.Most_Recent_Upsell_Hot_List__c)
     {
     //   updateResult.result  = false;  
     //   throw new AuraHandledException('An Upsell Opportunity has already been created from this Hot List. Please Upsell a different Hot list to the Contract and try again.');
      }
    }

    for(Opportunity op: mapUpAmendOps.get(recordId))
    {
      if(op.Hot_List__c==myContract.Most_Recent_Upsell_Hot_List__c)
     {
     //  updateResult.result  = false;    
    //   throw new AuraHandledException('An Upsell Opportunity has already been created from this Hot List. Please Upsell a different Hot list to the Contract and try again.');
      }
    }
        
       if(myContract.SBQQ__RenewalQuoted__c==true)
       myContract.SBQQ__RenewalQuoted__c=false;

       if(myContract.SBQQ__RenewalForecast__c==true)
       myContract.SBQQ__RenewalForecast__c=false;

       if(myContract.SBQQ__RenewalOpportunity__c!=null)
       myContract.SBQQ__RenewalOpportunity__c=null;
   
       Database.SaveResult srcontractUpdate = Database.update(myContract, true);

      myContract.SBQQ__RenewalQuoted__c=true;
      srcontractUpdate = Database.update(myContract, true);
   
      updateResult.result = true;
    } 
    
     catch(System.DmlException de) {
      updateResult.result  = false;
      updateResult.message = 'DML Exception while updating Contract field: ' + de.getMessage();
      System.debug('***Exception in DML: ' + updateResult.result + ' ' + updateResult.message);
    }    


    return updateResult;

    }


public class UpsellGuidanceResult {

  @AuraEnabled
  public String message;

  @AuraEnabled
  public Boolean result;    
}   

}