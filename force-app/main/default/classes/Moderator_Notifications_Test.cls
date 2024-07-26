@isTest
public class Moderator_Notifications_Test {
    
    @isTest static void executeTest(){
        Test.StartTest();
		Moderator_Notifications tsc = new Moderator_Notifications();
        String sch = '0 0 23 * * ?';
        system.schedule('Test check', sch, tsc);
		Test.StopTest();         
    }
}