/**
* @author        Keerthi Atluri     
* @date          2020-05-15
* @description   A Mock callout response class to convert the trails to full partner
*
* @group         Mock Test
*/

@isTest
global class ConvertTrailToPartnerMockFail implements HttpCalloutMock {
    
    global HTTPResponse respond(HTTPRequest req) {        
        
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setStatusCode(400);
        return res;
    }
}