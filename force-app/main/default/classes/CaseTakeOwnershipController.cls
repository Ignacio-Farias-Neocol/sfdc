/**
 * @description Class used for various apex methods connected with Case Ownership lighting component
*/
public without sharing class CaseTakeOwnershipController {
    /**
    * @description Controller class method that change ownership of the case to the current user and also delete any PSR associated with the current case
    */
    @AuraEnabled
    public static String changeOwner(Id caseId){
        try{

            String msg;
            String strtechnical_Support;
            String strweb_Case;
            String strcommunity_Help;
            String strrequest_Quote;
            String strcase_Internal_Ticket_Record_Type;
            String strprofessional_Services;
            String strcustomer_Success;
            String strcommunity_Quote;
            
            system.debug('Get RecordTypeID for WM and TS');
            List<recordtype> web_Case = [select Id from recordtype where developername = 'Web_Case'];
            for (Recordtype r1: web_Case){
                strweb_Case = r1.id;
            }
            
            List<recordtype> technical_Support = [select Id from recordtype where developername = 'Technical_Support'];
            for (Recordtype r2: technical_Support){
                strtechnical_Support = r2.id;
            }
            
            List<recordtype> community_Help = [select Id from recordtype where developername = 'Community_Help'];
            for (Recordtype r3: community_Help){
                strcommunity_Help = r3.id;
            }
            
            List<recordtype> request_Quote = [select Id from recordtype where developername = 'Request_Quote'];
            for (Recordtype r4: request_Quote){
                strrequest_Quote = r4.id;
            }
            
            List<recordtype> case_Internal_Ticket_Record_Type = [select Id from recordtype where developername = 'Case_Internal_Ticket_Record_Type'];
            for (Recordtype r5: case_Internal_Ticket_Record_Type){
                strcase_Internal_Ticket_Record_Type = r5.id;
            }
            
            List<recordtype> professional_Services = [select Id from recordtype where developername = 'Professional_Services'];
            for (Recordtype r6: professional_Services){
                strprofessional_Services = r6.id;
            }
            System.debug('##strprofessional_Services:: ' + strprofessional_Services);
            
            List<recordtype> customer_Success = [select Id from recordtype where developername = 'Customer_Success'];
            for (Recordtype r7: Customer_Success){
                strcustomer_Success = r7.id;
            }
            
            
            List<recordtype> community_Quote = [select Id from recordtype where developername = 'Community_Quote'];
            for (Recordtype r7: community_Quote){
                strcommunity_Quote = r7.id;
            }
            
            System.debug('##strcommunity_Quote:: ' + strcommunity_Quote);
            
            System.debug('CaseTakeOwnershipController, changeOwner started');
            List <Case> lCases = [Select id, 
                                         CaseNumber, 
                                         Subject, 
                                         OwnerId,
                                         Status,
                                         RecordType.DeveloperName,
                                         RecordTypeId 
                                  From Case 
                                  Where id = :caseId];
            System.debug('##lCases:: ' + lCases);
            for (Case c: lCases){
                c.OwnerId = UserInfo.getUserId();
                if (c.RecordTypeId == strweb_Case) {
                    c.Take_Ownership_WM__c = true;
                    c.Take_Ownership_WM_DateTime__c = datetime.now();
                    System.debug('WM RT VALUE: ' + strweb_Case);

                }
            
                if (c.RecordTypeId == strtechnical_Support || c.RecordTypeId == strcommunity_Help || c.RecordTypeId == strrequest_Quote || c.RecordTypeId == strcase_Internal_Ticket_Record_Type || c.RecordType.DeveloperName == 'Professional_Services' || c.RecordTypeId == strcommunity_Quote || c.RecordTypeId == strcustomer_Success) {
                    c.Take_Ownership_TS__c = true;
                    c.Take_Ownership_TS_DateTime__c = datetime.now();
                    //SFDC 8141: Changing status to In Progress for New cases
                    if(c.Status == 'New'){
                        c.Status = 'In Progress';
                    }
                    System.debug('TS RT VALUE: ' + strtechnical_Support);
                    System.debug('CH RT VALUE: ' + strcommunity_Help); //SFDC 14039: Changing status to In Progress for New Community Help cases
                    System.debug('RQ RT VALUE: ' + strrequest_Quote); //SFDC 14039: Changing status to In Progress for New Request Quote cases
                    System.debug('ITRT RT VALUE: ' + strcase_Internal_Ticket_Record_Type); //SFDC 15017: Changing status to In Progress for New Internal Record Type cases
                    System.debug('PS RT VALUE: ' + strprofessional_Services); //SFDC-15889: Changing status to In Progress for Professional Service Record Type cases
                    System.debug('CS RT VALUE: ' + strcustomer_Success); //SFDC-17021: Changing status to In Progress for Customer Success Record Type cases
                    System.debug('CQ RT VALUE: ' + strcommunity_Quote); //SFDC-17036: Changing status to In Progress for Community Quote Record Type cases

                }
                msg = 'Case ' + c.CaseNumber + ' is now assigned to ' + UserInfo.getName() + '. ';


            }
            System.debug('##lCases:: ' + JSON.serialize(lCases));                
            withoutSharingDML.save(lCases);

            List <PendingServiceRouting > lPendingServiceRoutings = [select id from PendingServiceRouting where workItemId = :caseId];
            if (lPendingServiceRoutings.size() > 0 ){
                delete lPendingServiceRoutings;
                msg += '\n';
                // msg += ' ' + lPendingServiceRoutings.size() + ' Pending Service Routing record deleted. ';
            }


            return msg;

        } catch ( Exception e ){
            throw e;
        }
    }

}