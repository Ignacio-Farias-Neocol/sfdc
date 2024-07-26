/**
 * Created by Dilowar Hussain on 21/04/2023.
 *  
 *  Description:
 *  Test Class for the main class, "CloseParentOppForCancelledOrders"
 *  
 *  
 *  Added as a part of SFDC-18906
 */
@isTest
public class CloseParentOppForCancelledOrdersTest {
	public static List<Account> newAccount = new List<Account>();
    public static List <Opportunity> opportunities = new List<Opportunity>();
    /**
     * Create Test Data
     */
    public static void createData(){
        //Create Accounts, Reseller, Distributors
        newAccount = TestDataFactory.customers;
        //Create opportunities
        opportunities = TestDataFactory.opportunities;
        opportunities[0].AccountID = newAccount[0].id;
        //opportunities[0].Bill_To_Account__c = newAccount2[0].id;
        opportunities[0].Primary_Product_Family_2__c = 'Email Security Gateway'; // e.g. other values: Load Balancer, Phishline, Cloud Control
        opportunities[0].Model_Series__c = 'API';
        opportunities[0].StageName = 'Validation';
        opportunities[0].Amount = 3000;
        opportunities[0].CloseDate = System.today();
        //opportunities[0].Primary_Contact__c = cusCon[0].id;
        opportunities[0].LeadSource = 'Renewal';
        opportunities[0].PurchaseOrderID__c = '2020';
        opportunities[0].BypassBusinessGroupValidation__c = true;
        opportunities[0].Bypass_Validation__c = true;
        opportunities[0].Closed_Lost_Reason__c = '';
        update opportunities;
    }
    public testMethod static void testValidateOpptyClosure(){
        try{
            Test.startTest();
            createData();
            List<String> opptIDs = new List<String>();
            opptIDs.add(opportunities[0].id);
            if(!opptIDs.isEmpty()){
                //CloseParentOppForCancelledOrders closePOppty = new CloseParentOppForCancelledOrders();
                CloseParentOppForCancelledOrders.invokeClosingOperation(opptIDs);
            }
            Test.stopTest();
        }Catch(Exception e){
            system.debug('Exception'+e.getMessage()+'occurred at' +e.getStackTraceString());
        }
    }
}