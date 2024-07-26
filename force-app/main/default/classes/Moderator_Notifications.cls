public without sharing class Moderator_Notifications Implements Schedulable
{
    public void execute(SchedulableContext sc)
    {
        sendmail();
    }
    
    public void sendmail()
    {// Please add your logic according to requirement
		OrgWideEmailAddress owa = [select id, DisplayName, Address from OrgWideEmailAddress WHERE Address = 'noreply@barracuda.com' limit 1];
        EmailTemplate template = [Select Id,Subject,Description,HtmlValue,DeveloperName,Body from EmailTemplate where name = 'Moderator Notifications' limit 1];
        Map<Id, String> userEmailMap = getMailAddresses();
        for(Id i : userEmailMap.keyset()){
            String emailAddress = userEmailMap.get(i);
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setTargetObjectId(i); 
            email.setTemplateID(template.Id);
			email.setOrgWideEmailAddressId(owa.id);
            email.setReplyTo('noreply@barracuda.com');
            email.toAddresses= new String[] {userEmailMap.get(i)};
            email.saveAsActivity = false;
            Messaging.sendEmail(New Messaging.SingleEmailMessage[]{email});
        }
    }
    //Get Email Addresses
    public Map<Id, String> getMailAddresses(){
        List<String> idList = new List<String>();
        Map<Id,String> mailToAddresses = new Map<Id,String>(); 
        
        Group gp = [SELECT (SELECT UserOrGroupId FROM GroupMembers) FROM Group WHERE Name = 'Community Moderators'];
        for (GroupMember gm : gp.GroupMembers) {
            idList.add(gm.UserOrGroupId);
        }
        List<User> userList = [SELECT Email FROM User WHERE Id IN :idList];
        for(User u : userList) {
            mailToAddresses.put(u.Id, u.email);
        } 
        return mailToAddresses;
    }
}