@isTest public class CaseCustomButtonActionsTest
{
    @isTest
    static void unitTest(){

    // by pass business action ,
    TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler'); // among other things, keep the contact status as active
    List <Case> l = TestDataFactory.dpaasCases;
    TriggerHandler.clearAllBypasses();

    System.debug('support Cases: ' + l);

     Test.startTest();
        // change case type to DPAAS
        List <Case_Quick_Action_Button__mdt > buttons = CaseCustomButtonActions.getCustomButtonActionOptions(l[0].id);
        System.assertNotEquals(null, buttons);
        System.debug('buttons: ' + buttons);
        CaseCustomButtonActions.performQuickAction(l[0].id, buttons[0].id);

        /*
        CaseCustomButtonActions.shutdown(l[0].id);
        CaseCustomButtonActions.systemDate(l[0].id);
        CaseCustomButtonActions.dpass(l[0].id);
        CaseCustomButtonActions.localVault(l[0].id);
        */

     Test.stopTest();
    }

}