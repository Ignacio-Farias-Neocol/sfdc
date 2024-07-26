public class LeadService {

    public final static String DEFAULT_LEAD_STATUS {
        get {
            if(DEFAULT_LEAD_STATUS == NULL) {
                LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted=true LIMIT 1];
                DEFAULT_LEAD_STATUS = convertStatus?.MasterLabel;
            }

            return DEFAULT_LEAD_STATUS;
        }
        set;
    }

// private static Account reparentAccounts(Account clonedAccount, Account originalAccount){

//     try {
//         if(originalAccount?.ParentId != null){

//             System.debug('reparenting:: Cloned Account Parent Id before'+ clonedAccount.ParentId);

//             clonedAccount.ParentId=originalAccount.ParentId;
    
//             update clonedAccount;
//             System.debug('reparenting:: Cloned Account Parent Id after'+ clonedAccount.ParentId);
//         }
//         else if (originalAccount?.ParentId == null){
    
//            Account parentAcc=new Account( Name=originalAccount?.Name,
//                                          Type='Parent');
//            insert parentAcc;

//            System.debug('reparenting:: Parent Account Inserted '+ parentAcc.Id);
    
//            clonedAccount.ParentId=parentAcc.Id;
//            originalAccount.ParentId=parentAcc.Id;

//            System.debug('clonedAccountId ::'+ clonedAccount.Id);
    
//            update clonedAccount;
//            update originalAccount;          

//         }
//     }

//     catch(Exception ex){

//         throw new LeadConversionException('Failed to Reparent. ' + ex.getMessage());
//     }

//     return clonedAccount;
   
// }    


    public static ConversionResult convertLead(Id leadId, Account acc, Account originalAccount, Contact con, Opportunity opp, String donotCreateOpp) {

        System.debug('account ::'+ acc);
        System.debug('originalAccount::'+ originalAccount);
        if(originalAccount!=null){

            /// cloning
       
         Account clonedAccount=   AccountService.cloneAccount(originalAccount,acc);
          
         System.debug('clonedAccountId::'+ clonedAccount.Id);
        
         /// cloning

           if(clonedAccount.Id!=null) {
            acc = AccountService.reParentAccounts(clonedAccount,originalAccount);
           }
       }
        // If the Account does not have an ID, it is a new record and needs to be inserted
      else  if(acc != NULL && acc.Id == NULL) {            
            insert acc;
        }       
        // Convert the lead
        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(leadId);
        lc.setAccountId(acc.Id);
        lc.setConvertedStatus(DEFAULT_LEAD_STATUS);

        if(con.Id != NULL) {
            lc.setContactId(con.Id);
        }

        if(donotCreateOpp == 'true'){
            lc.setDoNotCreateOpportunity(true);
        } else if(opp?.Id != NULL) {
            lc.setOpportunityId(opp.Id);
        } else if(opp != NULL) {
            lc.setOpportunityName(opp.Name);
        }

        Database.LeadConvertResult lcr;
        try {
           lcr = Database.convertLead(lc);
        } catch (Exception e) {
            throw new LeadConversionException('Failed to convert lead. ' + e.getMessage());
        }

        if (!lcr.isSuccess()) {
            throw new LeadConversionException('Lead conversion failed. ' + lcr.getErrors()[0].getMessage());
        }

        if(con != NULL && con.Id == NULL) {
            // If the Contact was created by Lead Conversion, then update the attributes with form data
            con.Id = lcr.getContactId();
            System.enqueueJob(new UpdContactonLeadConvert(con),0);
            //String strcon = JSON.serialize(con,true);
            //updatecon(strcon);
            //update con;
        }

        return new ConversionResult(lcr, acc, con, opp);
    }

    public class LeadConversionException extends Exception {}

    public class ConversionResult {
        public String accountId { get; set; }
        public String contactId { get; set; }
        public String opportunityId { get; set; }
        public String accountName { get; set; }
        public String contactName { get; set; }
        public String opportunityName { get; set; }

        public ConversionResult(Database.LeadConvertResult lcr, Account acc, Contact con, Opportunity opp) {
            if(lcr == NULL) { throw new LeadConversionException('LeadConvertResult cannot be null'); }

            this.accountId = lcr.getAccountId();
            this.accountName = acc?.Name;

            this.contactId = lcr.getContactId();          
            //this.contactName = (con != NULL ? con.FirstName + ' ' + con.LastName : NULL);          
            this.contactName = (con!=NULL & con.Name!=Null) ? con?.Name : (con != NULL ? con.FirstName + ' ' + con.LastName : NULL);
            this.opportunityId = lcr.getOpportunityId();
            this.opportunityName = opp?.Name;
        }
    }
    
    /*@future
    public static void updatecon(String strcontact){
      Contact updcon = (Contact) JSON.deserialize(strcontact,Contact.class);
      Database.update(updcon,false);
    }*/
}