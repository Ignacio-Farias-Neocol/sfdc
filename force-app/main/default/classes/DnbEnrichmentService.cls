public  class DnbEnrichmentService implements IEnrichmentService { 

    public static HttpCalloutMock httpMock = null;

    public static ExternalService.DnbMatch.identityResolution_Request   mapAccountSearchCriteria ( Account acc){


    Map<String, Object> fieldsToValue = acc.getPopulatedFieldsAsMap();

    return mapSearchCriteria(fieldsToValue);


    }

    public  List<DnbResult> getMatchResults( ExternalService.DnbMatch.identityResolution_Request dnbRequest) {

    DnbResult dres;
    DnbEnrichmentService.DnBAPIResult dnbapiRes=new DnbEnrichmentService.DnBAPIResult();
    List<DnbResult> enrichResults=new List<DnbResult>();
    Map<string,DnbResult> enrichMap=new Map<string,DnbResult> ();

    ExternalService.DnbMatch matchApiClient = new ExternalService.DnbMatch();
    ExternalService.DnbMatch.identityResolution_Response dnbRes;
    ExternalService.DnbMatch.identityResolution_Request req;
    List<String> dList=new List<String>();
    List<ExternalService.DnbSearch_searchCriteria_OUT_200_searchCandidates>  searchRes;

    try {
   
    dnbRes = matchApiClient.identityResolution(dnbRequest);   

    dnbapiRes.dnbApiResult=dnbRes.responseCode == 200 ? true : false;

    System.debug('responseCode:: '+ dnbRes.responseCode);

    if(dnbapiRes.dnbApiResult ) {

    List<ExternalService.DnbMatch_identityResolution_OUT_200_matchCandidates> matchCandidates = dnbRes.Code200.matchCandidates;

    if(matchCandidates.size()> 0){

    // get Results from DnBSearch

    for (ExternalService.DnbMatch_identityResolution_OUT_200_matchCandidates mc: matchCandidates){

    dList.add(mc.organization.duns);

    }

    if(dList.size()>0){

    searchRes= getSearchData(dList);
    }


    // get Results from DnBSearch

    for (ExternalService.DnbMatch_identityResolution_OUT_200_matchCandidates mc: matchCandidates){

    dres= new DnbResult();
    dres.name=mc.organization?.primaryName;
    dres.DUNS_Number=mc.organization?.duns;
    dres.ConfidenceCode=mc.matchQualityInformation?.confidenceCode;
    dres.corporateLinkage=mc.organization?.corporateLinkage.familytreeRolesPlayed!=null?
    (mc.organization.corporateLinkage.familytreeRolesPlayed.size()>0?mc.organization.corporateLinkage.familytreeRolesPlayed[0].description:'') : '';
    dres.Phone =mc.organization.telephone.size()>0? mc.organization.telephone[0].telephoneNumber : '';

    if(searchRes.size()>0 ){

    for(ExternalService.DnbSearch_searchCriteria_OUT_200_searchCandidates sc: searchRes) {

    if (sc.organization?.duns ==mc.organization?.duns) {

    dres.Website=sc.organization?.domain;
    dres.BillingCountryCode=sc.organization?.primaryAddress?.addressCountry?.isoAlpha2Code;
    dres.BillingCountry=sc.organization?.primaryAddress?.addressCountry?.Name;
    dres.BillingCity=sc.organization?.primaryAddress?.addressLocality?.Name;
    dres.BillingState=sc.organization?.primaryAddress?.addressRegion?.Name;
    dres.BillingStateCode=sc.organization?.primaryAddress?.addressRegion?.abbreviatedName;
    dres.BillingStreet=sc.organization?.primaryAddress?.streetAddress?.line1 ;
    // sc.organization?.primaryAddress?.streetAddress?.line2; // Returning Null Every Time
    dres.BillingPostalCode=sc.organization?.primaryAddress?.postalCode;
    }
    }
    }

    enrichMap.put(dres.DUNS_Number,dres);
    }
    }
    }
    else {
    dnbapiRes.dnbApiResult=false;
    dnbapiRes.dnbApiMessage='DnB API did not fetch any Results';
    throw new DnBAPIException(dnbapiRes.dnbApiMessage);
    }

    } catch(Exception ex) {

    dnbapiRes.dnbApiResult=false;
    dnbapiRes.dnbApiMessage='No Match found for the given input criteria';    // Need to check identityResolution_ResponseException handling
    }
    System.debug('enrichMap Keys:: ' + enrichMap.keyset());
    return enrichMap.values();

    }

    public static List<DnbResult> getMatchResults(Map<String, Object> mapSearchCrit) {

        DnbResult dres;
        DnbEnrichmentService.DnBAPIResult dnbapiRes=new DnbEnrichmentService.DnBAPIResult();
        List<DnbResult> enrichResults=new List<DnbResult>();
        Map<string,DnbResult> enrichMap=new Map<string,DnbResult> ();

        ExternalService.DnbMatch matchApiClient = new ExternalService.DnbMatch();
        ExternalService.DnbMatch.identityResolution_Response dnbRes;
        ExternalService.DnbMatch.identityResolution_Request req;
        List<String> dList=new List<String>();
        List<ExternalService.DnbSearch_searchCriteria_OUT_200_searchCandidates>  searchRes;

        try {

            req= mapSearchCriteria(mapSearchCrit);

                dnbRes = matchApiClient.identityResolution(req);

                dnbapiRes.dnbApiResult=dnbRes.responseCode == 200 ? true : false;

                System.debug('responseCode:: '+ dnbRes.responseCode);

                if(dnbapiRes.dnbApiResult) {

                    List<ExternalService.DnbMatch_identityResolution_OUT_200_matchCandidates> matchCandidates = dnbRes.Code200.matchCandidates;

                    if(matchCandidates.size()> 0){

                        // get Results from DnBSearch

                        for (ExternalService.DnbMatch_identityResolution_OUT_200_matchCandidates mc: matchCandidates){

                            dList.add(mc.organization.duns);

                        }

                        if(dList.size()>0){

                            searchRes= getSearchData(dList);
                        }


                        // get Results from DnBSearch

                        for (ExternalService.DnbMatch_identityResolution_OUT_200_matchCandidates mc: matchCandidates){

                            dres= new DnbResult();
                            dres.name=mc.organization?.primaryName;
                            dres.DUNS_Number=mc.organization?.duns;
                            dres.ConfidenceCode=mc.matchQualityInformation?.confidenceCode;
                            dres.corporateLinkage=mc.organization?.corporateLinkage.familytreeRolesPlayed!=null?
                            (mc.organization.corporateLinkage.familytreeRolesPlayed.size()>0?mc.organization.corporateLinkage.familytreeRolesPlayed[0].description:'') : '';
                            dres.Phone =mc.organization.telephone.size()>0? mc.organization.telephone[0].telephoneNumber : '';

                            if(searchRes.size()>0 ){

                                for(ExternalService.DnbSearch_searchCriteria_OUT_200_searchCandidates sc: searchRes) {

                                    if (sc.organization?.duns ==mc.organization?.duns) {

                                        dres.Website=sc.organization?.domain;
                                        dres.BillingCountryCode=sc.organization?.primaryAddress?.addressCountry?.isoAlpha2Code;
                                        dres.BillingCountry=sc.organization?.primaryAddress?.addressCountry?.Name;
                                        dres.BillingCity=sc.organization?.primaryAddress?.addressLocality?.Name;
                                        dres.BillingState=sc.organization?.primaryAddress?.addressRegion?.Name;
                                        dres.BillingStateCode=sc.organization?.primaryAddress?.addressRegion?.abbreviatedName;
                                        dres.BillingStreet=sc.organization?.primaryAddress?.streetAddress?.line1 ;
                                        // sc.organization?.primaryAddress?.streetAddress?.line2; // Returning Null Every Time
                                        dres.BillingPostalCode=sc.organization?.primaryAddress?.postalCode;
                                    }
                                }
                            }
                            enrichMap.put(dres.DUNS_Number,dres);
                        }
                    }
                }
                else {
                    dnbapiRes.dnbApiResult=false;
                    dnbapiRes.dnbApiMessage='DnB API did not fetch any Results';
                    throw new DnBAPIException(dnbapiRes.dnbApiMessage);
                }
          
        } catch(Exception ex) {

            dnbapiRes.dnbApiResult=false;
            dnbapiRes.dnbApiMessage='No Match found for the given input criteria';    // Need to check identityResolution_ResponseException handling
        }
        System.debug('enrichMap Keys:: ' + enrichMap.keyset());
        return enrichMap.values();

    }

    public static ExternalService.DnbMatch.identityResolution_Request  mapSearchCriteria(Map<String,Object> mapSearchCrit){

    ExternalService.DnbMatch.identityResolution_Request dnbreq = new ExternalService.DnbMatch.identityResolution_Request();

    string duns = String.valueOf(mapSearchCrit.get('D_B_DUNS_Number__c'))!=null ? String.valueOf(mapSearchCrit.get('D_B_DUNS_Number__c')) :'';
    //string name = String.valueOf(mapSearchCrit.get('Company'));
    string name = String.valueOf(mapSearchCrit.get('Company'))!=null ? String.valueOf(mapSearchCrit.get('Company')) : (String.valueOf(mapSearchCrit.get('Name'))!=null  ? String.valueOf(mapSearchCrit.get('Name')) : '');
    System.debug('Country::' + String.valueOf(mapSearchCrit.get('Country')));
    System.debug('CountryCode::' + String.valueOf(mapSearchCrit.get('CountryCode')));
    System.debug('BillingCountryCode::' + String.valueOf(mapSearchCrit.get('BillingCountryCode')));
   // string countrycode = String.valueOf(mapSearchCrit.get('CountryCode'))!=null ? String.valueOf(mapSearchCrit.get('CountryCode')) :'';
   string countrycode = String.valueOf(mapSearchCrit.get('CountryCode'))!=null ? String.valueOf(mapSearchCrit.get('CountryCode')) :(String.valueOf(mapSearchCrit.get('BillingCountryCode'))!=null ? String.valueOf(mapSearchCrit.get('BillingCountryCode')) : '');
    if(String.isNotBlank( duns)){
    dnbreq.duns=duns;
    dnbreq.name='';

    }
    else {
    dnbreq.name=name;
    dnbreq.duns='';
    }

    dnbreq.countryISOAlpha2Code = countrycode;
    dnbreq.candidateMaximumQuantity = 10;
    dnbreq.confidenceLowerLevelThresholdValue = 6;
    dnbreq.isCleanseAndStandardizeInformationRequired = true;
    dnbreq.Authorization_set = true;
    System.debug('mapSearchCriteria dnbreq = ' + dnbreq);
    return dnbreq;

    }

    public static List<ExternalService.DnbSearch_searchCriteria_OUT_200_searchCandidates>  getSearchData(List<String> dunsList){

        ExternalService.DnbSearch searchApi = new ExternalService.DnbSearch();
        ExternalService.DnbSearch.searchCriteria_Request seacrhReq = new ExternalService.DnbSearch.searchCriteria_Request();
        ExternalService.DnbSearch.searchCriteria_Response searchRes;
        ExternalService.DnbSearch_searchCriteria_IN_body reqBody=new ExternalService.DnbSearch_searchCriteria_IN_body();
        List<ExternalService.DnbSearch_searchCriteria_OUT_200_searchCandidates> searchCandidates;

        try {

        seacrhReq.Contentx2dType='application/json';
        reqBody.dunsList =dunsList;
        seacrhReq.body=reqBody;

        System.debug('req::' + seacrhReq);        

        searchRes = searchApi.searchCriteria(seacrhReq);

        if(searchRes.responseCode==200){

        searchCandidates = searchRes.Code200.searchCandidates;

        }
     
        } catch(Exception ex) {

        System.debug(ex);
        }

        return searchCandidates;
    }

    public static DnbResult  getDnBDataBlocksInfo(String duns){

        ExternalService.DnbDataBlocks datablockApi = new ExternalService.DnbDataBlocks();
        ExternalService.DnbDataBlocks.dataBlocks_Request datablockReq = new ExternalService.DnbDataBlocks.dataBlocks_Request();
        ExternalService.DnbDataBlocks.dataBlocks_Response datablockRes;
        Map<string,List<String>> dataBlockMapRes=new  Map<string,List<String>>();
        DnbResult dnbRes= new DnbResult();

        try {

        datablockReq.Authorization_set = true; // Disable the Authorization header requirement as Named Credentials will automatically set
        datablockReq.blockIds = 'companyinfo_L2_v1,hierarchyconnections_L1_v1';
        datablockReq.dunsNumber = duns;
        datablockRes = datablockApi.dataBlocks(datablockReq);

        if(datablockRes!=null){

            dnbRes.NumberofEmployees= datablockRes.Code200.organization.numberOfEmployees.size()>0? datablockRes.Code200.organization.numberOfEmployees[0].value : -1;
            dnbRes.Industry =datablockRes.Code200.organization.primaryIndustryCode.usSicV4Description;
            }
       
        }   catch(Exception ex) {
             System.debug(ex);

        //   log.addExceptionLog(ex);

        }

        return  dnbRes ;
    }

    public class DnBAPIResult {

    public Boolean dnbApiResult;

    public String dnbApiMessage;
    }
    public class DnBAPIException extends Exception {}

    }