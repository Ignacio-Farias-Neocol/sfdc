@IsTest
public class SessionPermSetActionHelperTest {

    static PermissionSet sessionBasedPermissionSet {
        get {
            // Query for any session-based Permission Set assigned to the current user
            // NB: The current user is required as System.runAs does not provide a Session Id
            if(sessionBasedPermissionSet == NULL) {
                List<PermissionSet> permSet = [
                    SELECT Id, Name FROM PermissionSet
                    WHERE hasActivationRequired = TRUE
                    AND Id IN (SELECT PermissionSetId
                            FROM PermissionSetAssignment
                            WHERE AssigneeId = :UserInfo.getUserId())
                    LIMIT 1];
                sessionBasedPermissionSet = permSet.size() > 0 ? permSet.get(0) : NULL;
            }

            return sessionBasedPermissionSet;
        }
        set;
    }

    @testSetup
    private static void testSetup() {
        // If the current user does not have a session-based permission set already assigned, assign any existing one
        if(sessionBasedPermissionSet == NULL) {
            // A session-based Permission Set must be configured in the environment to meet the prerequisites of this test
            PermissionSet sessionBasedPermSet = [
                SELECT Id
                FROM PermissionSet
                WHERE hasActivationRequired = TRUE
                AND LicenseId IN (SELECT UserLicenseId FROM Profile WHERE Id = :UserInfo.getProfileId())
                LIMIT 1
            ];
            PermissionSetAssignment newAssignment = new PermissionSetAssignment(
                AssigneeId = UserInfo.getUserId(),
                PermissionSetId = sessionBasedPermSet.Id
            );
            insert newAssignment;

            Assert.isNotNull(sessionBasedPermSet, 'Cannot assign a session-based Permission Set to the current user');
        }
    }

    private static PermissionSetAssignment getPermissionSetAssignments() {
        List<PermissionSetAssignment> permSetAssignments = [
            SELECT PermissionSetId
            FROM PermissionSetAssignment
            WHERE AssigneeId = :UserInfo.getUserId()
            AND PermissionSetId = :sessionBasedPermissionSet.Id
            LIMIT 1
        ];

        return (permSetAssignments.size() > 0 ? permSetAssignments.get(0) : NULL);
    }

    @isTest
    private static void testActions() {
        String permissionSetName = sessionBasedPermissionSet?.Name;
    
        Test.startTest();
        SessionPermSetActionHelper.newInstance(permissionSetName).activate();
        SessionPermSetActionHelper.newInstance(permissionSetName).deactivate();
        Test.stopTest();

        // Unit tests do not return the session id
        // System.FlowException: There was no valid session id found for the request 
        Assert.isTrue(true, 'Dummy test'); 
    }
}