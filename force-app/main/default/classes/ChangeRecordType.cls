/** 
* Invocable apex class used to update Record Type ID from Process Builder
* 
* @Author Micah Gerger
* @Date 2018/11/01
* @Group Classes
*
*/
 
public class ChangeRecordType {

	//Variable for returned Record Type ID    
	Private static final String Record_Type_Id = 'recordTypeId';

    //Enable this method to be called by Process Builder
    @InvocableMethod(
        label = 'Change Object Record Type'
        description = 'Change Record Type by Developer Name'
    )
    
    /***********************************************************************
    * @description Method for gathering inputs from Process Builder
    * 
    * @param Requests
    * @return Responses
    */
    public static List<Response> execute(List<Request> requests) {

        List<Response> responses = new List<Response>();

        for (Request request : requests) {
            responses.add(updateRecordType(request));
        }

        return responses;
    }

 /***********************************************************************
    * @description Method for updating record type based on developer name
    * 
    * @param Request
    * @return Response
    */    
    private static Response updateRecordType(Request request) {
        Response response = new Response();
        try {

            Id recordTypeId = getRecordTypeId(request.objectName, request.developerName);

            if (recordTypeId == null){
                throw new NoRecordTypeFoundException(request);
            }

            String queryString = getQueryString(request.objectName, request.recordId);

            List<sObject> results = Database.query(queryString);

            if (results.size() == 0) {
                throw new NoRecordFoundException(request);
            }

            SObject record = results[0];
            record.put(RECORD_TYPE_ID, recordTypeId);
            DML.save(record);

            response.success = true;
        } 
        catch (Exception ex) {
            response.errorMesssage = ex.getMessage();
            response.success = false;   
        }

        return response;
    }
 	/***********************************************************************
    * @description Method for establishing query based on Object named in Process Builder
    * 
    * @param String - Object name and record ID
    * @return Query string 
    */
    private static String getQueryString(String objectName, String recordId) {
        List<String> args = new String[]{objectName, recordId};
            return String.format('SELECT Id FROM {0} WHERE Id = \'\'{1}\'\'', args);
    }

    /***********************************************************************
    * @description Method for getting Record Type Id from Object using Developer name
    * 
    * @param String - Object name and Developer Name of Record Type
    * @return Id 
    */
    private static Id getRecordTypeId(String objectName, String developerName){
        return Schema.getGlobalDescribe().get(objectName).getDescribe().getRecordTypeInfosByDeveloperName().get(developerName).getRecordTypeId();
    }

	///Establish Variables that will be passed in by Process Builder
    public class Request {

        @InvocableVariable(
            label = 'Record ID'
            description = 'The ID of the record to have its record type changed'
            required = true
        )
        public Id recordId;

        @InvocableVariable(
            label = 'Object Name'
            description = 'The Name of the Object which will have its record type changed'
            required = true
        )
        public String objectName;

        @InvocableVariable(
            label = 'Record Type Developer Name'
            description = 'The Developer Name of the Record Type to change the object to'
            required = true
        )
        public String developerName;

    }

    //Establish response for error handling
    public class Response {

        @InvocableVariable(
            label = 'Error Message'
            description = 'The message of the error'
        )
        public String errorMesssage;

        @InvocableVariable(
            label = 'Is Success'
            description = 'Successfully changed'
        )
        public Boolean success;
    }

    //Handle potential negative scenario -- no matching record type
    private class NoRecordTypeFoundException extends Exception {
        Private Request request;
        public NoRecordTypeFoundException(Request request){
            this.request = request;
        }
        public override String getMessage() {
            List<String> args = new String[]{request.objectName, request.developerName};
            return String.format('No Record Type ID found on object: {0} with Record Type Developer Name: {1}', args);  
        } 
    }
	
    //Handle potential scenario for bad record Id
    private class NoRecordFoundException extends Exception {     
        Private Request request;
        public NoRecordFoundException(Request request){
            this.request = request;
        }
        public override String getMessage() {
            List<String> args = new String[]{request.objectName, request.recordId};
            return String.format('No Record found for object: {0} with Record ID: {1}', args); 
        } 
    }
}