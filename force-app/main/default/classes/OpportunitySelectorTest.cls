@isTest
public class OpportunitySelectorTest { 

    @testSetup
    static void setup() {

        Account testAccount = new Account();
        testAccount.Name = 'Test Company';
        testAccount.Website = 'www.test.com';       
        insert testAccount;

        Contact testContact = new Contact();
        testContact.LastName = 'Test LName';   
        testContact.email='testcontact@gmail.com.invalid';
        testContact.AccountId= testAccount.Id;
        insert testContact;

        Opportunity testOppty = new Opportunity();
        testOppty.Name='Test Oppty';
        testOppty.AccountId =  testAccount.Id;
        testOppty.Primary_Contact__c=testContact.Id;
        testOppty.StageName='Accepted';
        testOppty.CloseDate=Date.today();
        testOppty.recordtypeid=Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('New Business').getRecordTypeId();
        insert testOppty;
    }

    @isTest
    static void getOpportunitysByAccountTest() {     

     Account testacc=[Select Id from Account];

     Test.startTest();

     List<Opportunity> opptyList=new OpportunitySelector.OppSelectorWithoutSharing().getOpportunitysByAccount(testacc.Id);

     Test.stopTest();

     System.assertNotEquals(null, opptyList);  
     System.assertEquals('Test Company', opptyList[0].Account.Name);  
     System.assertEquals('Test Oppty', opptyList[0].Name); 

    }

}