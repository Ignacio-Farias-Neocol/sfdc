@IsTest
private class DynamicBusinessRuleContractTest {
    @testSetup static void setup() {
        TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler'); 
        List <Account> customers = TestDataFactory.customers;
        List <Opportunity> opportunities = TestDataFactory.opportunities;
        List<Order> orders = TestDataFactory.orders;
        List<Account> distributor = TestDataFactory.partnersDistributor;
        TriggerHandler.clearAllBypasses(); 
    }

    @IsTest
    static  void unitTest() {
        List<Opportunity> testOpps = [Select ID From Opportunity];
        List<Account> testAccounts = [Select ID From Account];
        List<Order> testOrders = [Select ID From Order];

        Test.startTest();
            List<Contract> testContracts = new List<Contract> {
                new Contract(AccountId = testAccounts[0].Id, SBQQ__RenewalOpportunity__c = testOpps[0].Id, StartDate = System.Today(), ContractTerm = 12, Distributor__c = testAccounts[0].Id, Reseller__c = testAccounts[0].Id, SBQQ__Order__c = testOrders[0].Id),
                new Contract(AccountId = testAccounts[0].Id, SBQQ__RenewalOpportunity__c = testOpps[0].Id, StartDate = System.Today(), ContractTerm = 12, Distributor__c = testAccounts[0].Id)
            };
            insert testContracts;

            testOpps[0].SBQQ__RenewedContract__c = testContracts[0].Id;
            update testOpps[0];
            
            try {
                testContracts[0].SBQQ__RenewalOpportunity__c = null;
                update testContracts;

                testContracts[0].SBQQ__RenewalOpportunity__c = testOpps[0].Id;
                update testContracts;
            } catch (Exception e) {}
        Test.stopTest();
    }

    @IsTest
    static  void unitTestAutoRenewPrimaryContact() {
        List<Account> testAccounts = [Select ID From Account];

        Test.startTest();
            List<Contract> testContracts = new List<Contract> {
                new Contract(AccountId = testAccounts[0].Id, StartDate = System.Today(), ContractTerm = 12, Business_Group__c = 'Core')
            };
            insert testContracts;

            try {
                testContracts[0].Primary_Contact__c = null;
                testContracts[0].SBQQ__RenewalForecast__c = true;
                update testContracts;
            } catch (Exception e) {}
        Test.stopTest();
    }

    @isTest
    static void checkRenewalEligibleTest(){
     
        Database.SaveResult[] res=null;
        List<Account> testAccounts = [Select ID From Account];

        Test.startTest();
            List<Contract> testContracts = new List<Contract> {
                new Contract(AccountId = testAccounts[0].Id, StartDate = System.Today(), ContractTerm = 12,
                 Business_Group__c = 'Core',SBQQ__RenewalForecast__c=false)
            };
            insert testContracts;

        User u = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id,
            LastName = 'Test',
            Email = 'CPQ.Test@gmail.com.invalid',
            UserName = 'CPQ.Test.' + DateTime.now().getTime() + '@CPQ.Test.com',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US'
          );
       
          insert u;

          System.runAs(u){

            Opportunity testOp = [Select id from Opportunity  LIMIT 1];

            testOp.StageName='Accepted';
            testOp.Business_Group__c='Core';
            update testOp;
           
            testContracts[0].Primary_Contact__c = null;
            testContracts[0].SBQQ__RenewalForecast__c = true;
              
            res=Database.update(testContracts, false);
             
            for (Database.SaveResult sr : res ) {
            System.assert(sr.isSuccess() == false);
            System.assert(sr.getErrors().size() == 1);            
            }
       
            Test.stopTest();
          }
    }  

    @isTest
    static void addDistributorTest(){

        Database.SaveResult[] res=null;
        
        List<Account> testAccounts = [Select ID,Terr_Theater__c,Type,Auto_Renewal_Status_Core__c, Auto_Renewal_Status_Reason_Core__c
         From Account];

        Test.startTest();
        testAccounts[0].Terr_Theater__c='AMERICAS';
        testAccounts[0].Type='Core';
        testAccounts[0].Auto_Renewal_Status_Core__c='Included - Automatically';
        testAccounts[0].Auto_Renewal_Status_Reason_Core__c='Included - based on Account Flag';
        update testAccounts[0];        
       
         Account distributor = [SELECT ID FROM Account WHERE NAME LIKE '%PartnerDistributor%' LIMIT 1];
           
         List<Contract> testContracts = new List<Contract> {
              new Contract(AccountId = testAccounts[0].Id, StartDate = System.Today(), ContractTerm = 12,
              Business_Group__c = 'Core',SBQQ__RenewalForecast__c=false,Distributor__c=distributor.Id)
         };

        insert testContracts;  

        Test.stopTest();  

        /*System.assertEquals('Excluded - Automatically',[Select Id,Auto_Renewal_Status_Core__c from Contract
                                                        where Id=:testContracts[0].Id].Auto_Renewal_Status_Core__c
                            );*/

        /*System.assertEquals('Excluded - Distribution Deal',[Select Id,Auto_Renewal_Status_Reason_Core__c from Contract
                                                            where Id=:testContracts[0].Id].Auto_Renewal_Status_Reason_Core__c
                            );   */
    }

    @isTest
    static void removeDistributorTest(){

        Database.SaveResult[] res=null;

        Test.startTest();
       
        List<Account> testAccounts = [Select ID,Terr_Theater__c,Type,Auto_Renewal_Status_Core__c, Auto_Renewal_Status_Reason_Core__c From Account];

        System.debug('Terr_Theater__c ::'+testAccounts[0].Terr_Theater__c );
        System.debug('Type ::'+testAccounts[0].Type );

        testAccounts[0].Terr_Theater__c='AMERICAS';
        testAccounts[0].Type='Core';
        testAccounts[0].Auto_Renewal_Status_Core__c='Included - Automatically';
        testAccounts[0].Auto_Renewal_Status_Reason_Core__c='Included - based on Account Flag';
        update testAccounts[0];

        Account distributor = [SELECT ID FROM Account WHERE NAME LIKE '%PartnerDistributor%' LIMIT 1];
        
        List<Contract> testContracts = new List<Contract> {
                new Contract(AccountId = testAccounts[0].Id, StartDate = System.Today(), ContractTerm = 12,
                 Business_Group__c = 'Core',SBQQ__RenewalForecast__c=false,Distributor__c=distributor.Id)
            };
        insert testContracts;       

        Contract con=[Select Id,Distributor__c,Auto_Renewal_Status_Core__c,Auto_Renewal_Status_Reason_Core__c from Contract where Id=:testContracts[0].Id];
        con.Distributor__c=null;
        update con;

        Test.stopTest();       
    }

    @isTest
    static void portalAutoRenewalTest(){

        Database.SaveResult[] res=null;

        Test.startTest();
       
        List<Account> testAccounts = [Select ID,Terr_Theater__c,Type,Auto_Renewal_Status_Core__c, Auto_Renewal_Status_Reason_Core__c From Account];

        System.debug('Terr_Theater__c ::'+testAccounts[0].Terr_Theater__c );
        System.debug('Type ::'+testAccounts[0].Type );

        testAccounts[0].Terr_Theater__c='AMERICAS';
        testAccounts[0].Type='Core';
        update testAccounts[0];
        
        List<Contract> testContracts = new List<Contract> {
                new Contract(AccountId = testAccounts[0].Id, StartDate = System.Today(), ContractTerm = 12,
                 Business_Group__c = 'Core',SBQQ__RenewalForecast__c=false)
            };
        insert testContracts;       

        Order newOrder = new Order(AccountId = testAccounts[0].Id, Portal_Placed_Order__c = true, Auto_Renewal_Flag__c = true, EffectiveDate = Date.today(), Status = 'Draft');

        insert newOrder;

        testContracts[0].SBQQ__Order__c = newOrder.Id;

        update testContracts;

        Test.stopTest();
       
        System.assertEquals('Included - Automatically',[Select Id,Auto_Renewal_Status_Core__c from Contract
                                                        where Id=:testContracts[0].Id].Auto_Renewal_Status_Core__c
                            );
    }

  
}