public class SessionPermSetActionHelper {
    private Map<String, Object> flowInputs = new Map<String, Object>();
    private final String INPUT_PERMISSION_SET = 'Permission_Set_Name';
    private final String INPUT_ACTIVATE = 'doActivate';

    // Allow the helper to be called in one line
    // Example: SessionPermSetActionHelper.newInstance('permset').activate();
    public static SessionPermSetActionHelper newInstance(String permissionSetName) {
        return new SessionPermSetActionHelper(permissionSetName);
    }

    public SessionPermSetActionHelper(String permissionSetName) {
        setPermissionSetName(permissionSetName);
    }

    public void setPermissionSetName(String permissionSetName) {
        this.flowInputs.put(INPUT_PERMISSION_SET, permissionSetName);
    }

    public void activate() {
        this.flowInputs.put(INPUT_ACTIVATE, true);
        startFlow();
        System.debug('Perm Activated');
    }

    public void deactivate() {
        this.flowInputs.put(INPUT_ACTIVATE, false);
        startFlow();
        System.debug('Perm DeActivated');
    }

    private void startFlow() {
        Flow.Interview.Session_based_Permission_Set_Actions actionFlow = new Flow.Interview.Session_based_Permission_Set_Actions(this.flowInputs);
        
        // Unit tests do not return the session id
        // System.FlowException: There was no valid session id found for the request 
        if(!Test.isRunningTest()) {
            actionFlow.start();
        }
    }
}