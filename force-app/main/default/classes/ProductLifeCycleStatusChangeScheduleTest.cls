@isTest
public class ProductLifeCycleStatusChangeScheduleTest {
	
    @isTest
    static void testMethod01(){
        TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler');   
        SBQQ.TriggerControl.disable();
        
        String accountProductCode;
        String bundleProductCode;
        
        //Get the products eligible for upsell downsell
        for(Upsell_Downsell_Settings__mdt setting: [SELECT DeveloperName, 
                                                    Setting_Value__c 
                                                    FROM Upsell_Downsell_Settings__mdt 
                                                    WHERE DeveloperName in ('Account_Products','Level1_Bundle')]){
                                                        
                                                        //Populate product codes
                                                        if(String.isNotBlank(setting.Setting_Value__c)){
                                                            switch on setting.DeveloperName {
                                                                when 'Account_Products' {
                                                                    accountProductCode = setting.Setting_Value__c.split(',')[0];
                                                                }	
                                                                when 'Level1_Bundle' {
                                                                    bundleProductCode = setting.Setting_Value__c.split(',')[0]; 
                                                                }
                                                                when else {
                                                                    //Do Nothing
                                                                }
                                                            }
                                                        }
                                                    }
        
        //Product list
        List<Product2> prodList = new List<Product2>();
        
        //Create Account Product
        Product2 testAccountProduct                  = new Product2();
        testAccountProduct.Name                      = 'Account Product';
        testAccountProduct.Base_SKU__c               = accountProductCode;
        testAccountProduct.ProductCode               = accountProductCode; 
        prodList.add(testAccountProduct);
        
        //Create a Bundle Parent product
        Product2 testBundleParentProduct1             = new Product2();
        testBundleParentProduct1.Name                 = 'Bundle Parent 1';
        testBundleParentProduct1.Base_SKU__c          = bundleProductCode;
        testBundleParentProduct1.ProductCode          = bundleProductCode;
        prodList.add(testBundleParentProduct1);
        
        //Create a Bundle Parent product
        Product2 testBundleParentProduct2             = new Product2();
        testBundleParentProduct2.Name                 = 'Bundle Parent 2';
        testBundleParentProduct2.Base_SKU__c          = 'Bundle_Parent2';
        testBundleParentProduct2.ProductCode          = 'Bundle_Parent2';
        prodList.add(testBundleParentProduct2);
        
        //Create a Bundle Item product
        Product2 testBundleItemProduct1             = new Product2();
        testBundleItemProduct1.Name                 = 'Bundle Item1';
        testBundleItemProduct1.Base_SKU__c          = 'Bundle_Item1';
        testBundleItemProduct1.ProductCode          = 'Bundle_Item1';
        testBundleItemProduct1.SBQQ__Component__c   = true;
        testBundleItemProduct1.EOL__c = System.today();
        testBundleItemProduct1.EOS__c = System.today();
        testBundleItemProduct1.EOR__c = System.today();
        prodList.add(testBundleItemProduct1);
        
        //Create a Bundle Item product
        Product2 testBundleItemProduct2             = new Product2();
        testBundleItemProduct2.Name                 = 'Bundle Item2';
        testBundleItemProduct2.Base_SKU__c          = 'Bundle_Item2';
        testBundleItemProduct2.ProductCode          = 'Bundle_Item2';
        testBundleItemProduct2.SBQQ__Component__c   = true;
        prodList.add(testBundleItemProduct2);    
        
        insert prodList;   
        
        Test.startTest();        
        ProductLifeCycleStatusChangeSchedule sh1 = new ProductLifeCycleStatusChangeSchedule();      
        String sch = '0 0 23 * * ?';
        system.schedule('Test check', sch, sh1);   
        Test.stopTest();        
    }
}