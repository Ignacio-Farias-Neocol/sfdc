/**
* Apex Controller for SerialHistory Lighting component
*
* @Author Ivan Yeung
* @Date 2019/08/06
* @description
*       https://bugs.cudaops.com/browse/SFDC-6712
*
* @group Controller
*
*
*/
public with sharing class SerialHistoryController {

    public class SerialHistoryDTO implements Comparable {
        String serialId;
        String serialNumber;
        String serialActivationStatus;
        String serialStatus;
        Date serialActivationDate;
        String latestSerialNumber;
        String latestSerialId;
        String latestActivationStatus;
        String latestSerialStatus;
        Date latestActivationDate;
        String originalOrderId;
        String orderId; // current order, can be RMA
        String rmaNumber;
        String BOSrmaType;
        Date rmaDate;
        Decimal capacity;


        public Integer compareTo(Object compareTo) {
            SerialHistoryDTO compareToDTO = (SerialHistoryDTO) compareTo;
            try {
                // assume serial number is integer. otherwise, just return 0
                if (serialActivationDate != null && compareToDTO.serialActivationDate != null &&  serialActivationDate > compareToDTO.serialActivationDate  ) {
                // if (Integer.ValueOf(serialNumber) > Integer.ValueOf(compareToDTO.serialNumber)){
                    return -1;
                } else {
                    return 1;
                }
            } Catch (Exception e){
                System.debug('e:' + e);
            }

            return 0;

        }

        public SerialHistoryDTO (Serial__c s){
            serialId = s.Id;
            capacity = s.Capacity__c;
            serialNumber = s.Serial_Number__c;
            serialActivationStatus = s.Activation_Status__c;
            serialActivationDate = s.Activation_Date__c;
            serialStatus = s.Status__c;
            latestSerialNumber = s.Last_Serial__c;
            latestActivationStatus = s.Current_Status_Last_Serial__c;
            rmaDate = s.RMA_Date__c;
            rmaNumber = s.RMA_Number__c;
            BOSrmaType = s.BOS_RMA_Type__c;
            orderId = s.Order__c;
        }
    }

    public static Set <Id> serialIds = new Set<Id>();  // this is the list of collective serials
    public static Set <String> serialNumbers = new Set<String>();  // this is the list of serial numbers that are all related
    public static Id myRecordId;

    public static List<SerialHistoryDTO> pSerialHistoryDTOs;
    public static List<SerialHistoryDTO> serialHistoryDTOs {
        get {
            if (pSerialHistoryDTOs == null){
                pSerialHistoryDTOs = new List<SerialHistoryDTO>();

                // given a serial record id , get all the history information
                // find the initial sizeof serial;
                For (Serial__c s:[select Id,  Activation_Date__c, Activation_Status__c, Annotation_Type__c,
                        Auto_Renew_Auto_Bill__c, Base_Product_SKU__c, Capacity__c, Contract__c, Current_Status_Last_Serial__c,
                        Description__c, Disabled_Notes__c, eligible_Complimentary_HWW__c, Expire_Date__c, Extension_Date__c,
                        Firmware_Version__c, First_Serial__c, Hww_Refresh_Date__c, In_Rbm__c, International_Status__c,
                        Is_Pool__c, Is_Terminated__c, Last_Serial__c,  Legacy_Data__c, Legacy_Opportunity_ID__c,
                        Legacy_Opportunity_Key__c, Legacy_Order_Number__c, Lineage_Id__c, Location__c, MAC_Address__c,
                        Name, Order__c, Original_Order__c,  Phone_Home__c, Phone_Home_Domain__c, Phone_Home_IP__c,
                        Platform__c, Popkey__c, Region__c, RMA_Date__c, RMA_Number__c, BOS_RMA_Type__c, RowNumber__c, Serial_Number__c,
                        Shipped_Date__c, Status__c, Sub_Territory__c, Sub_Theater__c, Territory__c, Theater__c,
                        Unique_Contract_ID__c from Serial__c where id = :myRecordId] ){

                        SerialHistoryDTO dto = new SerialHistoryDTO(s);
                        pSerialHistoryDTOs.add(dto);
                        serialIds.add(s.Id);
                        if (String.isNotBlank(s.Serial_Number__c )){
                            serialNumbers.add(s.Serial_Number__c);
                        }
                        if (String.isNotBlank(s.Last_Serial__c )){
                            serialNumbers.add(s.Last_Serial__c);
                        }

                }

                if (serialNumbers.size() > 0 ){
                    gatherSerial();
                }

                pSerialHistoryDTOs.sort();
            }

            System.debug('~~~~~ SerialHistoryController pSerialHistoryDTOs: ' + pSerialHistoryDTOs);

            return pSerialHistoryDTOs;

        }
    }



    @AuraEnabled
    public static String getSerialHistory(Id recordId){
    // public static List<SerialHistoryDTO> getSerialHistory(Id recordId){

        myRecordId = recordId;

        System.debug('~~~~~ SerialHistoryController: ' + recordId);

        String historyJSON = JSON.serialize(serialHistoryDTOs);
        return historyJSON;


    }

    @TestVisible
    private static void gatherSerial(){

        Integer initialSize = serialNumbers.size();

        System.debug('~~~~~ gather Serial initialSize: ' + initialSize );

        For (Serial__c s:  [select Id,  Activation_Date__c, Activation_Status__c, Annotation_Type__c,
                Auto_Renew_Auto_Bill__c, Base_Product_SKU__c, Capacity__c, Contract__c, Current_Status_Last_Serial__c,
                Description__c, Disabled_Notes__c, eligible_Complimentary_HWW__c, Expire_Date__c, Extension_Date__c,
                Firmware_Version__c, First_Serial__c, Hww_Refresh_Date__c, In_Rbm__c, International_Status__c,
                Is_Pool__c, Is_Terminated__c, Last_Serial__c,  Legacy_Data__c, Legacy_Opportunity_ID__c,
                Legacy_Opportunity_Key__c, Legacy_Order_Number__c, Lineage_Id__c, Location__c, MAC_Address__c,
                Name, Order__c, Original_Order__c,  Phone_Home__c, Phone_Home_Domain__c, Phone_Home_IP__c,
                Platform__c, Popkey__c, Region__c, RMA_Date__c, RMA_Number__c, BOS_RMA_Type__c, RowNumber__c, Serial_Number__c,
                Shipped_Date__c, Status__c, Sub_Territory__c, Sub_Theater__c, Territory__c, Theater__c,
                Unique_Contract_ID__c from Serial__c
                where Serial_Number__c in :serialNumbers or  Last_Serial__c in :serialNumbers]){

            if (!serialIds.contains(s.Id)){
                SerialHistoryDTO dto = new SerialHistoryDTO(s);
                pSerialHistoryDTOs.add(dto);
                serialIds.add(s.Id);
                if (String.isNotBlank(s.Serial_Number__c )){
                    serialNumbers.add(s.Serial_Number__c);
                }
                if (String.isNotBlank(s.Last_Serial__c )){
                    serialNumbers.add(s.Last_Serial__c);
                }
            }
        }

        System.debug('~~~~~ gather Serial afterward size: ' + serialNumbers.size() );

        if (serialNumbers.size() > initialSize){
            gatherSerial();
        }


    }




}