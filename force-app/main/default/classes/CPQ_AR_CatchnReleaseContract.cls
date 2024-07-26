public class CPQ_AR_CatchnReleaseContract {
 @InvocableMethod(label='Trigger creation of opportunity' description='Exceptions are stored in Auto Renewal Error Return ' category= 'Contract')
 public static List<ID> renewingContracts(List<ID> contracts) {
 
     List<Contract> renewContracts = new List<Contract>();
     for (Contract c :  [SELECT ID,SBQQ__RenewalForecast__c,Auto_Renewal_Error_Return__c
                              FROM Contract
                              WHERE ID IN :contracts]){
         c.SBQQ__RenewalForecast__c = true;
         renewContracts.add(c);
     }


 	Database.SaveResult[] srList = Database.update(renewContracts,false);
    Map<ID,String> contractErrors = new Map<ID,String>();
    Set<ID> errorContractIDs = new Set<ID>();
     for (Database.SaveResult sr : srList){
         if (!sr.isSuccess()) {
             String errorNotification ='';
           for(Database.Error err : sr.getErrors()) {
            errorNotification = errorNotification + err.getStatusCode() + ': ' + err.getMessage();
        }
         contractErrors.put(sr.getId(),errorNotification);
         errorContractIDs.add(sr.getId());
         }
     } 
     
     List<Contract> insertContractError = new List<Contract>();
     for (Contract cErrors : [SELECT ID,SBQQ__RenewalForecast__c,Auto_Renewal_Error_Return__c
                              FROM Contract
                              WHERE ID IN :errorContractIDs]){
                              
                                  cErrors.SBQQ__RenewalForecast__c = true;
                                  cErrors.Auto_Renewal_Error_Return__c = contractErrors.get(cErrors.Id);
                                  insertContractError.add(cErrors);
                              }
      
     Database.update(insertContractError);
     return contracts;


     
 }

}