trigger XDRDeploymentCaseUpdateTrigger on XDR_Deployment_Case_Update__e (after insert) {

    new XDRDeploymentCaseUpdateHandler().run();
}