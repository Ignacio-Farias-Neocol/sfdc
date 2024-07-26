@IsTest
public class UpdContractHasSaaSProductQueueableTest {
    @isTest
    static void  statusActiveInactiveRMAFalseSonalTest(){
        
        //AfterInsert
        Test.startTest();
        
        Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
            .get('Customer').getRecordTypeId();
        
        Account testAccount = TestDataFactory.customers[0];
        testAccount.Terr_Theater__c='AMERICAS';
        testAccount.Terr_Region__c='WEST - REGION';        
        testAccount.RecordTypeId =recordTypeId;
        update testAccount;
        
        Product2 testProd = TestDataFactory.products[0];
        testProd.ProductCode='BEO-AES1-MSP';
        update testProd;
        
        Contract testContract = new Contract(AccountId = testAccount.Id, Business_Group__c = 'Core',
                                             Reseller__c=null,Distributor__c=null,
                                             StartDate = System.Today(),All_Subs_RMA__c=false,Auto_Renewal_Status_Core__c=null);
        insert testContract;
        
        List<SBQQ__Subscription__c>  testSubs = new List<SBQQ__Subscription__c> {
            new SBQQ__Subscription__c(SBQQ__Product__c = testProd.Id,SBQQ__Quantity__c = 1, SBQQ__Contract__c = testContract.Id, SBQQ__SubscriptionStartDate__c = System.Today(), ExtendedMonthlyPrice__c = 100, SBQQ__Account__c = testAccount.Id, SBCF_Serial_Number__c = '123',SBQQ__TerminatedDate__c=System.TODAY().addDays(-1)),
                new SBQQ__Subscription__c(SBQQ__Product__c = testProd.Id,SBQQ__Quantity__c = 1, SBQQ__Contract__c = testContract.Id, SBQQ__SubscriptionStartDate__c = System.Today(), ExtendedMonthlyPrice__c = 100, SBQQ__Account__c = testAccount.Id, SBCF_Serial_Number__c = '123',SBQQ__TerminatedDate__c=System.TODAY().addDays(-1))
                }; 
                    
                    insert testSubs;  
        List<SBQQ__Subscription__c> SubResult = [SELECT Id,SBQQ__Contract__c,Active__c,SBQQ__TerminatedDate__c FROM SBQQ__Subscription__c WHERE (Active__c = TRUE OR SBQQ__TerminatedDate__c = NULL)];
        for(SBQQ__Subscription__c ag: SubResult){
            system.debug('SubResult'+ag);
        }    
        /*testSubs[0].SBQQ__Quantity__c=2;

        update testSubs;  
        List<AggregateResult> aggResult = [SELECT COUNT(Id),SBQQ__Contract__c FROM SBQQ__Subscription__c WHERE (Active__c = TRUE OR SBQQ__TerminatedDate__c = NULL) GROUP BY SBQQ__Contract__c];
        for(AggregateResult ag: aggResult){
        system.debug('aggResult'+ag);
        }*/
        //system.assertequals(1,2);
    }  
    @isTest
    static void unitTestAllSubsRMATrue() {

        // AfterInsert
        Test.startTest();
        Account testAccount = TestDataFactory.customers[0];
        
        Product2 testProd = TestDataFactory.products[0];
        testProd.ProductCode='BEO-AES1-MSP';
        update testProd;

        Contract testContract = new Contract(AccountId = testAccount.Id, Business_Group__c = 'Core', StartDate = System.Today(),All_Subs_RMA__c=false);
        insert testContract;
                       
        List<SBQQ__Subscription__c>  testSubs = new List<SBQQ__Subscription__c> {
            new SBQQ__Subscription__c(SBQQ__Product__c = testProd.Id,SBQQ__Quantity__c = 1, SBQQ__Contract__c = testContract.Id, SBQQ__SubscriptionStartDate__c = System.Today(), ExtendedMonthlyPrice__c = 100, SBQQ__Account__c = testAccount.Id, SBCF_Serial_Number__c = '123',SBQQ__TerminatedDate__c=System.TODAY().addDays(1)),
            new SBQQ__Subscription__c(SBQQ__Product__c = testProd.Id,SBQQ__Quantity__c = -1, SBQQ__Contract__c = testContract.Id, SBQQ__SubscriptionStartDate__c = System.Today(), ExtendedMonthlyPrice__c = 100, SBQQ__Account__c = testAccount.Id, SBCF_Serial_Number__c = '123',SBQQ__TerminatedDate__c=System.TODAY().addDays(1))
        }; 

        insert testSubs;      
        Test.stopTest();

    }
}