@isTest
public with sharing class ReCalculateQuotePricesTest {

    @testSetup
    static void setup() {
       
        Account testAccount = new Account();  
        testAccount.Type = 'Customer';
        testAccount.Bill_To_Contact__c = 'Dummy Test';
        testAccount.Status__c = 'Active';
        testAccount.name = 'Test';
        testAccount.Terr_Theater__c='AMERICAS';
        insert testAccount;
        
        Contact con = new Contact();
        con.LastName = 'Test' ;
        con.FirstName = 'Testing';
        con.MailingCountry = 'United States';     
        con.Email = 'Test.Testing@test.com';
        con.Contact_Status__c = 'Active';  
        con.AccountId = testAccount.Id;     
        con.LeadSource = 'Renewal';
        insert con; 
      
        Opportunity testOpp = new Opportunity();
        testOpp.Name ='Test Oppty' ;
        testOpp.AccountID = testAccount.Id;               
        testOpp.Business_Group__c = 'Core' ;
        testOpp.StageName = 'Accepted';
        testOpp.CloseDate = System.today();
        testOpp.Primary_Contact__c = con.id;    
        testOpp.LeadSource = 'Renewal';      
        testOpp.Auto_Renewal_Status_Core__c='Included - Automatically';
        testOpp.Auto_Renewal_Status_Reason_Core__c='Included - Company Size';  
        insert testOpp;       

        SBQQ__Quote__c testQuote = new SBQQ__Quote__c(SBQQ__Opportunity2__c = testOpp.Id, SBQQ__Primary__c = true, SBQQ__Type__c = 'Renewal',ReCalToggle__c=false);
        insert testQuote;       
    }
    
     @isTest static void test_ReCalculateQuotePrices() {
        Test.startTest();
        ReCalculateQuotePricesSched s= new ReCalculateQuotePricesSched();
        String sch ='0 0 * * * ?'; 
        System.schedule('TestReCalculateQuotePricesSched', sch, s);
            
        ReCalculateQuotePrices b = new ReCalculateQuotePrices();
        Database.executeBatch(b, 1);

        Test.stopTest();

        System.assertEquals(true,[Select Id,ReCalToggle__c from SBQQ__Quote__c].ReCalToggle__c);       
    }
 }