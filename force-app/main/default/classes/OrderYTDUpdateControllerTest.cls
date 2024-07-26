@isTest
public class OrderYTDUpdateControllerTest {
  @isTest
    public static void test1(){
        String loggedInUserProfileName = [Select Id from Profile where Name ='Apollo: Custom- Customer Services'].Id;
        List<user> userForTesting = [SELECT Id,Email FROM User WHERE ProfileId =: loggedInUserProfileName AND IsActive = True LIMIT 1];
        List<PermissionSet> permissionSetList = [SELECT ID,Name FROM PermissionSet WHERE Name LIKE 'BYPASS_ALL_VALIDATIONS_ON_OPPTY'];
        List<PermissionSet> permissionSetList2 = [SELECT ID,Name FROM PermissionSet WHERE Name LIKE 'Bypass_Process_Builders'];
        PermissionSetAssignment psa = new PermissionSetAssignment();
        psa.AssigneeId = userForTesting[0].Id;
        system.debug('Email'+userForTesting[0].Email);
        psa.PermissionSetId = permissionSetList[0].Id;
        insert psa;
        PermissionSetAssignment psa2 = new PermissionSetAssignment();
        psa2.AssigneeId = userForTesting[0].Id;
        psa2.PermissionSetId = permissionSetList2[0].Id;
        insert psa2;
        system.runAs(userForTesting[0]){
            //TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler');
            
            Account newAccount = new Account();
            newAccount.Is_Unit_Test__c = true;
            newAccount.name = 'Test';
            newAccount.Bill_To_Contact__c = 'orderytduptest';
            newAccount.recordTypeId =   Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByDeveloperName().get('Customer').getRecordTypeId();
            insert newAccount;
            
            Account newAccount2 = new Account();
            newAccount2.Is_Unit_Test__c = true;
            newAccount2.name = 'Test2';
            newAccount2.Type = 'Partner - Reseller';
            newAccount2.Partner_Number__c = 3011;
            newAccount2.Bill_To_Contact__c = 'orderytduptest2';
            newAccount2.recordTypeId =   Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByDeveloperName().get('Customer').getRecordTypeId();
            insert newAccount2;
            
            Account newAccount3 = new Account();
            newAccount3.Is_Unit_Test__c = true;
            newAccount3.name = 'Test3';
            newAccount3.Type = 'Distributor - Core';
             newAccount3.Partner_Number__c = 2011;
            newAccount3.Bill_To_Contact__c = 'orderytduptest3';
            newAccount3.recordTypeId =   Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByDeveloperName().get('Customer').getRecordTypeId();
            insert newAccount3;
            
            Contact rec = new Contact();
            rec.LastName = 'Doe' ;
            rec.FirstName = 'John';
            rec.MailingCountry = 'United States';
            //rec.FirstName__c = 'John';
            //rec.LastName__c = 'Doe' + ' ' + suffixNumber;
            rec.Email = 'John.Doe@test.com';
            
            rec.Contact_Status__c = 'Active';  // Note: DPL check will change this status to 'Pending'
            rec.AccountId = newAccount.Id;
            rec.recordTypeId = Schema.getGlobalDescribe().get('Contact').getDescribe().getRecordTypeInfosByDeveloperName().get('Contact').getRecordTypeId();
            rec.LeadSource = 'Renewal';
            insert rec; 
            
            newAccount.Bill_To_Contact__c = rec.id;
            update newAccount;
            
             Opportunity oppt = new Opportunity();
            oppt.Name ='Oppty 1' ;
            oppt.AccountID = newAccount.Id;
            oppt.Bill_To_Account__c = newAccount.id;
            //oppt.SBQQ__PrimaryQuote__c = quoteList[0].id;
            /*oppt.Distributor__c = partnercontacts[0].accountId;
            oppt.Distributor_Contact__c = partnercontacts[0].id;
             oppt.Reseller__c =  partnercontacts[0].accountId;
            oppt.Reseller_Contact__c = partnercontacts[0].id;*/
            oppt.Primary_Product_Family_2__c = 'Email Security Gateway'; // e.g. other values: Load Balancer, Phishline, Cloud Control
            oppt.Model_Series__c = 'API';
            oppt.StageName = 'Closed Won';
            oppt.Amount = 3000;
            oppt.CloseDate = System.today();
            oppt.Primary_Contact__c = rec.id;
            // new business opportunities
             oppt.recordTypeId = Schema.getGlobalDescribe().get('Opportunity').getDescribe().getRecordTypeInfosByDeveloperName().get('New_Business').getRecordTypeId();
             oppt.Bypass_Validation__c = true;
            oppt.Reseller__c = newAccount2.Id;
            oppt.Distributor__c = newAccount3.Id;
            oppt.Is_Unit_Test__c = true;
            oppt.LeadSource = 'Renewal';
            oppt.PurchaseOrderID__c = 'SFDC11896';
            insert oppt; 
            
            Pricebook2 pricebook = new Pricebook2(Name = 'PriceBook Test'); 
            insert pricebook;
            
            String standardPBID = Test.getStandardPricebookId();
            
            Product2 newProduct = new Product2();
            newProduct.IsActive = true;
            newProduct.Name = 'Test Product';
            insert newProduct;
            
            PricebookEntry pbe = new PricebookEntry();
      pbe.Pricebook2Id = standardPBID; 
            pbe.Product2Id = newProduct.Id; 
            pbe.UnitPrice = 1; 
            pbe.IsActive = true; 
            Boolean useStandardPrice = false; 
        pbe.UseStandardPrice = false; // useStandardPrice; 
            insert pbe;
            
            
            
            Order newOrder = new Order();
            newOrder.AccountId = newAccount.id;
            newOrder.Name = 'test order';
            //newOrder.TotalAmount = 100;
            newOrder.Status = 'Draft';
            newOrder.Quote_Business_Group__c = 'Barracuda';
            newOrder.SBCF_Order_Type__c = 'Renewal';
            newOrder.EffectiveDate = System.today();
            newOrder.OpportunityId = oppt.id;
            newOrder.Has_RMA_Replace__c = false; 
            newOrder.Status = 'Draft';
            newOrder.Pricebook2Id = standardPBID;
            newOrder.Bill_To_Account__c = newAccount.id;
            newOrder.Bill_To_Contact__c = rec.id;
            insert newOrder;
            
            OrderItem newOrderProduct = new OrderItem();
            newOrderProduct.SBQQ__Status__c = 'Activated';
            newOrderProduct.UnitPrice= 100;
            newOrderProduct.Quantity = 10;
            newOrderProduct.Product2Id = newProduct.id;
            newOrderProduct.OrderId = newOrder.id;
            newOrderProduct.PricebookEntryId = pbe.id;
            insert newOrderProduct;
            
            newOrder.Bill_To_Contact_Email__c = 'test@barracuda.com' ;
            newOrder.BillToContactId = rec.id;
            newOrder.Status = 'Placed';
            update newOrder;
            
       newOrder.Status = 'Draft';
            update newOrder;           
        }
    }
}