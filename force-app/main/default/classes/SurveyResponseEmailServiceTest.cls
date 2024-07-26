@isTest
public class SurveyResponseEmailServiceTest {
    
    @isTest
    static void testUnsubscribe() {
    
       // Create a new email and envelope object.
       Messaging.InboundEmail email = new Messaging.InboundEmail() ;
       Messaging.InboundEnvelope env    = new Messaging.InboundEnvelope();   
       
       // Test with the subject that matches the unsubscribe statement.
       email.subject = 'test unsubscribe test';
       email.plainTextBody = 'test';
       env.fromAddress = 'user@acme.com';
       
       // Call the class and test it with the data in the testMethod.
       SurveyResponseEmailService serviceObj = new SurveyResponseEmailService();
       serviceObj.handleInboundEmail(email, env);
                            
    }
     
    @isTest    
    static void testUnsubscribe2() {
    
       // Create a new email and envelope object.
       Messaging.InboundEmail email = new Messaging.InboundEmail();
       Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();    
       
       // Test with a subject that does not contain "unsubscribe."
       email.subject = 'test';
       email.plainTextBody = 'test ##$$##a3g7j000000T8wz##$$##';
       env.fromAddress = 'user@acme.com';
    
       SurveyResponseEmailService serviceObj = new SurveyResponseEmailService();
       serviceObj.handleInboundEmail(email, env);                     
    }
}