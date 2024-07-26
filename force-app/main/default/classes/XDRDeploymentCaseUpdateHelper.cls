public  class XDRDeploymentCaseUpdateHelper {  

    public static void updateXDRDeploymentCases( List<XDR_Deployment_Case_Update__e> eList ){    
       
        System.debug('##updateXDRDeploymentCase');

        LogModel log = LogModel.startLog('XDRDeploymentCaseUpdateHelper', 'updateXDRDeploymentCase', 'Asynchronous Process');
      
        List<Case> cUpdate=new List<Case>();

        for(XDR_Deployment_Case_Update__e e: eList){

            log.addlog('CaseID :'+ e.Case_Id__c);
            log.addlog('XDR Executed Date :'+ e.XDR_TnC_Executed__c);

        if(!String.isBlank(e.Case_Id__c) && e.XDR_TnC_Executed__c!=null) {           

                Case c =new Case(Id=e.Case_Id__c, XDR_TnC_Executed__c=e.XDR_TnC_Executed__c,
                Status='XDR_TnC Executed');         
                
                cUpdate.add(c);
            }                    
     }

        if(cUpdate.size()>0) {

            log.addlog('Case Ids to be Updated :: '+  cUpdate);          
            ID jobID = System.enqueueJob(new AsyncXDRCaseUpdate(cUpdate));       
            log.addlog('Job Enqueued Id:: '+  jobID);
        }                      

          log.endlog();
    }
}