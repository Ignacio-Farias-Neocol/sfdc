public with sharing class CudaCommunityThemeLayoutController {
    public CudaCommunityThemeLayoutController() {

    }

    @AuraEnabled
    public static String getCommunityBaseUrl(){
        return URL.getSalesforceBaseUrl().toExternalForm();
    }
}