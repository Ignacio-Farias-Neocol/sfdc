global class ProductOptionCreationBatch implements Database.Batchable<sObject>, Database.Stateful{  
    
    private String productFamily;
    private String featureName;
    
    global ProductOptionCreationBatch(String productFamily, String featureName) {
		this.productFamily = productFamily;
        this.featureName = featureName;
    }    
    
    public Database.QueryLocator start(Database.BatchableContext BC){
        String query = 'SELECT ID FROM product2 WHERE Family =: productFamily AND SBCF_Is_Bundle__c = False';
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext BC, List<sObject> scope){
        Set<Id> productIdSet = new Set<Id>(); 
        for(sObject s : scope){
            Product2 productRecord = (Product2) s;
            productIdSet.add(productRecord.Id);            
        }	
        if(featureName == 'Professional Services'){
            ProductOptionCreationHelper.createProductOptions(productIdSet, productFamily);
        } else if(featureName == 'Options'){
            ProductOptionCreationHelper.createProductOptionsForOptionsFeature(productIdSet, productFamily);
        }
        
    }
    
    public void finish(Database.BatchableContext BC){
        
    }
}