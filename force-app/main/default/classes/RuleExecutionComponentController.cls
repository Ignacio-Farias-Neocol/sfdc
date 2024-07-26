/**
* @author Salesforce Services
* @date 10/29/2020
*
* @group Rule Engine
*
* @description: Component controller used to initiate the batch for executing ownership rules
*/
public with sharing class RuleExecutionComponentController {
    public List<Id> ruleIds {get;set;} // Rules to be evaluated
    public Id ruleId {get;set;} // Rule requested to be evaluated
    public Boolean runRuleFromRecordPage {get;set;} //Determines if the multiple rules are being executed or a specific rule from record page
    public String message {get;set;} //Message returned from the batch execution
    public Boolean showOKButton{get;set;} //Determines if OK button should be shown and Execute button should be hidden
    private static final String EMPTYID = '000000000000000'; //Used to check the empty ID provided when system cannot queue the batch

    public RuleExecutionComponentController() {
        showOKButton = false; //Initialize the value
    }

    //Run ownership rules selected by the user
    public void runOwnershipRules() {
        //If rules are present then execute the job
        if(ruleIds!=null && 
           !ruleIds.isEmpty()){
            //Create an instance of the batch job
            OpportunityOwnershipBatch batchInstance = new OpportunityOwnershipBatch(ruleIds);

            //Execute batch
            Id jobId = Database.executeBatch(batchInstance, 100);

            //If job was successfully queued then get the Job Id and show success message.
            //If job was not successfully queued then show the error message
            if(String.valueOf(jobId) != EMPTYID){
                message = String.format(Label.Opp_Owner_Rule_Job_Submitted, new List<String>{String.valueOf(jobId)});
            }
            else{
                message = Label.Opp_Owner_Rule_Job_Not_Submitted;
            }
        }
        //If rules were not selected then ask user to select rules. This will never happen since it is being caught in the VF page. 
        //This is a catch all. 
        else{
            message = Label.Opp_Owner_Rule_No_Rules_Selected;
        }

        //Show OK button to let users go back to object/record home page
        showOKButton = true;
    } 
    
    //Go back to the page that launched the VF page
    public PageReference goBack() {
        PageReference retURL;
        if(runRuleFromRecordPage){
            //Record home page if the request was initiated from a record home page
            retURL = new PageReference('/'+ruleId);
        }
        else{
            //Object home page if the request was initiated from a list view
            retURL = new PageReference('/'+Schema.SObjectType.Opportunity_Ownership_Rule__c.getKeyPrefix()+'/o');
        }
        retURL.setRedirect(true);
        return retURL;
    }      
}