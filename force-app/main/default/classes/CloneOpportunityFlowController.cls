/**
* @author HZ
* @date 2020/02
*
* @group Controller
* @description apex controller for the CloneOpportunityFlow component
*/
public with sharing class CloneOpportunityFlowController {

    @AuraEnabled
    public static boolean checkClonePermission() {

        // return boolean
        if (FeatureManagement.checkPermission('Clone_Opportunity')) {
            return true;
        }
        else {
            return false;
        }
    }
}