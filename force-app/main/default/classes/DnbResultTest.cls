@isTest
public  class DnbResultTest { 


    @testSetup
    private static void testSetup() {
      
    }

    @isTest
    private static void updateFromSearchResultsTest(){

        ExternalService.DnbSearch_searchCriteria_OUT_200_searchCandidates searchCandidate=
        new ExternalService.DnbSearch_searchCriteria_OUT_200_searchCandidates();

        ExternalService.DnbSearch_searchCriteria_OUT_200_searchCandidates_organization org=
        new  ExternalService.DnbSearch_searchCriteria_OUT_200_searchCandidates_organization();       

        org.domain='barracuda.com';

        searchCandidate.organization =org;

        DnbResult dnbRes=new DnbResult();

        Test.startTest();
        dnbRes.updateFromSearchResults(searchCandidate);
        Test.stopTest();

        System.assertEquals('barracuda.com', dnbRes.Website);
    }

    @isTest
    private static void updateFromDatablocksTest(){

        ExternalService.DnbSearch_searchCriteria_OUT_200_searchCandidates searchCandidate=
        new ExternalService.DnbSearch_searchCriteria_OUT_200_searchCandidates();

        ExternalService.DnbDataBlocks_dataBlocks_OUT_200_organization org=
        new  ExternalService.DnbDataBlocks_dataBlocks_OUT_200_organization();       

        ExternalService.DnbDataBlocks_dataBlocks_OUT_200_organization_numberOfEmployees noofEmp=
        new ExternalService.DnbDataBlocks_dataBlocks_OUT_200_organization_numberOfEmployees();
        noofEmp.value=100;

        org.numberOfEmployees = new List<ExternalService.DnbDataBlocks_dataBlocks_OUT_200_organization_numberOfEmployees> { noofEmp };
       
        ExternalService.DnbDataBlocks_dataBlocks_OUT_200_organization_primaryIndustryCode piCode=
        new ExternalService.DnbDataBlocks_dataBlocks_OUT_200_organization_primaryIndustryCode();
        piCode.usSicV4Description='Test Industry';
        org.primaryIndustryCode=piCode;

        DnbResult dnbRes=new DnbResult();

        Test.startTest();
        dnbRes.updateFromDatablocks(org);
        Test.stopTest();

        System.assertEquals('Test Industry', dnbRes.Industry);
    }

    @isTest
    private static void toAccountTest(){

        DnbResult dnb=new DnbResult();
        dnb.Name= 'Test';
        dnb.Website= 'Test Website';
        dnb.corporateLinkage= 'Test Description';
        dnb.DUNS_Number= '12345';       
        dnb.BillingCountry= 'Test Country';
        dnb.BillingState= 'Test State';
        dnb.BillingCity= 'Test City';
        dnb.BillingPostalCode= 'Test PostalCode';
        dnb.BillingStreet= 'Test Street';
        dnb.ConfidenceCode= 10;

        Test.startTest();
        Account acc= dnb.toAccount();
        Test.stopTest();

        System.assertEquals('Test', acc.Name);
        System.assertEquals('Test Website', acc.Website);
        System.assertEquals('Test Description', acc.Description);
        System.assertEquals('Test Country', acc.BillingCountry);
        System.assertEquals('Test State', acc.BillingState);
        System.assertEquals('Test City', acc.BillingCity);
        System.assertEquals('Test PostalCode', acc.BillingPostalCode);
        System.assertEquals(10, acc.DNBConnect__D_B_Match_Confidence_Code__c);
    }

    @isTest
    private static void DnbResultConstTest(){

        ExternalService.DnbMatch_identityResolution_OUT_200_matchCandidates matchCandidate=new ExternalService.DnbMatch_identityResolution_OUT_200_matchCandidates();

        ExternalService.DnbMatch_identityResolution_OUT_200_matchCandidates_organization org= new  ExternalService.DnbMatch_identityResolution_OUT_200_matchCandidates_organization();

        ExternalService.DnbMatch_identityResolution_OUT_200_matchCandidates_organization_primaryAddress addr=new ExternalService.DnbMatch_identityResolution_OUT_200_matchCandidates_organization_primaryAddress();
       

        ExternalService.DnbMatch_identityResolution_OUT_200_matchCandidates_organization_primaryAddress_addressCountry cont=new  ExternalService.DnbMatch_identityResolution_OUT_200_matchCandidates_organization_primaryAddress_addressCountry();
       
        ExternalService.DnbMatch_identityResolution_OUT_200_matchCandidates_organization_primaryAddress_addressLocality  loc= new ExternalService.DnbMatch_identityResolution_OUT_200_matchCandidates_organization_primaryAddress_addressLocality();

        ExternalService.DnbMatch_identityResolution_OUT_200_matchCandidates_organization_primaryAddress_addressRegion  reg= new ExternalService.DnbMatch_identityResolution_OUT_200_matchCandidates_organization_primaryAddress_addressRegion();
        
        ExternalService.DnbMatch_identityResolution_OUT_200_matchCandidates_organization_corporateLinkage link=new ExternalService.DnbMatch_identityResolution_OUT_200_matchCandidates_organization_corporateLinkage();

        ExternalService.DnbMatch_identityResolution_OUT_200_matchCandidates_organization_corporateLinkage_familytreeRolesPlayed fam=
        new  ExternalService.DnbMatch_identityResolution_OUT_200_matchCandidates_organization_corporateLinkage_familytreeRolesPlayed();

        ExternalService.DnbMatch_identityResolution_OUT_200_matchCandidates_organization_primaryAddress_streetAddress street=new ExternalService.DnbMatch_identityResolution_OUT_200_matchCandidates_organization_primaryAddress_streetAddress();
        ExternalService.DnbMatch_identityResolution_OUT_200_matchCandidates_organization_telephone phone= new ExternalService.DnbMatch_identityResolution_OUT_200_matchCandidates_organization_telephone();
        phone.telephoneNumber ='1234567890';

        org.telephone = new List<ExternalService.DnbMatch_identityResolution_OUT_200_matchCandidates_organization_telephone> {phone};
      
        fam.description='Family Desc'; 
        link.familytreeRolesPlayed    =  new List<ExternalService.DnbMatch_identityResolution_OUT_200_matchCandidates_organization_corporateLinkage_familytreeRolesPlayed> {fam};
        org.corporateLinkage=link;

        loc.Name='Test Locality';
        addr.addressLocality=loc;

        reg.Name='Test Region';
        addr.addressRegion=reg;

        cont.Name='Test Country';
        addr.addressCountry=cont;

        street.line1='Test Street';
        street.line2='Test Street';
        addr.streetAddress=street;

        addr.postalCode='12345';
       
        org.primaryAddress=addr;
        org.primaryName='Test Name';
        org.duns='12345';

        matchCandidate.organization=org;

        Test.startTest();
        DnbResult dnb= new DnbResult(matchCandidate);
        Test.stopTest();

        System.assertEquals('Test Name', dnb.Name);

    }

    @isTest
    private static void wrapResponseTest(){

        List<Sobject> dnbResultsList = new List<Sobject>();
        DnbResult dnb=new DnbResult();
        dnb.wrapResponse(dnbResultsList);
        dnb.getDestinationType();
        dnb.getSourceType();
    }
}