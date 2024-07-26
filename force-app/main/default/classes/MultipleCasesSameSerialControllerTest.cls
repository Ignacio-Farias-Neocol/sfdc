@isTest
private class MultipleCasesSameSerialControllerTest {
    @isTest
    static void testforSerialCases() {
        Product2 product = TestDataFactory.products[0];
        product.SBCF_Is_Shipped__c = TRUE;
        update product;
        
        // Create a serial record with Serial_Number__c
        Serial__c serial = new Serial__c(
            Activation_Date__c = Date.today(),
            Serial_Number__c = String.valueOf(Math.random() * 10000000).left(6),
            Product__c= product.Id,
            Status__c = 'Active'
        );
        insert serial;
		Account acc = new Account(Name = 'Vinmai');
        insert acc;
        
        Contact con = new Contact(LastName = 'Vinmai T',Phone='8676567868');
        insert con;
        
        string rectype = Schema.SobjectType.Case.getRecordTypeInfosByDeveloperName().get('Technical_Support').getRecordTypeId();

        Case serialCase = new Case(
			AccountId = acc.id,
            ContactId = con.id,
            Status = 'New',
            Subject = 'test',
            Missing_Serial_Number__c = 'S-868788',
            Pick_Product_only_if_Essentials__c = 'XDR',
            Serial__c = serial.Id,
            Product_Family_List__c = 'XDR',
            Web_Region__c = 'Americas',
            recordtypeid = rectype
        	);
        
        insert serialCase;
		
        Test.startTest();
        List<Case> result1 = MultipleCasesWithSameSerialController.getFilteredCases(serial.Serial_Number__c,'XDR');     
		Test.stopTest();
    } 
    
}