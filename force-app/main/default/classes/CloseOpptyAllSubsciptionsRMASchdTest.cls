@isTest
public with sharing class CloseOpptyAllSubsciptionsRMASchdTest {
    public testMethod static void testBatchSch(){
        CloseOpptyAllSubsciptionsRMASchd s = new CloseOpptyAllSubsciptionsRMASchd();
        String sch ='0 0 * * * ?'; 
        System.schedule('TestCloseOpptyAllSubsciptionsRMASchd', sch, s);
    }
}