@isTest
private class ClientCredentialsAuthProviderTest {

    private static final String OAUTH_TOKEN = 'testToken';
    private static final String STATE = 'mocktestState';
    private static final String STATE_TO_PROPOGATE = 'testState';
    private static final String REFRESH_TOKEN = 'temp-refresh-token';
    private static final String CALLBACK_URL = 'http://localhost/services/authcallback/ClientCredentialsAuthProvider';
    private static final String PROVIDER_NAME = 'ClientCredentialsAuthProvider';
    private static final String TOKEN_ENDPOINT = '/v2/token';
    private static final String TOKEN_NAMED_CREDENTIAL = 'DNB_Token_Request';

    private static Map<String,String> setupAuthProviderConfig()
    {
        Map<String,String> authProviderConfiguration = new Map<String, String>();
        authProviderConfiguration.put('Callback_URL__c', CALLBACK_URL);
        authProviderConfiguration.put('Provider_Name__c', PROVIDER_NAME);
        authProviderConfiguration.put('Token_Endpoint__c', TOKEN_ENDPOINT);
        authProviderConfiguration.put('Token_Named_Credential__c', TOKEN_NAMED_CREDENTIAL);
        return authProviderConfiguration;
    }

    @isTest
    static void testInitiateMethod() {
        Map<String,String> authProviderConfiguration = setupAuthProviderConfig();
        ClientCredentialsAuthProvider authProvider = new ClientCredentialsAuthProvider();

        PageReference expectedPageRef = new PageReference(authProviderConfiguration.get('Callback_URL__c') +
        '?state=' + STATE_TO_PROPOGATE);

        PageReference actualPageRef = authProvider.initiate(authProviderConfiguration, STATE_TO_PROPOGATE);

        Assert.areEqual(expectedPageRef.getUrl(), actualPageRef.getUrl());
    }

    @isTest
    static void testHandleCallback() {
        Map<String,String> authProviderConfiguration = setupAuthProviderConfig();
        ClientCredentialsAuthProvider authProvider = new ClientCredentialsAuthProvider();

        Test.setMock(HttpCalloutMock.class, new MockHttp_ResponseWrapper());

        Map<String,String> queryParams = new Map<String,String>();
        queryParams.put('state', STATE);

        Auth.AuthProviderCallbackState cbState =
            new Auth.AuthProviderCallbackState(null,null,queryParams);

        Auth.AuthProviderTokenResponse actualAuthProvResponse =
            authProvider.handleCallback(authProviderConfiguration, cbState);

        Auth.AuthProviderTokenResponse expectedAuthProvResponse =
            new Auth.AuthProviderTokenResponse('ClientCredentialsAuthProvider', OAUTH_TOKEN, REFRESH_TOKEN, STATE);

        Assert.areEqual(expectedAuthProvResponse.provider, actualAuthProvResponse.provider);

        Assert.areEqual(expectedAuthProvResponse.oauthToken, actualAuthProvResponse.oauthToken);

        Assert.areEqual(expectedAuthProvResponse.oauthSecretOrRefreshToken,
                        actualAuthProvResponse.oauthSecretOrRefreshToken);

        Assert.areEqual(expectedAuthProvResponse.state, actualAuthProvResponse.state);
    }

    @isTest
    static void testRefresh() {
        Map<String,String> authProviderConfiguration = setupAuthProviderConfig();
        ClientCredentialsAuthProvider authProvider = new ClientCredentialsAuthProvider();

        Test.setMock(HttpCalloutMock.class, new MockHttp_ResponseWrapper());

        Auth.OAuthRefreshResult actualAuthProvResponse = authProvider.refresh(authProviderConfiguration, null);

        Auth.OAuthRefreshResult expectedAuthProvResponse = new Auth.OAuthRefreshResult(OAUTH_TOKEN, 'Bearer');

        Assert.areEqual(expectedAuthProvResponse.accessToken, actualAuthProvResponse.accessToken);
    }

    @isTest
    static void testGetUserInfo() {
        Map<String,String> authProviderConfiguration = setupAuthProviderConfig();
        ClientCredentialsAuthProvider authProvider = new ClientCredentialsAuthProvider();

        Test.setMock(HttpCalloutMock.class, new MockHttp_ResponseWrapper());

        Auth.UserData actualAuthProvResponse = authProvider.getUserInfo(authProviderConfiguration, null);

        Auth.UserData expectedAuthProvResponse =
            new Auth.UserData('fakeId', 'first', 'last', 'full', 'email', 'link', null, null, null, null, null);

        Assert.areEqual(expectedAuthProvResponse.identifier, actualAuthProvResponse.identifier);
    }

    @isTest
    static void testGetCustomMetadataType() {
        ClientCredentialsAuthProvider authProvider = new ClientCredentialsAuthProvider();

        String actualAuthProvResponse = authProvider.getCustomMetadataType();

        Assert.areEqual('ClientCredentialsAuthProvider__mdt', actualAuthProvResponse);
    }

    public class MockHttp_ResponseWrapper implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            String s=
            '{' +
            '   "access_token": "testToken",'+
            '   "expires_in": "1799" '+
            '}';

            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody(s);
            res.setStatusCode(200);
            return res;
        }
    }
}