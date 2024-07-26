@RestResource(urlMapping='/searchBeforeCreate/*')
global class SearchBeforeCreateWebService {

    @TestVisible
    static Integer CONFIDENCE_THRESOLD = 9;

    @HttpPost
    global static Response createAccount() {
        try {
            RestRequest request = RestContext.request;
            String requestBody = request.requestBody.toString();
            System.debug('requestBody = ' + requestBody);

            Request sbcRequest = (Request)JSON.deserialize(requestBody, Request.class);
            if (sbcRequest.enrich == null) {
                sbcRequest.enrich = true;
            }
            if (sbcRequest.dryrun == null) {
                sbcRequest.dryrun = false;
            }

            List<DnbResult> matchedConfidenceAccts = new List<DnbResult>();
            Account enrichedAccount = sbcRequest.account;
            Account foundAccount;

            System.debug('sbcRequest.account = ' + sbcRequest.account);
            System.debug('sbcRequest.enrich = ' + sbcRequest.enrich);

            if (String.isBlank(sbcRequest.account.Name) || String.isBlank(sbcRequest.account.Type) ||
                String.isBlank(sbcRequest.account.BillingCountryCode)) {

                return new Response(false, null, new List<String>{'400 Bad Request: Name, Type or BillingCountryCode missing'});
            }

            // Enrichment with DUNS
            if (sbcRequest.enrich) {

                //enrichedAccount = DnbEnrichmentService.enrichWithDUNS(enrichedAccount);

                ExternalService.DnbMatch.identityResolution_Request dnbReq =
                    DnbEnrichmentService.mapAccountSearchCriteria(enrichedAccount);

                DnbEnrichmentService dnbSer = new DnbEnrichmentService();
                List<DnbResult> enrichedResults=dnbSer.getMatchResults(dnbReq); // What about multiple Dnb results returned

                if (enrichedResults!=null)   enrichedResults.sort(new DnbResultSorter()) ;

                System.debug('enrichedResults size = ' + enrichedResults.size());
                for (DnbResult dnb: enrichedResults) {
                    System.debug('dnb.name = ' + dnb.name + ' dnb.DUNS_Number = ' + dnb.DUNS_Number + ' dnb.ConfidenceCode = ' + dnb.ConfidenceCode);
                }

                for (DnbResult dnb: enrichedResults) {

                    if (dnb.ConfidenceCode >= CONFIDENCE_THRESOLD) {

                        matchedConfidenceAccts.add(dnb);
                        break;
                    }
                }

                if (matchedConfidenceAccts.size()==1) {

                    for (DnbResult mc: matchedConfidenceAccts) {
                        enrichedAccount.Name=mc.Name;
                        enrichedAccount.Website=mc.Website;
                        enrichedAccount.Description=mc.corporateLinkage;
                        enrichedAccount.D_B_DUNS_Number__c=mc.DUNS_Number;
                        enrichedAccount.DUNS_Number__c=mc.DUNS_Number;
                        enrichedAccount.BillingCountry=mc.BillingCountry;
                        enrichedAccount.BillingState=mc.BillingState;
                        enrichedAccount.BillingCity=mc.BillingCity;
                        enrichedAccount.BillingPostalCode=mc.BillingPostalCode;
                        enrichedAccount.BillingStreet=mc.BillingStreet;
                        enrichedAccount.DNBConnect__D_B_Match_Confidence_Code__c=mc.ConfidenceCode;
                    }
                    System.debug('Found one enrichedAccount = ' + enrichedAccount);
                } else {
                    System.debug('No enriched account found');
                }
            }

            List<Account> matchingAccounts = AccountSelector.findMatch(enrichedAccount);
            //High Confidence Match
            if(matchingAccounts.size() == 1) {
                Account matchedAccount = matchingAccounts[0];
                System.debug('matchedAccount found = ' + matchedAccount);
                System.debug('matchedAccount.Type = ' + matchedAccount.Type);
                System.debug('enrichedAccount.Type = ' + enrichedAccount.Type);

                if(matchedAccount.Type == enrichedAccount.Type) {
                    return new Response(true, matchedAccount.Id, new List<String>{'200 Success'});
                }else {
                    Account reparentedAccount = AccountService.reparentAccounts(enrichedAccount, matchedAccount);
                    return new Response(true, reparentedAccount.Id, new String[]{});
                }

            } else if(matchingAccounts.size() == 0) {
                System.debug('No matching account found, inserting new account');
                if (!sbcRequest.dryrun) {
                    insert sbcRequest.account;
                }
                return new Response(true, sbcRequest.account.Id, new String[]{});
            } else {
                // Multiple matching accounts found - return error
                return new Response(false, null, new String[]{'Multiple matching accounts found'});
            }
        }catch(Exception e) {
            System.debug('Exception type caught: ' + e.getTypeName());
            System.debug('Message: ' + e.getMessage());
            System.debug('Line number: ' + e.getLineNumber());
            System.debug('Stack trace: ' + e.getStackTraceString());
            throw new SearchBeforeCreateException('Error occurred: ' + e.getMessage());
        }

        //return AccountService.findMatch(requestBody);
    }

    private static Id safeInsert(Account acc) {
        Database.SaveResult result = Database.insert(acc, true);
        if(result.isSuccess()) {
            return result.Id;
        } else {
            String errMsg = '';
            for (Database.Error err : result.getErrors()) {
                errMsg += err.getMessage() + '; ';
            }
            throw new SearchBeforeCreateException('Insert failed: ' + errMsg);
        }
    }
    // Inner class for request deserialization
    global class Request {
        public Account account {get; set;}
        public Boolean dryrun {get; set;}
        public Boolean enrich {get; set;}

        public Request() {
            // set default values for flags
            this.dryrun = false;
            this.enrich = true;
        }
    }

    // Inner class for response
    global class Response {
        public Boolean success {get; set;}
        public Id id {get; set;}
        public List<String> errors {get; set;}

        public Response(Boolean success, Id id, List<String> errors) {
            this.success = success;
            this.id = id;
            this.errors = errors;
        }

        // public Response(Id id) {
        //     this.success = true;
        //     this.id = id;
        //     this.errors = new List<String>();
        // }

        // public Response(System.Exception e) {
        //     this.success = false;
        //     this.id = null;
        //     this.errors = new List<String>{e.getMessage()};
        // }

        // public Response(String errorMessage) {
        //     this.success = false;
        //     this.id = null;
        //     this.errors = new List<String>{errorMessage};
        // }
    }

    public class SearchBeforeCreateException extends Exception {}
}