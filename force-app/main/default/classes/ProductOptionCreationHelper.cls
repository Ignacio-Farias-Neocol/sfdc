public class ProductOptionCreationHelper {
	
    // for professional services feature
    public static void createProductOptions(Set<Id> productIdSet, String productFamily){
        
        List<SBQQ__ProductOption__c> psPO = new List<SBQQ__ProductOption__c> ();
        Map<Id, Set<Id>> featureProductOptionMap = new Map<Id, Set<Id>>();
        Set<Id> featureIdSet = new Set<Id>();        
        List<String> families = new List<String>(); //Families to add to
        families.add(productFamily);
        
        //Feature Name
        String featureName ='Professional Services';        
        
        List<SBQQ__ProductFeature__c> newFeatures = new List<SBQQ__ProductFeature__c>();
        for (Product2 cP : [SELECT ID,ProductCode,SBQQ__ConfigurationType__c,SBQQ__ConfigurationEvent__c, (SELECT ID,Name FROM SBQQ__Features__r) FROM Product2 WHERE Family IN :families AND SBCF_Is_Bundle__c = False and Id =: productIdSet]){
            //No feature detected?
            Boolean found = false;
            for (SBQQ__ProductFeature__c f : cP.SBQQ__Features__r){
                if(f.Name==featureName){found=true;}
            }
            if(!found){
                cP.SBQQ__ConfigurationType__c = 'Allowed';
                cP.SBQQ__ConfigurationEvent__c = 'Always';
                SBQQ__ProductFeature__c ProServe = new SBQQ__ProductFeature__c();
                ProServe.Name = featureName;
                ProServe.SBQQ__ConfiguredSKU__c = cP.ID;
                ProServe.SBQQ__Number__c = 200;
                ProServe.SBQQ__MinOptionCount__c=0;
                newFeatures.add(proServe);                          
            }
        }  
        if(!newFeatures.isEmpty()){
            Database.insert(newFeatures);
        }                
        
        //Now add Product Options
        //Proserve products
        ID OSQS = '01t5x00000EJ6HwAAL';
        ID OSHC = '01t5x00000EJ6HmAAL';
        ID OSUM = '01t5x00000EJ6HyAAL';        
        ID RQS = '01t5x00000EJ6HnAAL';
        ID RHC = '01t5x00000EJ6HoAAL';
        ID RUM = '01t5x00000EJ6HxAAL';
        
        //Do not adjust anything below this line
        //Create list of products to add
        Set<Id> psProds = new Set<Id>();
        psProds.add(OSUM);
        psProds.add(OSHC);
        psProds.add(OSQS);
        psProds.add(RUM);
        psProds.add(RHC);
        psProds.add(RQS);
        
        List<Product2> productList = [SELECT ID ,(SELECT ID,Name FROM SBQQ__Features__r where Name =: featureName) FROM product2 
                                      WHERE Family IN :families AND SBCF_Is_Bundle__c = False
                                      AND Id =: productIdSet];
        
        // get Product Feature Id's
        for(Product2 productRecord: productList){
            for (SBQQ__ProductFeature__c productFeature : productRecord.SBQQ__Features__r){
                if(productFeature.Name == featureName){
                    featureIdSet.add(productFeature.Id);
                }        
            }
        }
        
        // generate Product Feature - related Product options Map
        for(SBQQ__ProductFeature__c productFeature: [Select Id, (Select Id, SBQQ__OptionalSKU__c from SBQQ__ProductOptions__r where SBQQ__OptionalSKU__c =: psProds) from SBQQ__ProductFeature__c where Id =: featureIdSet]){
            for(SBQQ__ProductOption__c productOption: productFeature.SBQQ__ProductOptions__r){
                if(!featureProductOptionMap.containsKey(productFeature.Id)){
                    featureProductOptionMap.put(productFeature.Id, new Set<Id>());
                }
                featureProductOptionMap.get(productFeature.Id).add(productOption.SBQQ__OptionalSKU__c);          
            }
        }
        
        for (Product2 p : productList){
            for (SBQQ__ProductFeature__c pf : p.SBQQ__Features__r){
                if (pf.Name=='Professional Services'){
                    Integer Num = 1;
                    for (ID osID : psProds){
                        if(featureProductOptionMap.containsKey(pf.Id) && featureProductOptionMap.get(pf.Id).contains(osID)){
                            continue;
                        }
                        SBQQ__ProductOption__c nPO = new SBQQ__ProductOption__c();
                        nPO.SBQQ__ConfiguredSKU__c = p.ID;  
                        nPO.SBQQ__OptionalSKU__c = osID;  
                        npo.SBQQ__Feature__c = pf.id;
                        nPO.SBQQ__Number__c = num;
                        npo.SBQQ__Type__c = 'Accessory';  
                        num=num+1;
                        psPO.add(nPO);
                    }
                }
            }
        }
        insert psPO;        
    }
    
    // for options feature
    // for professional services feature
    public static void createProductOptionsForOptionsFeature(Set<Id> productIdSet, String productFamily){
        
        List<SBQQ__ProductOption__c> psPO = new List<SBQQ__ProductOption__c> ();
        Map<Id, Set<Id>> featureProductOptionMap = new Map<Id, Set<Id>>();
        Set<Id> featureIdSet = new Set<Id>();        
        List<String> families = new List<String>(); //Families to add to
        families.add(productFamily);
        
        //Feature Name
        String featureName ='Options';        
        
        List<SBQQ__ProductFeature__c> newFeatures = new List<SBQQ__ProductFeature__c>();
        for (Product2 cP : [SELECT ID,ProductCode,SBQQ__ConfigurationType__c,SBQQ__ConfigurationEvent__c, (SELECT ID,Name FROM SBQQ__Features__r) FROM Product2 WHERE Family IN :families AND SBCF_Is_Bundle__c = False and Id =: productIdSet]){
            //No feature detected?
            Boolean found = false;
            for (SBQQ__ProductFeature__c f : cP.SBQQ__Features__r){
                if(f.Name==featureName){found=true;}
            }
            if(!found){
                cP.SBQQ__ConfigurationType__c = 'Allowed';
                cP.SBQQ__ConfigurationEvent__c = 'Always';
                SBQQ__ProductFeature__c optionsFeature = new SBQQ__ProductFeature__c();
                optionsFeature.Name = featureName;
                optionsFeature.SBQQ__ConfiguredSKU__c = cP.ID;
                optionsFeature.SBQQ__Number__c = 100;
                optionsFeature.SBQQ__MinOptionCount__c=0;
                newFeatures.add(optionsFeature);                          
            }
        }  
        if(!newFeatures.isEmpty()){
            Database.insert(newFeatures);
        }                
        
        //Now add Product Options
		List<SBQQ__ProductOption__c> productOptionsList = [Select Id, SBQQ__Feature__c, SBQQ__ConfiguredSKU__c 
                                                           from SBQQ__ProductOption__c
                                                           where SBQQ__ConfiguredSKU__c =: productIdSet
                                                           and SBQQ__ConfiguredSKU__r.Family =: productFamily
                                                           and SBQQ__Feature__c = null];  
       
        // Product Feature List
        List<SBQQ__ProductFeature__c> featureList = [Select Id, SBQQ__ConfiguredSKU__c 
                                                           from SBQQ__ProductFeature__c
                                                           where SBQQ__ConfiguredSKU__c =: productIdSet
                                                           and SBQQ__ConfiguredSKU__r.Family =: productFamily
                                                           and Name =: featureName];
        
        for(SBQQ__ProductOption__c productOption: productOptionsList){
            if(productOption.SBQQ__ConfiguredSKU__c == featureList[0].SBQQ__ConfiguredSKU__c){
                productOption.SBQQ__Feature__c = featureList[0].Id;
            }         
        }
        
        if(!productOptionsList.isEmpty()){
            Database.update(productOptionsList);
        }
    }     
}