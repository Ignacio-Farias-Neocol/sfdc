@isTest
private class CPQ_OrderItemList_ControllerTest {
     @isTest static void myUnitTest() {
        CPQ_OrderItemList_Controller cont = new CPQ_OrderItemList_Controller();
        cont.getBaseURL();
        System.Debug(cont.listtype);

        cont.record = new Order(SBQQ__Quote__c = '001000000000001');
        System.Debug(cont.RMAReplaceSerials);
     }
}