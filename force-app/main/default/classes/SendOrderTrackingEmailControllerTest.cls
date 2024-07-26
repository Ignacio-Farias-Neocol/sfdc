@isTest
public class SendOrderTrackingEmailControllerTest {
    @testSetup static void setup() {
        test.startTest();
        List<Contact> listOfContacts = TestDataFactory.partnercontactsDistributor;
        List<Order> orders = TestDataFactory.orders;
        test.stopTest();
    }
    @isTest static void emailAddressNotFoundContactTest(){        
        SendOrderTrackingEmailController.sendEmailMessge('test@barracuda.com','');
        List<Task> listOfActivities = [Select Id from Task]; 
        system.assertEquals(0,listOfActivities.size());
    }
    @isTest static void emailAddressFoundContactTest(){
        Order order = [Select Id From Order Limit 1]; 
        SendOrderTrackingEmailController.ErrorOrSuccessResponse response = SendOrderTrackingEmailController.sendEmailMessge('john.doe@test.com,mary.doe@test.com', order.Id);
        system.assertEquals('200', response.statusCode);
        List<Task> listOfActivities = [Select Id from Task]; 
        system.assertEquals(2,listOfActivities.size() , 'Email sent successfully, Activity record for the particular contact, will be created');
    }
    @isTest static void emailAddressFoundAndNotFoundContactTest(){
        Order order = [Select Id From Order Limit 1]; 
        SendOrderTrackingEmailController.ErrorOrSuccessResponse response = SendOrderTrackingEmailController.sendEmailMessge('john.doe@test.com,mary.doe@test.com,test@test.com', order.Id);
        system.assertEquals('500', response.statusCode);
        List<Task> listOfActivities = [Select Id from Task]; 
        system.assertEquals(0,listOfActivities.size());
    }
}