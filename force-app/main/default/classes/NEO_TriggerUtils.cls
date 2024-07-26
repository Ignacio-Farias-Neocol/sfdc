/**
 * @description       : This class contains utility methods for triggers
 * @author            : santiago.gonzalez@neocol.com
 * @group             : Neocol
 * @last modified on  : 07-19-2024
 * @last modified by  : Ignacio F.
**/
public class NEO_TriggerUtils {

    /**
    * @description This method will check if the record is new or if any of the fields have changed
    * @author santiago.gonzalez@neocol.com | 07-10-2024 
    * @param newRecord 
    * @param oldRecord 
    * @param fields 
    * @return Boolean 
    **/
    public static Boolean checkChangedFields(SObject newRecord, SObject oldRecord, List<Schema.SObjectField> fields) {
        if ( oldRecord == null ) {
            return true;
        }
        for ( Schema.SObjectField field : fields ) {
            if ( newRecord.get(field) != oldRecord.get(field) ) {
                return true;
            }
        }
        return false;
    }
    
    /**
    * @description This method will return an SObject with the recordId sent from the Map. If no record is present, one will be created
    * @author santiago.gonzalez@neocol.com | 07-11-2024 
    * @param recordsMap 
    * @param recordId 
    * @return SObject 
    **/
    public static SObject getRecordFromMap(Map<Id, SObject> recordsMap, Id recordId) {
        if ( !recordsMap.containsKey(recordId) ) {
            recordsMap.put(recordId, recordId.getSObjectType().newSObject(recordId));
        }
        return recordsMap.get(recordId);
    }
}