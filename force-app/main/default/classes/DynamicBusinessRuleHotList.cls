/**
* @author Yuli Fintescu
* @date 2019
*
* @group DynmaicBusinessRuleAction
*
* @description implementation of DynamicBusinessRuleAction interface to contract triggers
* SFDC-9061 Need to use serial information from Hot List to create a serial / assigned serial
*/
public class DynamicBusinessRuleHotList implements DynamicBusinessRuleAction {
    public void processRecords(Map<Id,SObject> newRecordMap, Map<Id,SObject> oldRecordMap, List <SObject> records, String jsonParameter, String triggerOrder, String triggerContext) {
        if (triggerOrder == 'POST') {
            if (triggerContext.contains('Insert')) {
                CreateSerial(records);
            }
        }
    }

    //SFDC-9061
    private static void CreateSerial(List<SObject> records) {
        //serial number => hot list record
        Map<String, Hot_List__c> candidates = new Map<String, Hot_List__c>();
        //serial number => product code
        Map<String, String> baseProductSkus = new Map<String, String>();

        for (Hot_List__c hl : (List<Hot_List__c>)records){
            if (hl.Business_Group__c == 'Core' && !String.isEmpty(hl.Serial_Number__c) && !String.isEmpty(hl.Products__c)) {
                String serialNumber = hl.Serial_Number__c.substringAfterLast('-');
                candidates.put(serialNumber, hl);

                //use base product code for product look up
                String bpSku = hl.Products__c.substringBefore('-');
                if(!String.isEmpty(bpSku)) {
                    baseProductSkus.put(serialNumber, bpSku.toUpperCase());
                }
            }
        }

        if (candidates.isEmpty() || baseProductSkus.isEmpty()) {
            return;
        }

        Set<String> existingSerials = new Set<String>();
        for (Serial__c s : [Select ID, Serial_Number__c From Serial__c Where Serial_Number__c in: candidates.keySet()]) {
            if (!String.isEmpty(s.Serial_Number__c))
                existingSerials.add(s.Serial_Number__c);
        }

        Map<String, Product2> exitingProducts = new Map<String, Product2>();
        for (Product2 p : [Select ID, Name, ProductCode, SBCF_Form_Factor__c From Product2 Where ProductCode in: baseProductSkus.values()]) {
            exitingProducts.put(p.ProductCode.toUpperCase(), p);
        }

        //collect errors. any error will be added to Other_Notes__c field
        Map<String, Hot_List__c> errors = new Map<String, Hot_List__c>();

        List<Asset> assetsToCreate = new List<Asset>();
        List<Serial__c> serialsToCreate = new List<Serial__c>();
        List<Hot_List__c> hls = new List<Hot_List__c>();//for collecting errors
        
        for (String key : candidates.keySet()) {
            Hot_List__c hl = candidates.get(key);
            String bpSku = baseProductSkus.get(key);
            
            if (String.isEmpty(hl.Account__c) && String.isEmpty(hl.Contact__c)) {
                Hot_List__c error = new Hot_List__c(ID = hl.Id, Other_Notes__c = 'Generate Serial Error: Must have account or contact');
                errors.put(error.ID, error);
                continue;
            } 
            
            if (String.isEmpty(bpSku)) {
                Hot_List__c error = new Hot_List__c(ID = hl.Id, Other_Notes__c = 'Generate Serial Error: Base Product not specified');
                errors.put(error.ID, error);
                continue;
            } 
            
            if (existingSerials.contains(key)) {
                Hot_List__c error = new Hot_List__c(ID = hl.Id, Other_Notes__c = 'Generate Serial Error: Serial Number Exists');
                errors.put(error.ID, error);
                continue;
            }
            
            Product2 product = exitingProducts.get(bpSku);
            if (product == null) {
                Hot_List__c error = new Hot_List__c(ID = hl.Id, Other_Notes__c = 'Generate Serial Error: Base Product not found');
                errors.put(error.ID, error);
                continue;
            }

            /*
                Asset Name: Just the generic Product Name (Barracuda backup 390)
                Status (active)
                Serial
                Product: Lookup field -base product
                Account
                End user account
                Reseller Account (If applicable)
                Distributor Account (If applicable)
                Quantity: Should be 1 or user quantity if SaaS product
                Appliance line type: DEMO
            */
            Decimal quantity = 1;
            if (product.SBCF_Form_Factor__c == 'SaaS' && (hl.Employee_Count_User_Entered__c > 0 || hl.Employee_Count_Rep_Entered__c > 0)) {
                quantity = hl.Employee_Count_User_Entered__c > 0 ? hl.Employee_Count_User_Entered__c : hl.Employee_Count_Rep_Entered__c;
            }
            Asset a = new Asset(Name = product.Name,
                                Status = 'Installed',
                                SBCF_Serial_Number__c = key,
                                Product2Id = product.Id,
                                AccountId = hl.Account__c, 
                                ContactId = hl.Contact__c, 
                                EndUserAccount__c = hl.Account__c, 
                                ResellerAccount__c = hl.Reseller__c, 
                                Quantity = quantity,
                                DistributorAccount__c = hl.Distributor__c, 
                                Business_Group__c = hl.Business_Group__c,
                                Appliance_Line_Type__c = 'Demo');
            assetsToCreate.add(a);
            
            Serial__c s = new Serial__c(Serial_Number__c = key, 
                                Status__c = 'Active',
                                Base_Product_SKU__c = product.ProductCode,
                                Business_Group__c = hl.Business_Group__c);
            serialsToCreate.add(s);
            
            hls.add(hl);
        }
        
        if (!hls.isEmpty()) {
            //create assets
            Database.SaveResult[] srListAsset = database.insert(assetsToCreate, false);
            //create serials
            Database.SaveResult[] srListSerial = database.insert(serialsToCreate, false);
            
            //------------------------------------------
            //collect results of assets and serials creation
            //and build assigned serial records and populate root id on the new assets which is the new asset SFID
            Database.DMLOptions dml = new Database.DMLOptions();
            dml.allowFieldTruncation = true;
            
            List<Asset> assetsToUpdate = new List<Asset>();
            List<Assigned_Serial__c> asgserialsToCreate = new List<Assigned_Serial__c>();
            List<Hot_List__c> hls2 = new List<Hot_List__c>();//for collecting errors

            for (Integer i = 0; i < hls.size(); i++) {
                Hot_List__c hl = hls[i];
                Database.SaveResult srAsset = srListAsset[i];
                Database.SaveResult srSerial = srListSerial[i];

                String errorMsg = '';
                if (!srSerial.isSuccess()) {//if create serial failed
                    for(Database.Error err : srSerial.getErrors())
                        errorMsg = errorMsg + err.getMessage() + '\n';
                } else {
                    if (!srAsset.isSuccess()) {//if create asset failed
                        for(Database.Error err : srAsset.getErrors())
                            errorMsg = errorMsg + err.getMessage() + '\n';
                    } else {   
                        //build assigned serial records
                        Assigned_Serial__c asg = new Assigned_Serial__c(Status__c = 'Active',
                                Serial__c = srSerial.getId(),//serialsToCreate[i].Id;
                                Asset__c = srAsset.getId(),//assetsToCreate[i].Id;
                                Business_Group__c = hl.Business_Group__c/*,
                                End_User_Account__c = hl.Account__c*/);
                        asgserialsToCreate.add(asg);
                        hls2.add(hl);
                    }
                }

                //populate root id for the new assets
                if (srAsset.isSuccess()) {
                    String assetId = srAsset.getId();
                    Asset a = new Asset(ID = assetId, SBQQ__RootId__c = assetId);
                    assetsToUpdate.add(a);
                }
                
                if (!String.isEmpty(errorMsg)) {
                    Hot_List__c errored = new Hot_List__c(ID = hl.Id);
                    errored.setOptions(dml);
                    errored.Other_Notes__c = 'Failed to Generate Asset and Serial: ' + errorMsg;
                    errors.put(errored.Id, errored);
                }
            }

            if (!asgserialsToCreate.isEmpty()) {
                Database.SaveResult[] srList = database.insert(asgserialsToCreate, false);
                for (Integer i = 0; i < hls2.size(); i++) {
                    Hot_List__c hl = hls[i];
                    Database.SaveResult sr = srList[i];

                    if (!sr.isSuccess()) {//if create assigned serial failed
                        String errorMsg = '';
                        for(Database.Error err : sr.getErrors())
                            errorMsg = errorMsg + err.getMessage() + '\n';
                        
                        Hot_List__c errored = new Hot_List__c(ID = hl.Id);
                        errored.setOptions(dml);
                        errored.Other_Notes__c = 'Failed to Generate Assighed Serial: ' + errorMsg;
                        errors.put(errored.Id, errored);
                    } 
                }
            }

            if (!assetsToUpdate.isEmpty())
                database.update(assetsToUpdate, false);
        }

        if (!errors.isEmpty())
            database.update(errors.values(), false);
    }
}
/*
Delete [select ID from Asset Where CreatedDate = Today and CreatedByID = '005f200000A0Orb'];
Delete [select ID from Serial__c Where CreatedDate = Today and CreatedByID = '005f200000A0Orb'];
Delete [select ID from Hot_List__c Where CreatedDate = Today and CreatedByID = '005f200000A0Orb'];
*/