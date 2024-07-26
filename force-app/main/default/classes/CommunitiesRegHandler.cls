//This class includes the basics for a Registration Handler class.

global class CommunitiesRegHandler {

    @InvocableMethod(label='Register Community User')
    global static List<CommunitiesRegHelper.UserData> registerUser(List<Contact> contacts) {
        return CommunitiesRegHelper.createUser(contacts);
    } 
}