public with sharing class DynamicValidationOpptyPartnerStageCheck  implements DynamicValidationRule {
    public Set<String> getExpectedFields() {
        return new Set<String> {
        }; 
    } 

    public Map<SObject,Boolean> evaluateRule(List<SObject> records){

    Map<Sobject,Boolean> oppsforNoStageChange = new Map<Sobject,Boolean>();
     /**
     * Added the condition to check if profileName is not blank, as a part of SFDC-18906.
     * This has been added to get rid of this validation for opportunities getting updated by Automated Process, 
     * since Automated Process doesn't have any profile.
	*/
        //Id profileId=userinfo.getProfileId();
    	//String profileName=[Select Id,Name from Profile where Id=:profileId].Name;
        List<User> lstUser = [select id, name, profileId, Profile.Name from User where id= :userInfo.getUserId()];
        String profileName = lstUser[0].Profile.Name != NULL ? lstUser[0].Profile.Name : '';
        if(!String.isBlank(profileName)){
        	System.debug('Profile Name::'+profileName);
        	System.debug('System.isQueueable::'+System.isQueueable());
            for(sobject o : records){
                Opportunity opp = (Opportunity) o;       
                if(!System.isQueueable() && 
                (opp.Stagename=='Accepted' ||  opp.Stagename=='Not Contacted' || opp.Stagename=='Discovery' ||  opp.Stagename=='Validation' ||
                 opp.Stagename=='Tech Evaluation' ||  opp.Stagename=='Negotiation' || opp.Stagename=='Contact Attempted' ||  opp.Stagename=='Customer Undecided' ||
                 opp.Stagename=='Quote Sent' ||  opp.Stagename=='Procurement / Approval Process' || opp.Stagename=='Commit' ||  opp.Stagename=='Order in Process' ||
                 opp.Stagename=='Closed Won' ||  opp.Stagename=='Credit' || opp.Stagename=='Closed Lost')
                 && profileName.tolowerCase().Contains('partner')) {
                 oppsforNoStageChange.put(opp,false);
                   }
            }
            System.debug('oppsforNoStageChange::'+oppsforNoStageChange);
        }
        return oppsforNoStageChange;  
    }
}