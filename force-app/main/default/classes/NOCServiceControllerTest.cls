@isTest
public class NOCServiceControllerTest {
	static testMethod void test() {
        Account record = new Account();
        record.Is_Unit_Test__c = true;
        record.Name = 'Test';
        insert record;
        
        NOC_Service_Information__c noc = new NOC_Service_Information__c();
        noc.Account__c = record.Id;
        insert noc;
        
        String pin = NOCServiceController.getRandomUniquePIN(noc.Id);
    }
}