/**
* @author        Ivan Yeung/salesforce services       
* @date          2018-10-15
* @description   Unit Test class for ContactTriggerHandler 
* @group         Test
*
*/
@isTest
public with sharing class ContactTriggerHandlerTest {
    @isTest static void testInsertUpdate() {


        Test.startTest();
        
        // create an contact
        Contact rec = TestDataFactory.customerContacts[0];

//        Contact rec = new Contact();
//        rec.LastName = 'Doe';
//        rec.FirstName = 'John';
//        DML.save(rec);

        // List <Contact> recs = new List <Contact> {rec}; 
        // Database.SaveResult[] srList = Database.insert(recs, false);
        // // Iterate through each returned result
        // for (Database.SaveResult sr : srList) {
        //     if (sr.isSuccess()) {
        //         // Operation was successful, so get the ID of the record that was processed
        //         System.debug('~~~ Successfully inserted Record. record ID: ' + sr.getId());
        //     }
        //     else {
        //         // Operation failed, so get all errors                
        //         for(Database.Error err : sr.getErrors()) {
        //             System.debug('~~~ The following error has occurred.');                    
        //             System.debug(err.getStatusCode() + ': ' + err.getMessage());
        //             System.debug('~~~ REcord fields that affected this error: ' + err.getFields());
        //         }
        //     }
        // }


        // Perform validations here   
        // Verify that an integration event is created 
        Test.getEventBus().deliver(); 
        System.debug('Integration Events created:' + PlatformEventHelper.eventList );
        // System.assertNotEquals( 0, PlatformEventHelper.eventList.size(), 'There should be one integration event in the list' );  // 2019-4-16 turn off assertion in case business rule in not activated
        /*

        {  
        UUID__c=ac7f95d3-eed6-8919-1df0-603e2eeee70a,
        Object_Name__c=Account,
        Record_ID__c=0010v00000H7tWHAAZ,
        Object_Payload__c=   {  
            "attributes":{  
                "type":"Account",
                "url":"/services/data/v44.0/sobjects/Account/0010v00000H7tWHAAZ"
            },
            "LastModifiedDate":"2018-10-17T09:39:24.000+0000",
            "IsDeleted":false,
            "CompareName":"TESTACCT",
            "OwnerAlias":"UUser",
            "CleanStatus":"Pending",
            "OwnerId":"0050v000001bdM2AAI",
            "CreatedById":"0050v000001bdM2AAI",
            "CreatedDate":"2018-10-17T09:39:24.000+0000",
            "Id":"0010v00000H7tWHAAZ",
            "LastModifiedById":"0050v000001bdM2AAI",
            "SystemModstamp":"2018-10-17T09:39:24.000+0000",
            "Name":"Test Acct"
        },
        Event_Type__c=INSERT
        }

        */

        // update an account
        rec.FirstName = 'Johnny';
        DML.save(rec);
        // Perform validations here    
        // Verify that two integration event is created 
        Test.getEventBus().deliver();
            // contact platform event is optional
        // System.assertNotEquals( 0, PlatformEventHelper.eventList.size(), 'There should be one integration event in the list' );

        Test.stopTest(); 

    }
}