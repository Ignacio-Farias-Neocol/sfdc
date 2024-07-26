@isTest
class portalCommunicationControllerTest {
    @isTest
    static void testportalCommunicationController() {

        Account accObj = new Account();
        accObj.Name = 'Test Account';
        insert accObj;

        Contact conObj  = new Contact();
        conObj.FirstName = 'Test';
        conObj.LastName = 'Test';
        conObj.email = 'contact@test.com';
        insert conObj;

        Case caseObj = new Case();
        caseObj.AccountId = accObj.Id;
        caseObj.Status = 'New';
        caseObj.Priority = 'Medium';
        caseObj.Origin = 'Email';
        insert caseObj;

        FeedItem f = new FeedItem();
        f.Body = 'legal test';
        f.parentID = caseObj.id;  
        f.Visibility = 'AllUsers';
        insert f;

        Map<String, Object> req = new Map<String, Object>();
        req.put('recordId', caseObj.id);
        req.put('feedItemId', f.id);
        req.put('commentText', caseObj.id);
        PortalCommunicationController.insertFeedComment(JSON.serializePretty(req));
        PortalCommunicationController.getCustomerComments(JSON.serializePretty(req));
        Long logVal = 999999999;
        PortalCommunicationController.getRelativeDateTime(logVal);
        //POShippingController.getCustomerComments(JSON.serializePretty(req));
        //POShippingController.getCustomerComments(JSON.serializePretty(req));
        new portalCommunicationController();
    }
}