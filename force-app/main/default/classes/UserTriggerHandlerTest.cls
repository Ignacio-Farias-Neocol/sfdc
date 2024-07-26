/**
 * Created by iyeung on 2/20/19.
 */

@isTest
public with sharing class UserTriggerHandlerTest {


    @isTest static void unitTest() {


        Test.StartTest();

        User u = new User(
                ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id,
                LastName = 'last',
                Email = 'sysadmin@test.com',
                Username = 'sysadmin@test.com' + System.currentTimeMillis(),
                CompanyName = 'TEST',
                Title = 'title',
                Alias = 'alias',
                TimeZoneSidKey = 'America/Los_Angeles',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US'
        );

        insert u;

        Test.StopTest();


    }

}