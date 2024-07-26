/**
 *  @author Jade Global
 *  @date 2021-12-15
 *  @description  Test class to cover admin dashboard class.
 */
@isTest
private class TestAdminDashBoardCallout {
    @testSetup static void setupTestData(){
        Account partner = AdminDashboardDataFactory.getAccount();  
        Contact conRec = AdminDashboardDataFactory.getContact();
        conRec.AccountId = partner.Id;
        Insert conRec;
        Opportunity oppt = AdminDashboardDataFactory.getOppty(partner.Id, conRec.Id);
        Insert oppt; 
        //Opportunity oppObj = [Select Id, Street__c, City__c, State__c, Country__c, Country_ISO_Code__c, Zip_Postal_Code__c, Billing_Address__c, Ship_To_Street__c, 
        // Ship_To_City__c, Ship_To_State__c, Ship_To_Country__c, Shipping_Country_ISO_Code__c, Ship_To_Zip_Postal_Code__c, Shipping_Address__c from Opportunity where Id =: oppt.Id];
        
        Opportunity opp = new Opportunity();
        opp.Id = oppt.Id;
        for(Address__c addr : [Select Id, Street__c, City__c, State_Name__c, Country_Name__c, Country_ISO__c,Zip_Postal_Code__c, Type__c, Account__c from Address__c where Account__c =: partner.Id]){
            if(addr.Type__c == 'Billing'){
                opp.Street__c = addr.Street__c;
                opp.City__c = addr.City__c;
                opp.State__c = 'Ontario';
                opp.Country__c = 'Canada';
                opp.Country_ISO_Code__c = 'CA';
                opp.Zip_Postal_Code__c = addr.Zip_Postal_Code__c;
                opp.Billing_Address__c = addr.Id;  
            }else if(addr.Type__c == 'Shipping'){
                opp.Ship_To_Street__c = addr.Street__c;
                opp.Ship_To_City__c = addr.City__c;
                opp.Ship_To_State__c = 'Ontario';
                opp.Ship_To_Country__c = 'Canada';
                opp.Shipping_Country_ISO_Code__c = 'CA';
                opp.Ship_To_Zip_Postal_Code__c = addr.Zip_Postal_Code__c;
                opp.Shipping_Address__c = addr.Id;  
            }
            system.debug('address1234@ '+addr);
        }
        update opp;
        
        SBQQ__Quote__c quote = AdminDashboardDataFactory.getQuote(opp);
        List<Product2> products = AdminDashboardDataFactory.addProducts(); 
        SBQQ__QuoteLine__c line = new SBQQ__QuoteLine__c();
        line.SBQQ__Product__c = products[0].Id;
        line.SBQQ__Quote__c = quote.Id;
        line.SBQQ__Quantity__c = 1;
        line.SBQQ__NetPrice__c = 0;
        line.Reseller_Memo_Sonian_Only__c = 'Skout'+products[0].ProductCode;
        
        test.startTest();
        Insert line;  
        OpportunityLineItem oppProduct = AdminDashboardDataFactory.getOpportunityProd(products[0].Id);
        oppProduct.SBQQ__QuoteLine__c = line.Id;
        oppProduct.OpportunityId = opp.Id;
        system.assert(oppProduct.PricebookEntryId!=null);
        Insert oppProduct; 
        test.stopTest();
    }
    
    @isTest static void testProvisioning() {
        User user = AdminDashboardDataFactory.createUser();  
        List<PermissionSet> permissionSetList = [SELECT ID,Name FROM PermissionSet WHERE Name LIKE 'Bypass_Process_Builders'];
        List<PermissionSet> permissionSetList2 = [SELECT ID,Name FROM PermissionSet WHERE Name LIKE 'BYPASS_ALL_VALIDATIONS_ON_OPPTY'];
        
        PermissionSetAssignment psa = new PermissionSetAssignment();
        psa.AssigneeId = user.Id;
        psa.PermissionSetId = permissionSetList[0].Id;
        insert psa;
        
        PermissionSetAssignment psa2 = new PermissionSetAssignment();
        psa2.AssigneeId = user.Id;
        psa2.PermissionSetId = permissionSetList2[0].Id;
        insert psa2;
        system.runAs(user){
            Opportunity oppObj = [Select Id, StageName,Model_Series__c from Opportunity];
            oppObj.StageName = 'Closed Won';
            oppObj.Model_Series__c = 'API';
            SBQQ.TriggerControl.disable();
            Update oppObj;
            test.startTest();
            AdminDashBoardCallout.CallAdminDashBoardAPI(new List<Id>{oppObj.Id});
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
            test.stopTest();
        }
    }
    
    @isTest static void testDeProvisioning() {
        User user = AdminDashboardDataFactory.createUser();  
        List<PermissionSet> permissionSetList = [SELECT ID,Name FROM PermissionSet WHERE Name LIKE 'Bypass_Process_Builders'];
        List<PermissionSet> permissionSetList2 = [SELECT ID,Name FROM PermissionSet WHERE Name LIKE 'BYPASS_ALL_VALIDATIONS_ON_OPPTY'];
        
        PermissionSetAssignment psa = new PermissionSetAssignment();
        psa.AssigneeId = user.Id;
        psa.PermissionSetId = permissionSetList[0].Id;
        insert psa;
        
        PermissionSetAssignment psa2 = new PermissionSetAssignment();
        psa2.AssigneeId = user.Id;
        psa2.PermissionSetId = permissionSetList2[0].Id;
        insert psa2;
        system.runAs(user){
            Opportunity oppObj = [Select Id, StageName,Model_Series__c from Opportunity];
            OpportunityLineItem lineitem = [Select Id, Quantity from OpportunityLineItem where OpportunityId =: oppObj.Id];
            lineitem.Quantity = -1;
            update lineitem;
            oppObj.StageName = 'Closed Won';
            oppObj.Model_Series__c = 'API';
            SBQQ.TriggerControl.disable();
            Update oppObj;
            test.startTest();
            AdminDashBoardCallout.CallAdminDashBoardAPI(new List<Id>{oppObj.Id});
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
            test.stopTest();
        }
    }
}