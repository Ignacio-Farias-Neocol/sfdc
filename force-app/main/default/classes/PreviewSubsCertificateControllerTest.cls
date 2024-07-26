/**
* @author Aditya
* @date 09/01/2022
*
* @description Test class for PreviewSubscriptionCertificateController
*
*/
@isTest 
public class PreviewSubsCertificateControllerTest 
{
    
    @TestSetup
    private static void testDataSetup(){
        TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler');   
        
        //Create Parent Product
        Product2 testProduct1                  = new Product2();
        testProduct1.Name                      = 'Product1';
        testProduct1.is_pst_enterprise__c      = true;
        testProduct1.Base_SKU__c               = 'TEST_SKU';
        testProduct1.ProductCode               = 'TEST_SKU';
        //testProduct1.Product_Sales_Grouping__c = 'Cloud Email Services';   
        testProduct1.Product_Sales_Grouping__c = 'ESS'; 
        
        Product2 testProduct2                  = new Product2();
        testProduct2.Name                      = 'Product2';
        testProduct2.is_pst_enterprise__c      = true;
        testProduct2.Base_SKU__c               = 'TEST_SKU_2';
        testProduct2.ProductCode               = 'TEST_SKU_2';
        //testProduct2.Product_Sales_Grouping__c = 'Cloud Email Services'; 
        testProduct2.Product_Sales_Grouping__c = 'ESS';    
        
        insert new List<Product2>{testProduct1, testProduct2};
            //Create product bundle
            SBQQ__ProductOption__c testPO = new SBQQ__ProductOption__c( SBQQ__Number__c = 10,
                                                                       SBQQ__ConfiguredSKU__c = testProduct1.Id,
                                                                       SBQQ__OptionalSKU__c = testProduct2.Id,
                                                                       SBQQ__Type__c = 'Component',
                                                                       SBQQ__QuoteLineVisibility__c = 'Never');
        
        insert testPO;
        
        //Update Account Information
        Account acct = TestDataFactory.customers[0];
        
        //Opportunity
        Opportunity testOpp = TestDataFactory.opportunities[0];
        
        //Quote
        SBQQ__Quote__c testQuote = new SBQQ__Quote__c(SBQQ__Opportunity2__c = testOpp.Id, 
                                                      SBQQ__Primary__c      = true);
        insert testQuote;
        
        //Contract
        Contract testContract = new Contract(AccountId            = acct.Id, 
                                             Business_Group__c    = 'Core', 
                                             SBQQ__Quote__c       = testQuote.Id, 
                                             StartDate            = System.today(),
                                             Reseller__c          = acct.Id,
                                             SBQQ__RenewalTerm__c = 12,
                                             ContractTerm = 3);
        
        Contract testTargetContract = new Contract(AccountId            = acct.Id, 
                                                   Business_Group__c    = 'MSP', 
                                                   SBQQ__Quote__c       = testQuote.Id, 
                                                   StartDate            = System.today(),
                                                   Reseller__c          = acct.Id,
                                                   SBQQ__RenewalTerm__c = 12,
                                                   ContractTerm = 3);                                         
        insert new List<Contract>{testContract, testTargetContract};
            
            //Order
            Order testOrder              = new Order();
        testOrder.AccountId          = TestDataFactory.customers[0].Id;
        testOrder.EffectiveDate      = Date.today();
        testOrder.Pricebook2Id       = TestDataFactory.priceBookId;
        testOrder.description        = 'Test Order';
        testOrder.Status             = 'Draft';
        testOrder.Type               = 'New'; // new order
        testOrder.Active_Contract__c = testContract.Id;
        testOrder.OpportunityId      = testOpp.Id;
        
        insert testOrder;
        
        TriggerHandler.clearAllBypasses();  
    }
    
	static testMethod void testMethod1() 
	{
		Order o = [SELECT Id FROM Order LIMIT 1];
        Test.StartTest(); 
        PageReference testPage = Page.PreviewSubscriptionCertificate; 
        Test.setCurrentPage(testPage);
        testPage.getParameters().put('Id', String.valueOf(o.Id));
        PreviewSubscriptionCertificateController prvSubsCert = new PreviewSubscriptionCertificateController();
       	prvSubsCert.getOrderRec();
        Test.StopTest();
	}
}