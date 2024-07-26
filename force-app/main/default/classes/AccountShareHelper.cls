public without sharing class AccountShareHelper {
    

    public static void addAccountShare(String accountId, String userId) {
        
        //Manual Share end user account to disti/reseller user
        AccountShare newAcctShare = new AccountShare();
        //Id of record being shared
        newAcctShare.AccountId = accountId;
        newAcctShare.UserOrGroupId = userId;
        newAcctShare.AccountAccessLevel = 'Edit';
        newAcctShare.ContactAccessLevel = 'Edit';
        newAcctShare.OpportunityAccessLevel = 'Edit';

        insert newAcctShare;
    
    }

    public static Boolean getAccountShare(String accountId, String userId) {
        
        List<AccountShare> acctShare = [
            SELECT 
            Id 
            FROM AccountShare
            WHERE AccountId = :accountId
            AND UserOrGroupId = :userId
            AND RowCause = 'manual'
            LIMIT 1
        ];

        return !acctShare.isEmpty();

    }

    public static void deleteAccountShare(String accountId, String userId) {
        
        List<AccountShare> acctShare = [
            SELECT 
            Id 
            FROM AccountShare
            WHERE AccountId = :accountId
            AND UserOrGroupId = :userId
            AND RowCause = 'manual'
            LIMIT 1
        ];

        if(!acctShare.isEmpty()) {
            delete acctShare;
        }

    }

}