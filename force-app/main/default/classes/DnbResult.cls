public class DnbResult implements IEnrichmentResult {
    public String Name { get; set; }
    public String Website { get; set; }
    public String Description { get; set; }
    public String corporateLinkage { get; set; }
    public String DUNS_Number { get; set; }
    public String BillingCountry { get; set; }
    public String BillingCountryCode { get; set; }
    public String BillingCity { get; set; }
    public String BillingState { get; set; }
    public String BillingStateCode { get; set; }
    public String BillingPostalCode { get; set; }
    public String BillingStreet { get; set; }
    public Integer NumberofEmployees { get; set; }
    public String Industry { get; set; }
    public Integer ConfidenceCode { get; set; }
    public String Phone { get; set; }
    public Boolean result { get; set; }
    public String message { get; set; }
    public List<DnbResult> retList{get;set;}
    
    public DnbResult(){}

    public DnbResult(ExternalService.DnbMatch_identityResolution_OUT_200_matchCandidates matchCandidate) {
        ExternalService.DnbMatch_identityResolution_OUT_200_matchCandidates_organization organization = matchCandidate?.organization;
        this.name = organization.primaryName;
        this.DUNS_Number = organization.duns;
        this.ConfidenceCode = matchCandidate.matchQualityInformation?.confidenceCode;

        if(organization.corporateLinkage.familytreeRolesPlayed != NULL &&
            organization.corporateLinkage.familytreeRolesPlayed.size() > 0
        ) {
            this.corporateLinkage = organization.corporateLinkage.familytreeRolesPlayed[0].description;
        }

        if(organization.telephone.size() > 0) {
            this.Phone = organization.telephone[0].telephoneNumber;
        }

        if(organization.websiteAddress != NULL && organization.websiteAddress.size() > 0) {
            this.Website = organization.websiteAddress[0].url;
        }

        if(organization.primaryAddress != NULL) {
            this.BillingCountry = organization.primaryAddress.addressCountry.name;
            this.BillingCity = organization.primaryAddress.addressLocality.name;
            this.BillingState = organization.primaryAddress.addressRegion.name;
            this.BillingPostalCode = organization.primaryAddress.postalCode;

            this.BillingStreet = organization.primaryAddress.streetAddress.line1;
            if(!String.isBlank(organization.primaryAddress.streetAddress.line2)) {
                this.BillingStreet += ' ' + organization.primaryAddress.streetAddress.line2;
            }
        }
    }

    public void updateFromSearchResults(ExternalService.DnbSearch_searchCriteria_OUT_200_searchCandidates searchCandidate) {
        ExternalService.DnbSearch_searchCriteria_OUT_200_searchCandidates_organization organization = searchCandidate?.organization;

        if(this.Website == NULL) {
            this.Website = organization.domain;
        }
    }

    public void updateFromDatablocks(ExternalService.DnbDataBlocks_dataBlocks_OUT_200_organization organization) {
        if(organization.numberOfEmployees != NULL && organization.numberOfEmployees.size() > 0) {
            this.NumberofEmployees = organization.numberOfEmployees[0].value;
        }
        this.Industry = organization.primaryIndustryCode.usSicV4Description;
    }

    public Account toAccount() {
        Account accountRecord = new Account();
        accountRecord.Name = this.Name;
        accountRecord.Website = this.Website;
        accountRecord.Description = this.corporateLinkage;
        accountRecord.D_B_DUNS_Number__c = this.DUNS_Number;
        accountRecord.DUNS_Number__c = this.DUNS_Number;
        accountRecord.BillingCountry = this.BillingCountry;
        accountRecord.BillingState = this.BillingState;
        accountRecord.BillingCity = this.BillingCity;
        accountRecord.BillingPostalCode = this.BillingPostalCode;
        accountRecord.BillingStreet = this.BillingStreet;
        accountRecord.DNBConnect__D_B_Match_Confidence_Code__c = this.ConfidenceCode;

        return accountRecord;
    }

    public Type getSourceType (){
        return null;
    }

    public Type getDestinationType(){
        return null;
    }

    public  List<IEnrichmentResult> wrapResponse(List<Sobject> dnbRes){
        List<DnbResult> dnbResultsList = new List<DnbResult>();
        return dnbResultsList;
    }
}