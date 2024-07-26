public class SendQuoteAlertFromOpportunity{
    @InvocableMethod
    public static void sendQuoteFromOpportunity(List<ID> opportunityIds){
        Set<Id> opportunityIdSet = new Set<Id>(opportunityIds);
        System.debug(':::::opportunityIdSet:::::'+JSON.serialize(opportunityIdSet));
        List<Opportunity> opportunityList = [Select id,Primary_Contact__r.Email,SBQQ__PrimaryQuote__r.SBQQ__PrimaryContact__c,SBQQ__PrimaryQuote__r.SBQQ__PrimaryContact__r.Email,SBQQ__PrimaryQuote__c,Owner.Email,Owner.Name from Opportunity where Id in: opportunityIdSet];
        System.debug('opportunityList:::::'+JSON.serialize(opportunityList));
        System.debug('opportunityList::SIZE:::::'+opportunityList.size());
        List<EmailTemplate> emailTemplate=  [Select id from EmailTemplate where DeveloperName = 'Send_Quote_Email_Alert' LIMIT 1];
        System.debug('emailTemplate:::::'+JSON.serialize(emailTemplate));
        OrgWideEmailAddress owea = new OrgWideEmailAddress();
        List<OrgWideEmailAddress> oweaList = [SELECT Id, Address, DisplayName FROM
                                              OrgWideEmailAddress WHERE Address='renewals@barracuda.com' LIMIT 1];
        if(oweaList != null && !oweaList.isEmpty()){
            owea = oweaList[0];
            System.debug('owea:::::'+JSON.serialize(owea));
            List<Messaging.SingleEmailMessage> sendQuoteAlertEmailList = new List<Messaging.SingleEmailMessage>();
            System.debug('opportunityList:::::'+JSON.serialize(opportunityList));
            if(opportunityList != null && !opportunityList.isEmpty()){
                for(Opportunity opp: opportunityList){
                    System.debug('emailTemplate[0].Id:::::'+emailTemplate[0].Id);
                    System.debug('opp.SBQQ__PrimaryQuote__c:::::'+opp.SBQQ__PrimaryQuote__c);
                    System.debug('opp.Primary_Contact__r.Email:::::'+opp.SBQQ__PrimaryQuote__r.SBQQ__PrimaryContact__r.Email);
                    System.debug('owea.id:::::'+owea.id);
                    
                    if(opp.SBQQ__PrimaryQuote__r.SBQQ__PrimaryContact__r.Email != null && opp.Owner.Email != null && owea.id != null && opp.SBQQ__PrimaryQuote__c != null){
                        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
                        message.setTargetObjectId(Userinfo.getUserId());
                        message.setReplyTo(opp.Owner.Email);
                        message.setUseSignature(false);
                        message.setBccSender(false);
                        message.setSaveAsActivity(true);
                        if(!emailTemplate.isEmpty()){
                            message.setTemplateId(emailTemplate[0].Id);
                        }
                        message.setWhatId(Id.valueOf(opp.SBQQ__PrimaryQuote__c));
                        message.toAddresses = new String[]{opp.SBQQ__PrimaryQuote__r.SBQQ__PrimaryContact__r.Email};
                            message.setTreatTargetObjectAsRecipient(false);
                        message.setOrgWideEmailAddressId(owea.id);
                        
                        sendQuoteAlertEmailList.add(message);
                        opp.Send_Quote_Alert__c = false;
                        opp.Last_Quote_Auto_sent__c = Datetime.now();
                    }
                }
            }
            System.debug('sendQuoteFromOpportunity :: sendQuoteAlertEmailList ::'+JSON.serialize(sendQuoteAlertEmailList));
            if(!sendQuoteAlertEmailList.isEmpty()){
                List<Messaging.SendEmailResult> sendEmailResults = new List<Messaging.SendEmailResult>();
                if(!Test.isRunningTest()){
                    sendEmailResults = Messaging.sendEmail(sendQuoteAlertEmailList,true);
                }
                
                Boolean isEmailSuccessfullySent = false;
                for(Messaging.SendEmailResult result: sendEmailResults){
                    if(!result.IsSuccess()){
                        for(Messaging.SendEmailError  error: result.getErrors()){
                            System.debug('Error while sending email:' + error);
                        }
                    }else{
                        isEmailSuccessfullySent = true;                        
                        System.debug('Email Send Successfully');
                    }
                }
                if(isEmailSuccessfullySent) Database.update(opportunityList);
            }
        }
    }
}