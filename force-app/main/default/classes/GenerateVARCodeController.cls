public with sharing class GenerateVARCodeController {
    
    @AuraEnabled
    public static String generateVAR(ID recid) {
        list<MW_Account__c> lstAcc=new list<MW_Account__c>();
        lstAcc=[Select id, name, VAR_Code__c from MW_Account__c where id=:recid];
        if(lstAcc.size() > 0 && lstAcc[0].VAR_Code__c!=null && lstAcc[0].VAR_Code__c!='')
            return 'VARCode already exists for the account';
        if(lstAcc.size() > 0 && (lstAcc[0].VAR_Code__c==null || lstAcc[0].VAR_Code__c=='')){
            MW_Account__c acc=new MW_Account__c();
            acc=lstAcc[0];
            acc.VAR_Code__c = getVarCode();
            //acc.VAR_Code__c='SP-14114822';
            try{
                upsert acc;
                return 'VARCode has been successfully generated';
            }
            catch(exception e){
                return 'Please regenerate the code';                            
            }   
        }
        else{
            return null;
        }
    }

    public static String getVarCode() {
        Integer shortYear = Integer.valueOf( String.valueOf(Date.Today().Year()).right(2) );
        Integer month = Date.Today().Month();
        Integer randomCode = Math.round( Math.random() * 100000 );
        return 'SP-' + shortYear + month + randomCode;
    }

  /**
    * @description Helper method to determine whether there is already existing VAR code.
    * @param varCode VAR code to check.
    * @return Boolean 
    */ 
    public static Boolean isVarCodeUnique( String varCode ) {
        List<MW_Account__c> mwAccounts = [SELECT Id, VAR_Code__c FROM MW_Account__c WHERE VAR_Code__c = :varCode];
        return mwAccounts.isEmpty();
    }
}