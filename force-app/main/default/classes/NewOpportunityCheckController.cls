/**
* @author HZ
* @date 2020/05
*
* @group Controller
* @description apex controller for the NewOpportunityOverride component
*/
public with sharing class NewOpportunityCheckController {

    @AuraEnabled
    public static boolean checkNewOppPermission() {

        // return boolean
        if (FeatureManagement.checkPermission('Create_New_Opportunity')) {
            return true;
        }
        else {
            return false;
        }
    }
}