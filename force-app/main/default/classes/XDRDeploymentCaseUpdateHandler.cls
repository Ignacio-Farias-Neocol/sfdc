public with sharing class XDRDeploymentCaseUpdateHandler extends TriggerHandler {
    public override void afterInsert() {

        XDRDeploymentCaseUpdateHelper.updateXDRDeploymentCases(Trigger.new);
    }
}