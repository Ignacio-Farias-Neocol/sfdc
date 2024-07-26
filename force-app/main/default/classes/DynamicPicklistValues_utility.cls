/**
*  @author Venkata Polavarapu
*  @date 12/28/17
*  @group utility
*  @description  utility class for to get picklist value
*/
public class DynamicPicklistValues_utility {
    /*******************************************************************************************************
* @description Get picklist value based on parameter passed
* @param sobject name,Field Name and first value 
* @return List of String
*/
    public static List<string> getPickValues(string object_name, String field_name, String first_val) {
            List<string> options = new List<string>(); //new list for holding all of the picklist options
            if (first_val != null) { //if there is a first value being provided
                options.add(first_val); //add the first option
            }
            Schema.sObjectType sobject_type = Schema.getGlobalDescribe().get(object_name);//object_name.getSObjectType(); //grab the sobject that was passed
            Schema.DescribeSObjectResult sobject_describe = sobject_type.getDescribe(); //describe the sobject
            Map<String, Schema.SObjectField> field_map = sobject_describe.fields.getMap(); //get a map of fields for the passed sobject
            List<Schema.PicklistEntry> pick_list_values = field_map.get(field_name).getDescribe().getPickListValues(); //grab the list of picklist values for the passed field on the sobject
            for (Schema.PicklistEntry a : pick_list_values) { //for all values in the picklist list

                options.add(a.getlabel()); //add the value and label to our final list
            }

            return options; //return the List

    }
    /*******************************************************************************************************
* @description Get picklist value based on parameter passed
* @param sobject name,Field Name and first value 
* @return Map of String
*/
    public static Map<string, string> getPickValuesMap(string object_name, String field_name, String first_val) {
            Map<string, string> options = new Map<string, string>(); //new list for holding all of the picklist options
            if (first_val != null) { //if there is a first value being provided
                options.put(first_val, first_val); //add the first option
            }
            Schema.sObjectType sobject_type = Schema.getGlobalDescribe().get(object_name);//object_name.getSObjectType(); //grab the sobject that was passed
            Schema.DescribeSObjectResult sobject_describe = sobject_type.getDescribe(); //describe the sobject
            Map<String, Schema.SObjectField> field_map = sobject_describe.fields.getMap(); //get a map of fields for the passed sobject
            List<Schema.PicklistEntry> pick_list_values = field_map.get(field_name).getDescribe().getPickListValues(); //grab the list of picklist values for the passed field on the sobject
            for (Schema.PicklistEntry a : pick_list_values) { //for all values in the picklist list

                options.put(a.getLabel(), a.getValue()); //add the value and label to our final list
            }

            return options; //return the List
        
    }
    /*******************************************************************************************************
* @description Get picklist value with API name based on parameter passed
* @param sobject name,Field Name and first value 
* @return Map of String
*/
    public static Map<string, string> getPickValuesMapApiasKey(string object_name, String field_name, String first_val) {
            Map<string, string> options = new Map<string, string>(); //new list for holding all of the picklist options
            if (first_val != null) { //if there is a first value being provided
                options.put(first_val, first_val); //add the first option
            }
            Schema.sObjectType sobject_type = Schema.getGlobalDescribe().get(object_name);//object_name.getSObjectType(); //grab the sobject that was passed
            Schema.DescribeSObjectResult sobject_describe = sobject_type.getDescribe(); //describe the sobject
            Map<String, Schema.SObjectField> field_map = sobject_describe.fields.getMap(); //get a map of fields for the passed sobject
            List<Schema.PicklistEntry> pick_list_values = field_map.get(field_name).getDescribe().getPickListValues(); //grab the list of picklist values for the passed field on the sobject
            for (Schema.PicklistEntry a : pick_list_values) { //for all values in the picklist list

                options.put(a.getValue(), a.getLabel()); //add the value and label to our final list
            }

            return options; //return the List
       }
}