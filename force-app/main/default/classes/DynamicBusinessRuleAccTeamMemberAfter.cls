/**
* @author Aditya Padhy
* @date 2022-02-24
*
* @group DynmaicBusinessRuleAction
* @group-content
*
* @description:
*   SFDC-16765 Customer Success List View - Account Team Role + Account relationship
*	2024-04-12 Commenting out this logic from Account Team trigger and moved to Account itself
*  
*/
public class DynamicBusinessRuleAccTeamMemberAfter implements DynamicBusinessRuleAction {
    public void processRecords(Map<Id,SObject> newRecordMap, Map<Id,SObject> oldRecordMap, List <SObject> records, String jsonParameter, String triggerOrder, String triggerContext) {
        if (triggerContext.contains('Insert')) {
            //updateAccountWithAccTeamMembers((List<AccountTeamMember>)records, null, triggerContext);
        }        
        if (triggerContext.contains('Update')) {
            //updateAccountWithAccTeamMembers((List<AccountTeamMember>)records, oldRecordMap, triggerContext);
        }
        if (triggerContext.contains('Delete')) {
             system.debug('record Deleted');
             //updateAccountWithAccTeamMembers(null, oldRecordMap, triggerContext);
        }
       
    }
    
    /*
    public void updateAccountWithAccTeamMembers (List<AccountTeamMember> listOfNewTeamMembers, Map<Id, SObject> mapOfOldTeamMembers, String triggerContext){
		LogModel log = LogModel.startLog('DynamicBusinessRuleAccTeamMemberAfter', 'updateAccountWithAccTeamMembers');
		try{
			Set<String> setOfTeamRoles = new Set<String>();
			Set<Id> setOfAccountIds = new Set<Id>();
			AccountTeamMember oldTeamMember;
			for(Account_Team_Member_Role__mdt atmr : Account_Team_Member_Role__mdt.getAll().values()){
				setOfTeamRoles.add(atmr.Team_Member_Role__c);
			}
			if(!triggerContext.contains('Delete')){
				for(AccountTeamMember accTeamMem : listOfNewTeamMembers){
					oldTeamMember = (mapOfOldTeamMembers == null) ? null : (AccountTeamMember)mapOfOldTeamMembers.get(accTeamMem.Id);
					if((oldTeamMember == null && setOfTeamRoles.contains(accTeamMem.TeamMemberRole)) ||(oldTeamMember != null && accTeamMem.TeamMemberRole != oldTeamMember.TeamMemberRole && setOfTeamRoles.contains(accTeamMem.TeamMemberRole))){
						setOfAccountIds.add(accTeamMem.AccountId);
					}
				}
			}else{
				for(AccountTeamMember oldAccTeamMem : (List<AccountTeamMember>)mapOfOldTeamMembers.values()){
					if(setOfTeamRoles.contains(oldAccTeamMem.TeamMemberRole)){
						setOfAccountIds.add(oldAccTeamMem.AccountId);
					}
				}
			}
			
			if(!setOfAccountIds.isEmpty()){
				List<String> lstOfCSMs;
				List<String> lstOfCSMNames;
				List<String> lstOfCSMManagerNames;
				List<Account> lstOfAccsToUpdate = [SELECT Id,CSM__c,(SELECT Id, User.FirstName, User.LastName, User.Manager.Name, UserId FROM AccountTeamMembers WHERE TeamMemberRole IN: setOfTeamRoles) FROM Account WHERE Id IN: setOfAccountIds];            
				for(Account acc : lstOfAccsToUpdate){
					lstOfCSMs = new List<String>(); 
					lstOfCSMNames = new List<String>();
					lstOfCSMManagerNames = new List<String>();
					for(AccountTeamMember atm : acc.AccountTeamMembers){
						lstOfCSMs.add(atm.UserId);
						lstOfCSMNames.add(atm.User.FirstName+' '+atm.User.LastName);
						lstOfCSMManagerNames.add(atm.User.Manager.Name);
					}
					acc.CSM__c = String.join(lstOfCSMs, ',');
					acc.CSM_Name__c = String.join(lstOfCSMNames, ',');
					acc.CSM_Manager__c = String.join(lstOfCSMManagerNames, ',');
				}
				update lstOfAccsToUpdate;
			}
		}  catch(Exception ex){
			log.addExceptionLog(ex);
		}
	}*/
}