@isTest
public class GenerateVARCodeControllerTest {
    static testMethod void testGenerateVARCode() {
        Account acc=new Account();
        acc.Name='test';
        acc.Is_Unit_Test__c = true;
        insert acc;
        
        MW_Account__c mwacc=new MW_Account__c();
        mwacc.Name='test123';
        mwacc.AccountId__c=acc.id;
        insert mwacc;
        String varCode = GenerateVARCodeController.generateVAR(mwacc.id);
        
        Boolean isVarCodeUnique = GenerateVARCodeController.isVarCodeUnique(varCode);
    }
}