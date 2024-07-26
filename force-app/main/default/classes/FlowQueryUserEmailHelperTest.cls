/**
* @author HZ
* @date 2019
*
* @description test class for FlowQueryUserEmailHelper
*   2020-02-04 : Initial creation
*/
@isTest
public with sharing class FlowQueryUserEmailHelperTest {

    @isTest static void unitTest() {

        User usr = TestDataFactory.createUser('System Administrator');
        List<Id> usrIds = new List<Id>();
        usrIds.add(usr.id);

        FlowQueryUserEmailHelper.GetParams param = new FlowQueryUserEmailHelper.GetParams();
        param.recIds = usrIds;
        List<FlowQueryUserEmailHelper.GetParams> params = new List<FlowQueryUserEmailHelper.GetParams> {param};

        Test.startTest();
        List<List<String>> results = FlowQueryUserEmailHelper.getRecords(params);
        System.assertEquals(1, results.size());
        Test.stopTest();
    }
}