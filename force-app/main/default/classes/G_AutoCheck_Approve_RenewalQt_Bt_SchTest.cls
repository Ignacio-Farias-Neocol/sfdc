@istest
public with sharing class G_AutoCheck_Approve_RenewalQt_Bt_SchTest {
    public static testMethod void testschedule() {
		Test.StartTest();
		G_AutoCheck_Approve_RenewalQt_Bt_Sch testsche = new G_AutoCheck_Approve_RenewalQt_Bt_Sch();
		String sch = '0 0 23 * * ?';
		system.schedule('Test status Check', sch, testsche );
		Test.stopTest();
	}
}