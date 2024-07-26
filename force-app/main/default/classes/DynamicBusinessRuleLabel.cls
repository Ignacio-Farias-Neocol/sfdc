/**
* @author IY
* @date 2019
*
* @group DynamicBusinessRuleLabel
* @group-content a relative path to a static html file that provides content about the group
*
* @description implementation of DynamicBusinessRuleAction interface to set label on a object (in pre trigger context (
*/
public with sharing class DynamicBusinessRuleLabel implements DynamicBusinessRuleAction {

    private static Map<Integer,String> base30Mapping = new Map<Integer,String>{
            0 => '0',1 => '1',2 => '2',3 => '3',4 => '4',5 => '5',6 => '6',7 => '7',8 => '8',9 => '9',
            10 => 'A',11 => 'B',12 => 'C',13 => 'D',14 => 'E',15 => 'F',16 => 'G',17 => 'H',18 => 'I',19 => 'J',
            20 => 'K',21 => 'L',22 => 'M',23 => 'N',24 => 'O',25 => 'P',26 => 'Q',27 => 'R',28 => 'S',29 => 'T'
    };

    /**
    * @description Converts decimal into Base30 representation
    * @param num number to be converted
    * @return Base30 representation
    **/
    public static String convertToBase30(Decimal num){
        String value = '';
        Decimal inputValue = num;
        while(inputValue > 0) {
            Decimal element = Math.floor(inputValue / 30.0);
            Integer remainder = Integer.valueOf(inputValue - (30.0 * element));
            value = base30Mapping.get(remainder) + value;
            inputValue = element;
        }
        return value;
    }

    /**
    * @description Converts decimal into Base30 representation witl 0 left padding if required
    * @param num number to be converted
    * @param padLength numer of 0 pad
    * @return Base30 representation
    **/
    public static String convertToBase30(Decimal num, Integer padLength){
        return convertToBase30(num).leftPad(padLength,'0');
    }

    private String createLabel(SObject o, Label_Helper_Setting__mdt setting, String fieldName  , Boolean isBase30){

        String label = '';

        if (String.isNotBlank(fieldName)){
            String value = String.valueOf(o.get(fieldName ));

            if (isBase30){
                value = value.replaceAll('[^0-9]', ''); // get numeric only value
                value = convertToBase30(Decimal.valueOf(value), 6);
            }

            label += value;
        }

        return label;

    }

    /**
    Decimal num = 99999999;
    String s = DynamicBusinessRuleLabel.convertToBase30(num, 6);
    System.debug('~~ s: ' + s);   43DL39 -> So 6 digits are sufficient for most typical auto number in salesforce
    **/

    /*******************************************************************************************************
    * @description  update territory fields, based upon state_code__c field
    * @param trigger.new map
    * @return none, the result should be set to the records itself
    * @example
    */
    public void processRecords(Map<Id,SObject> newRecordMap, Map<Id,SObject> oldRecordMap, List <SObject> records, String jsonParameter, String triggerOrder, String triggerContext) {

        // set a field (target) based upon information from other fields

        if (records == null || records.size() == 0){
            return;
        }

        String objectName = records[0].getSObjectType().getDescribe().getName();


        List <Label_Helper_Setting__mdt> labelSettings = [select Connector__c, DeveloperName, Field1_Source__c, Field2_Source__c, Field3_Source__c,  Field1_Base30__c, Field2_Base30__c, Field3_Base30__c, Id, Label, Language, MasterLabel, NamespacePrefix,
                Prefix__c, QualifiedApiName, SObject_Name__c, Target_Field__c from Label_Helper_Setting__mdt where  SObject_Name__c = :objectName ];

        // assume : all the fields are available in pre trigger context


        for (Label_Helper_Setting__mdt setting: labelSettings){

            for (SObject o: records){

                String label = '';
                if (String.isNotBlank( setting.Prefix__c  )){
                    label += setting.Prefix__c;
                }

                if (String.isNotBlank(setting.Field1_Source__c) && String.isNotBlank( (String) o.get(setting.Field1_Source__c) )) {
                    label += label.length() > 0 ? setting.Connector__c : '';
                    label += createLabel(o, setting, setting.Field1_Source__c, setting.Field1_Base30__c);
                }
                if (String.isNotBlank(setting.Field2_Source__c) && String.isNotBlank( (String)  o.get(setting.Field2_Source__c) )) {
                    label += label.length() > 0 ? setting.Connector__c : '';
                    label += createLabel(o, setting, setting.Field2_Source__c, setting.Field2_Base30__c);
                }
                if (String.isNotBlank(setting.Field3_Source__c) && String.isNotBlank( (String)  o.get(setting.Field3_Source__c) )) {
                    label += label.length() > 0 ? setting.Connector__c : '';
                    label += createLabel(o, setting, setting.Field3_Source__c, setting.Field3_Base30__c);
                }

                o.put(setting.Target_Field__c, label );


            }


        }


    }

}