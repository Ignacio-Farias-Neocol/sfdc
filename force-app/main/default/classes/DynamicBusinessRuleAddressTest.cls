@isTest
public class DynamicBusinessRuleAddressTest {
    
    @testSetup static void testSetup(){
        Account acc = new Account();
        acc.Name = 'TESH ACC';
        acc.Type = 'Partner - MSP';
        insert acc;
        
        Account acc2 = new Account();
        acc2.Name = 'TESH ACaFDC';
        acc.Type ='Customer';
        insert acc2;
        
        List<Address__c> addressList = [Select id,Name,Account__r.Name,Primary__c,Type__c from Address__c];
        System.debug('::::::::testSetup::address::::::::::::'+JSON.serialize(addressList));
         Opportunity testOpp = TestDataFactory.createOpportunity(acc);
         testOpp.Business_Group__c='MSP';
         testOpp.Distributor__c = null;
        testOpp.Distributor_Contact__c = null;
        testOpp.Reseller__c =  null;
        testOpp.Reseller_Contact__c = null;
        insert testOpp;
        
        //Opportunity testOpp = TestDataFactory.createOpportunity(acc2);
        List<Contract> testContracts = new List<Contract> {
                new Contract(AccountId = acc.Id, StartDate = System.Today(), ContractTerm = 12,EndDate=Date.today().addDays(366), status ='Draft',Business_Group__c='MSP')
            };
            insert testContracts;
        TriggerHandler.clearAllBypasses();
    }
    
    
    @isTest static void unitBothCaseTest(){
        
        List<Address__c> addressList = new List<Address__c>([Select id,Country__c,Account__c,Primary__c,Type__c,Zip_Postal_Code__c from Address__c where Business_Group__c = 'MSP']);
        
        System.debug('::::::BEFORE::INTEST::addressList::::::::::::'+JSON.serialize(addressList));
        
        List<Address__c> addressListForUpdate = new List<Address__c>();
        
        if(!addressList.isEmpty()){
            for(Address__c qAddress: addressList){
                Address__c address = new Address__c();
                address.id = qAddress.Id;
                address.Primary__c = true;
                address.Zip_Postal_Code__c = '94088';
                addressListForUpdate.add(address);
            }
            Test.startTest();
                update addressListForUpdate;
            Test.stopTest();    
        }
    }
}