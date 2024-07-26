public with sharing class DynamicValidationUpSellOpptyCheck  implements DynamicValidationRule {


  public Set<String> getExpectedFields() {
        return new Set<String> {
        }; // not used in bulk validation in trigger context
    }


public Map<SObject,Boolean> evaluateRule(List<SObject> records) {

 Map<SObject, Boolean> results = new Map<SObject, Boolean>();
 Map<Id,List<Opportunity>> mapUpRenOps=new Map<Id,List<Opportunity>>();
 Map<Id,List<Opportunity>> mapUpAmendOps=new Map<Id,List<Opportunity>>();
 Set<Id> checkops=new Set<Id>();

 Set<Id> contractIds=new Set<Id>();
 for (SObject o : records) {
            Opportunity opp = (Opportunity) o;
              
                System.debug('Renewed Con ::' + opp.SBQQ__RenewedContract__c);
                  System.debug('Amended Con ::' + opp.SBQQ__AmendedContract__c);
                    System.debug('Hot List ::' + opp.Hot_List__c);
              
             if ((opp.SBQQ__AmendedContract__c!=null || opp.SBQQ__RenewedContract__c!=null) &&  opp.Hot_List__c!=null)
               {
                              

                  if (opp.SBQQ__AmendedContract__c!=null)
                    {
                    contractIds.add(opp.SBQQ__AmendedContract__c);
                    }
                    else 
                    {
                        contractIds.add(opp.SBQQ__RenewedContract__c);
                    }
               }
             }

             System.debug('contract ::' + contractIds);
             
             
             if(contractIds.size()>0)
             {
             List<Contract> myContract=[Select Id,Most_Recent_Upsell_Hot_List__c,
             (Select Id,Hot_List__c,SBQQ__RenewedContract__c from SBQQ__RenewalOpportunities__r),
             (Select Id,Hot_List__c,SBQQ__AmendedContract__c from SBQQ__AmendmentOpportunities__r)
             from Contract where ID in :contractIds];

             System.debug('myContract ::' + myContract);
             for(Contract con: myContract)
             {
             mapUpRenOps.put(con.Id,con.SBQQ__RenewalOpportunities__r);
             mapUpAmendOps.put(con.Id,con.SBQQ__AmendmentOpportunities__r);
             }
             for(Contract con: myContract)
             {

             for(Opportunity op:mapUpRenOps.get(con.Id))
              {
                if(op.Hot_List__c==con.Most_Recent_Upsell_Hot_List__c)
                {
                  checkops.add(con.Id);
                
                 }

              }
              for(Opportunity op: mapUpAmendOps.get(con.Id))
              {
                if(op.Hot_List__c==con.Most_Recent_Upsell_Hot_List__c)
               {
                checkops.add(con.Id);
               
                }
              }

            }
             }
            System.debug('checkops ::' + checkops);
            for (SObject o : records) {
              Opportunity opp = (Opportunity) o;
              results.put(opp, true); // set to valid by default
               if (checkops.contains(opp.SBQQ__AmendedContract__c) || checkops.contains(opp.SBQQ__RenewedContract__c) )
                 {
                       results.put(opp, false);
                     
                 }
               }

         return results;
    }

}