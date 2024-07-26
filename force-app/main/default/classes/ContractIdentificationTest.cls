@isTest
public class ContractIdentificationTest {
    @isTest
    public static void test1(){
        Account partnerAccount = TestDataFactory.partners[0];
        Opportunity testOpp = TestDataFactory.opportunities[0];
        SBQQ__Quote__c testQuote = new SBQQ__Quote__c(SBQQ__Opportunity2__c = testOpp.Id, 
                                                  SBQQ__Primary__c      = true);
        insert testQuote;
        Product2 testParentProduct                  = new Product2();
        testParentProduct.Name                      = 'Parent Product';
        testParentProduct.is_pst_enterprise__c      = true;
        testParentProduct.Base_SKU__c               = 'TEST_SKU';
        testParentProduct.ProductCode               = 'TEST_SKU';
        // testParentProduct.Product_Sales_Grouping__c = 'Cloud Email Services';
        testParentProduct.Product_Sales_Grouping__c = 'ESS';
        insert new List<Product2>{testParentProduct};
            
        Contract testContract = new Contract(AccountId            = partnerAccount.Id, 
                                         Business_Group__c    = 'MSP', 
                                         SBQQ__Quote__c       = testQuote.Id, 
                                         StartDate            = System.today(),
                                         Reseller__c          = partnerAccount.Id,
                                         SBQQ__Evergreen__c = true,
                                         SBQQ__RenewalTerm__c = 12);
        insert new List<Contract>{testContract};
        SBQQ__Subscription__c testSub1 = new SBQQ__Subscription__c(SBQQ__Quantity__c              = 1, 
                                                               SBQQ__Contract__c              = testContract.Id, 
                                                               SBQQ__SubscriptionStartDate__c = System.today(),
                                                               SBQQ__SubscriptionEndDate__c   = System.today().addDays(90),
                                                               SBQQ__Product__c               = testParentProduct.Id,
                                                               SBQQ__Account__c               = partnerAccount.Id);
        List<SBQQ__Subscription__c> parentsubs = new List<SBQQ__Subscription__c>{testSub1};
        insert parentsubs;
        Serial__c testSerial = new Serial__c(Serial_Number__c    = '1234567',
                                         Status__c           = 'Active',
                                         Capacity__c         = 1,
                                         Base_Product_SKU__c = 'TEST_SKU');
    insert testSerial;
        List<Id> serialIdList = new List<Id>();
        serialIdList.add(testSerial.id);
    //Assigned Serial
    Assigned_Serial__c testAssigned1 = new Assigned_Serial__c(Serial__c        = testSerial.Id, 
                                                              Subscription__c = parentsubs[0].Id);
        List<Assigned_Serial__c> assignedSerials = new List<Assigned_Serial__c>{testAssigned1}; 
        Test.startTest();
            insert assignedSerials;
             
       ContractIdentification.fetchContracts(serialIdList);
        Test.stopTest();
    }
}