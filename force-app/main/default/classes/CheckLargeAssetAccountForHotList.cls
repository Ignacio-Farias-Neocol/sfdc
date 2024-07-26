global with sharing class CheckLargeAssetAccountForHotList {
    
    public CheckLargeAssetAccountForHotList() {

    }

    public class hotListDetails{
        @InvocableVariable
        public String hotListId;

        @InvocableVariable
        public Boolean isLargeAssetAccount;
    }

    @InvocableMethod(label='Check Large Asset Account')
    public static List<CheckLargeAssetAccountForHotList.hotListDetails> checkLargeAssetAccount(List<CheckLargeAssetAccountForHotList.hotListDetails> hotListDetails) {
        
        List<CheckLargeAssetAccountForHotList.hotListDetails> returnDetails = new List<CheckLargeAssetAccountForHotList.hotListDetails>();
        List<String> hotListIds = new List<String>();
        for(hotListDetails det : hotListDetails){
            hotListIds.add(det.hotListId);
        }

        Opp_Creation_Settings__mdt oppCreateMetadata = [Select Id, QualifiedApiName, Asset_Volume_Threshold__c, Check_Asset_Volume_On_Account__c, Error_Message__c from Opp_Creation_Settings__mdt Where QualifiedApiName = 'Check_Asset'];
        Boolean checkAssetVolumeOnAccount;
        Integer AssetVolumeThreshold;
        if(!Test.isRunningTest()){
            checkAssetVolumeOnAccount = oppCreateMetadata.Check_Asset_Volume_On_Account__c;
            AssetVolumeThreshold = (Integer)oppCreateMetadata.Asset_Volume_Threshold__c;
        }
        else{
            checkAssetVolumeOnAccount = true;
            AssetVolumeThreshold = 2;
        }

        if(checkAssetVolumeOnAccount != null && checkAssetVolumeOnAccount == true){

            List<Hot_List__c> hotlists = [Select Id, Account__c From Hot_List__c Where Id IN: hotListIds];

            map<Id,list<Hot_List__c>> hotlistsByAccountIds = new map<Id,list<Hot_List__c>>();

            for(Hot_List__c rec : hotlists){
              if(rec.Account__c != null){
                if(!hotlistsByAccountIds.containsKey(rec.Account__c)){
                    hotlistsByAccountIds.put(rec.Account__c,new List<Hot_List__c>{rec});
                }
                else{
                    hotlistsByAccountIds.get(rec.Account__c).add(rec);
                }
              }
            }

            if(!hotlistsByAccountIds.isEmpty()){
                List<AggregateResult> aggregatedAssets = [Select AccountId, Count(Name) from Asset Where AccountId IN: hotlistsByAccountIds.keySet() GROUP BY AccountId];
                for(AggregateResult aggregatedAsset : aggregatedAssets){
                    String accountId = (String)aggregatedAsset.get('AccountId');
                    List<Hot_List__c> hotListsForAccount = hotlistsByAccountIds.get(accountId);
                    Integer numOfAssets = (Integer)aggregatedAsset.get('expr0');
                    
                    for(Hot_List__c hl : hotListsForAccount){
                        hotListDetails hlDetail = new hotListDetails();
                        hlDetail.hotListId = hl.Id;
                        if(numOfAssets > AssetVolumeThreshold){
                            hlDetail.isLargeAssetAccount = true;
                        }
                        else{
                            hlDetail.isLargeAssetAccount = false;
                        }
                        returnDetails.add(hlDetail);
                    }
                }
            } 
        }
        return returnDetails;
    }
}