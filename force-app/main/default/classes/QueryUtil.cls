/*	
 * Author: Bhavesh Jha
 * Description: To quering all fields from the object.
 * Returns a whole fields included String.
*/
public class QueryUtil {

	/*******************************************************************************************************
     * Description: get all additional field from Relational Parent Object.
     * @param Parent SObject API Name
     * @param Relation Name
    *******************************************************************************************************/
    public static String getWholeParentAdditionalFields(String parentSObjectAPI,String relationName){
        String queryParentFields = '';
        Map<String, Schema.SObjectField> objectFields = Schema.getGlobalDescribe().get(parentSObjectAPI).getDescribe().fields.getMap();
        
        //   Grab the fields from the describe method and append them to the queryString one by one.
        for(String s : objectFields.keySet()) {
            if(queryParentFields==''){
                queryParentFields += ' '+relationName+'.'+s;
            }else{
                queryParentFields += ', '+relationName+'.'+ s ;
            }
        }
        return queryParentFields;
    }

    /*******************************************************************************************************
     * Description: get all field from current SObject
     * @param SObject API Name
     * @param Where Clause 
     * @param Additional Fields
    *******************************************************************************************************/
    public static String getWholeFieldsQuery(String SObjectAPI, String whereClause ,String additionalFields ){
        String query = 'SELECT';
        Map<String, Schema.SObjectField> objectFields = Schema.getGlobalDescribe().get(SObjectAPI).getDescribe().fields.getMap();
        
        // Grab the fields from the describe method and append them to the queryString one by one.
        for(String s : objectFields.keySet()) {
            if(query=='SELECT'){
                query += ' '+s;
            }else if( s!='dnboptimizer__family_tree_link_status__c' && s!='dnboptimizer__number_of_contact__c'&&
 s!='dnboptimizer__number_of_task__c'&& s!='dnboptimizer__number_of_opportunity__c'){
                query += ', ' + s ;
            }
        }
        
        //check whether aditional field exists or not.
        if(additionalFields != null && additionalFields != ''){
            // Manually add related object's fields that are needed.
            if(query.endsWith(',')){
                query += additionalFields +','; 
            }else{
                query += ','+additionalFields +','; 
            }
            
        }
        
        // Strip off the last comma if it exists.
        if (query.trim().subString(query.Length()-1,query.Length()) == ','){
            query = query.subString(0,query.Length()-1);
        }
        
        // Add FROM statement
        query += ' FROM ' + SObjectAPI;
        
        // Add on a WHERE/ORDER/LIMIT statement as needed
        if(whereClause!='')
        query += ' WHERE '+whereClause;
        
        return query;
    }
}