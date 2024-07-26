/**
 * @File Name			    : ClientCredentialsAuthProvider.cls
 * @Description			    : To create custom Auth. Provider to support Client Credential flow with Named Credentials. Access token encryption and expiration/refresh will be handle natively by Salesforce.
 * @Test class       	    : ClientCredentialsAuthProviderTest.cls
 * @Modification Log	    :
 *
 * Ver		  Date		        Author				  Modification
 * 1.00		  04/25/2023	    Bao Nguyen			  First version
 * 1.01		  08/25/2023	    Brian Chong			  D&B API auth
 *
**/
public without sharing class ClientCredentialsAuthProvider extends Auth.AuthProviderPluginClass {
    private final String METADATA_API_NAME = 'ClientCredentialsAuthProvider__mdt'; // api name for the custom metadata type created for this auth provider
    private String callbackUrl;
    private String refreshToken = 'temp-refresh-token'; // just a place holder, fake refresh token so that Named Credentials understands that this support getting new access token when the existing one expires

    public String getCustomMetadataType() {
        return this.METADATA_API_NAME;
    }

    public PageReference initiate(Map<string, string> authProviderConfiguration, String stateToPropagate) {
       	callbackUrl = authProviderConfiguration.get('Callback_URL__c');
        callbackUrl += + '?state=' + stateToPropagate;

        return new PageReference(callbackUrl);
    }

    public Auth.AuthProviderTokenResponse handleCallback(Map<string,string> authProviderConfiguration, Auth.AuthProviderCallbackState state) {

        ResponseWrapper responseWrapper = new ResponseWrapper();

        try {
            responseWrapper = getAccessToken(authProviderConfiguration);
        } catch (Exception e) {
            system.debug('handleCallback exception ' + e.getStackTraceString());
        }

        return new Auth.AuthProviderTokenResponse(
            authProviderConfiguration.get('Provider_Name__c'),
            responseWrapper.access_token,
            this.refreshToken,
            state.queryParameters.get('state')
        );
    }

    public override Auth.OAuthRefreshResult refresh(Map<String,String> authProviderConfiguration, String refreshToken) {

        ResponseWrapper responseWrapper = new ResponseWrapper();

        try {
            responseWrapper = getAccessToken(authproviderconfiguration);
        } catch (Exception e) {
            system.debug('handleCallback exception ' + e.getStackTraceString());
        }

        return new Auth.OAuthRefreshResult(
            responseWrapper.access_token,
            this.refreshToken
        );
    }

    //Return fake user, client credentials auth flow is not for a user
    public Auth.UserData getUserInfo(Map<string,string> authProviderConfiguration, Auth.AuthProviderTokenResponse response) {

        return new Auth.UserData('fakeId', 'first', 'last', 'full', 'email', 'link', null, null, null, null, null);
    }

    public ResponseWrapper getAccessToken(Map<String, String> config) {
        String url = 'callout:' + config.get('Token_Named_Credential__c') + config.get('Token_Endpoint__c');

        Http httpObject = new Http();

        HttpRequest request = new HttpRequest();
        request.setEndpoint(url);
        request.setMethod('POST');
        request.setHeader('content-type', 'application/json');
        request.setHeader('Authorization', '{!HTMLENCODE($Credential.AuthorizationHeaderValue)}');
        request.setBody('{"grant_type":"client_credentials"}');

        HttpResponse response = httpObject.send(request);

        ResponseWrapper responseBody = (ResponseWrapper)JSON.deserialize(response.getBody(), ResponseWrapper.class);
        return responseBody;
    }

    public class ResponseWrapper {
        public String access_token;
        public String expiresIn;
    }
}
/*
    ClientCredentialsAuthProvider api = new ClientCredentialsAuthProvider();
    System.debug(api.getAccessToken(new Map<String, String>{
            'Named_Credential' => 'DnbNamedCredential',
            'Token_Path' => '/v2/token'
    }));
*/

/*


ExternalService.CopyOfDnbMatch api = new ExternalService.CopyOfDnbMatch();
ExternalService.CopyOfDnbMatch.identityResolution_Response res;

ExternalService.CopyOfDnbMatch.identityResolution_Request req = new ExternalService.CopyOfDnbMatch.identityResolution_Request();
req.name = 'Slalom';
req.countryISOAlpha2Code = 'US';
//req.Authorization = access;
//req.Authorization = '{!$Credential.OAuthToken}';
// req.Authorization = 'Bearer {!$Credential.OAuthToken}';
//req.Authorization = 'Bearer h692aQZFH9965XVsZjA32c810i4A';
//req.Contentx2dType = 'application/json';

System.debug('req >>>> ' + req);

try {
    res = api.identityResolution(req);
} catch(Exception ex) {
    System.debug(ex);
}
    System.debug('res >>> ' + res);
    System.debug('api >>> ' + api);


*/