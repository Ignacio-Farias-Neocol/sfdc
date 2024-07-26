/**
* @author HZ
* @date 2020
*
* @description helper class for returning random number in flows
*   2020-05-21 : Initial creation
*/

@isTest
public with sharing class FlowRandomNumberHelperTest {

   @isTest static void unitTest() {

        FlowRandomNumberHelper.GetParams param = new FlowRandomNumberHelper.GetParams();
        param.maxRange = 100000;
        List<FlowRandomNumberHelper.GetParams> params = new List<FlowRandomNumberHelper.GetParams> {param};

        Test.startTest();
        List<Integer> results = FlowRandomNumberHelper.getRandomNumber(params);
        System.assertEquals(1, results.size());
        Test.stopTest();
  }
}