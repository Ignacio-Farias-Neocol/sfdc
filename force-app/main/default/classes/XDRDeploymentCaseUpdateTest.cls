@isTest
public  class XDRDeploymentCaseUpdateTest {

    @testSetup
    static void setup() {

        Case c= new Case ( Status='New', Origin='Opportunity', RecordTypeId='0125x000000cdlRAAQ');
        insert c;
    }

    @isTest static void testAsyncXDRUpdate() {

        Case xdrc = [SELECT Id,Status FROM Case];

        XDR_Deployment_Case_Update__e XDRUpdateEvent = new XDR_Deployment_Case_Update__e(
            Case_Id__c=xdrc.Id,
            XDR_TnC_Executed__c=datetime.now()
          );

          Test.startTest();

          Database.SaveResult sr = EventBus.publish(XDRUpdateEvent);
   
          Test.stopTest();
          System.assertEquals(true, sr.isSuccess());
    }
}