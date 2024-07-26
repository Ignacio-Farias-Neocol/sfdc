@isTest
public class CPQRnwBtDelayExecutionContTest {
    public testMethod static void testDelay(){
        Test.startTest();
        //dc.delay = 10000;
        PageReference delay = Page.CPQRnwBtDelayExecution;
        Test.setCurrentPage(delay);
        delay.getParameters().put('CPQRnwBtDelayExecution','10000');
        CPQRnwBtDelayExecutionController dc = new CPQRnwBtDelayExecutionController();
        Test.stopTest();
    
    }
}