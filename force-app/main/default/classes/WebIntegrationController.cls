/**
*
*
* @Author Ivan Yeung
* @Date 2018/11/11
* @Description  Apex controller to interface with web server / CMS server integration
* @group Controller
*/
public with sharing class WebIntegrationController {

    public static final String STATUS_SUCCESS = 'SUCCESS';
    public static final String STATUS_FAILURE = 'FAILURE';

    public class WebDTO {

        @AuraEnabled Public String url;
        @AuraEnabled Public String success_message;
        @AuraEnabled Public String failure_message;
        @AuraEnabled Public String status; // SUCCESS / FAILURE

    }

    /*

opportunity.Name,
opportunity.Reseller_Contact__c,
opportunity.Reseller__c,
opportunity.Distributor__c, (optional)
opportunity.Distributor__r.Name (optional)
opportunity.Primary_Product_Family_2__c,
opportunity.CloseDate,
opportunity.OwnerId,
opportunity.LastModifiedDate,
opportunity.AccountId, (this is the customer id)
opportunity.Account.Name,

opportunity.Primary_Contact__c (this replace the old Contact_Name__c field)
opportunity.Deal_Reg_Tracking_No__c, (optional)
opportunity.Model_Series__c,
opportunity.reseller_contact_name__c ,
opportunity.reseller_contact_email__c ,


     */

    @TestVisible
    private static List <String> mandatoryDealRegOpptyFields = new List <String> {
            'Name',
            'Primary_Product_Family_2__c',
            'Model_Series__c',
            'CloseDate',
            'Reseller__c',
            'Reseller_Contact__c',
            'reseller_contact_name__c',
            'reseller_contact_email__c',
            'OwnerId',
            'Primary_Contact__c',
            'Terr_Theater__c'
    };

    @TestVisible
    private static List <String> mandatoryDealRegAcctFields = new List <String> {
            'Name'
    };

    @TestVisible
    private static String sumitDealRegApproval(Id recordId, String approvalProcess, String comments){

        String errorMsg = '';

        if (String.isBlank(approvalProcess)){
            return errorMsg;
        }

        try {
            // Create an approval request for the account
            Approval.ProcessSubmitRequest req1 =
                    new Approval.ProcessSubmitRequest();
            req1.setComments(comments);
            req1.setObjectId(recordId);

            // Submit on behalf of current user
            req1.setSubmitterId(UserInfo.getUserId());

            // Submit the record to specific process and skip the criteria evaluation
            req1.setProcessDefinitionNameOrId(approvalProcess);
            req1.setSkipEntryCriteria(false); // don't skip entry critiera

            // Submit the approval request for the account
            Approval.ProcessResult result = Approval.process(req1);

            // Verify the result
            System.assert(result.isSuccess());

            System.assertEquals(
                    'Pending', result.getInstanceStatus(),
                    'Instance Status' + result.getInstanceStatus());
        } catch (Exception e){
            errorMsg = e.getMessage();
        }


        return errorMsg;
    }

    /**
     *
     *
     * @param recordId
     *
     * @return
     *     Success: URL of the Deal Reg
     *     Failure: a String of message that should be displayed at the pop up message
     *
     */
    @AuraEnabled
    public static WebDTO getDealRegURL(Id recordId, String comments){

        WebDTO dto = new WebDTO();


        try {
            dto.url = '';

            String soql = 'select id, AccountId  ';
            for (String s : mandatoryDealRegOpptyFields) {
                soql += ',' + s;
            }
            for (String s : mandatoryDealRegAcctFields) {
                soql += ',' + 'Account.' + s;
            }
            soql += ' from opportunity where id =:recordId';
            System.debug('#!#! SOQL: ' + soql);


            Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
            Map<String, Schema.SObjectField> opptyFieldMap = schemaMap.get('Opportunity').getDescribe().fields.getMap();
            Map<String, Schema.SObjectField> acctFieldMap = schemaMap.get('Account').getDescribe().fields.getMap();

            Boolean isReady = true;
            String opptErrorMessage = '';
            String acctErrorMessage = '';
            String theater = '';
            For (Opportunity o : Database.query(soql)) {
                for (String s : mandatoryDealRegOpptyFields) {
                    if (String.isBlank(String.valueOf(o.get(s)))) {
                        isReady = isReady && false;
                        opptErrorMessage += opptErrorMessage == '' ? '' : ', ';
                        opptErrorMessage += opptyFieldMap.get(s).getDescribe().getLabel();  // label of the field
                    }
                }

                // account field checking
                SObject a = o.getSObject('account');
                if (a != null) {
                    for (String s : mandatoryDealRegAcctFields) {
                        if (String.isBlank(String.valueOf(a.get(s)))) {
                            isReady = isReady && false;
                            acctErrorMessage += acctErrorMessage == '' ? '' : ', ';
                            acctErrorMessage += acctFieldMap.get(s).getDescribe().getLabel();  // label of the field
                        }
                    }
                }

                theater = o.Terr_Theater__c ;

            }


            for (Web_Integration_Setting__mdt s : [
                    select Base_URL__c, DeveloperName, Id, Label, Language, MasterLabel,
                            NamespacePrefix, Parameter1_Label__c, Parameter1_Value__c, Parameter2_Label__c, Parameter2_Value__c,
                            Parameter3_Label__c, Parameter3_Value__c, QualifiedApiName, Approval_Process__c, Custom_Permission__c, Failure_Message__c, Success_Message__c
                    from Web_Integration_Setting__mdt
                    where DeveloperName = 'Deal_Reg'
            ]) {

                Boolean hasPermission = true;
                if (String.isNotBlank(s.Custom_Permission__c)) {
                    FeatureManagement.checkPermission(s.Custom_Permission__c);
                }

                if (hasPermission || Test.isRunningTest()) { // skip permission check if testing

                    if (isReady) {
                        // dto.url = s.Base_URL__c + recordId + '?' + s.Parameter1_Label__c + '=' + s.Parameter1_Value__c + '&' + s.Parameter2_Label__c + '=' + s.Parameter2_Value__c;

                        dto.success_message = s.Success_Message__c;
                        dto.status = STATUS_SUCCESS;

                        if (s.Approval_Process__c != null) {
                            // approval process being a comma delimited list
                            List<String> approvalProcesses = s.Approval_Process__c.split(',');

                            for (String ap : approvalProcesses) {
                                System.debug('---- trying to submit: ' + ap);
                                // if (ap.contains(theater)) { remove territory check, just rely on approval entry critiera.
                                    String approvalErr = sumitDealRegApproval(recordId, ap, comments);
                                    if (String.isNotBlank(approvalErr)) {
                                        // keep the last error but continue to loop through the rest
                                        dto.failure_message = approvalErr;
                                        dto.status = STATUS_FAILURE;
                                    } else {
                                        dto.success_message = s.Success_Message__c;
                                        dto.status = STATUS_SUCCESS;
                                        break; // exit first submission
                                    }

                                // }

                            }
                        }


                    } else {

                        dto.failure_message = s.Failure_Message__c;
                        dto.failure_message = 'The deal registration requeset cannot be processed because these fields are missing: ';
                        if (String.isNotBlank(opptErrorMessage)) {
                            dto.failure_message += ' ( Opportunities: ' + opptErrorMessage + ' ) ';
                        }
                        if (String.isNotBlank(acctErrorMessage)) {
                            dto.failure_message += ' ( Account: ' + acctErrorMessage + ' ) ';
                        }
                        dto.status = STATUS_FAILURE;
                    }

                } else {
                    dto.failure_message = 'Sorry you don\'t have the permission to initiate deal registration';
                    dto.status = STATUS_FAILURE;
                }
            }
            // https://www.barracuda.com/web_api/create_dealreg_from_sf/0066000001rtjfG?uname=webprod&pswd=14273371c52b0b162c5748169c69ad17

        } Catch (Exception e){
            dto.failure_message = String.valueOf(e);
            dto.status = STATUS_FAILURE;
        }

        return dto;
    }




    /**
    *
    *
    * @param recordId of an account
    *
    * @return
    *     Success: URL of the Deal Reg
    *     Failure: a String of message that should be displayed at the pop up message
    *
    */
    @AuraEnabled
    public static WebDTO getCreditCardURL(Id recordId){


        WebDTO dto = new WebDTO();

        try {
            String objName = '';
            if (recordId != null) {
                objName = recordId.getSobjectType().getDescribe().getName();
            }

            System.debug('#!#! objectName: ' + objName);


            dto.url = '';

            String accountId = '';
            String accountName = '';
            String opportunityName = '';
            String opportunityId = '';

            if (objName == 'Opportunity') {
                For (Opportunity o : [select id, Bill_To_Account__c, Bill_To_Account__r.Name, Name, account.Name from Opportunity where id = :recordId]) {
                    accountId = o.Bill_To_Account__c;
                    accountName = o.Bill_To_Account__r.Name;
                    opportunityName = o.name;
                }
                opportunityId = recordId;
            } else if (objName == 'Account') {
                accountId = recordId;

                For (Account o : [select id, Name from Account where id = :recordId]) {
                    accountName = o.name;
                }

            }

            System.debug('#!#! accountId: ' + accountId);
            System.debug('#!#! accountName: ' + accountName);
            System.debug('#!#! opportunityName: ' + opportunityName);
            System.debug('#!#! opportunityId: ' + opportunityId);

            String developerName = 'Credit_Card_' + objName;
            for (Web_Integration_Setting__mdt s : [
                    select Base_URL__c, DeveloperName, Id, Label, Language, MasterLabel,
                            NamespacePrefix, Parameter1_Label__c, Parameter1_Value__c, Parameter2_Label__c, Parameter2_Value__c,
                            Parameter3_Label__c, Parameter3_Value__c, QualifiedApiName, Custom_Permission__c, Failure_Message__c, Success_Message__c
                    from Web_Integration_Setting__mdt
                    where DeveloperName = :developerName
            ]) {


                Boolean hasPermission = true;
                if (String.isNotBlank(s.Custom_Permission__c)) {
                    hasPermission = FeatureManagement.checkPermission(s.Custom_Permission__c);
                }

                if (hasPermission) {

                    if (String.isBlank(accountId)) {
                        dto.failure_message = 'The Bill to Account is missing';
                        dto.status = STATUS_FAILURE;
                    } else {
                        if (objName == 'Account') {
                            dto.url = s.Base_URL__c + '?' + s.Parameter1_Label__c + '=' + accountId;
                        } else if (objName == 'Opportunity') {
                            dto.url = s.Base_URL__c + '?' + s.Parameter1_Label__c + '=' + accountId + '&' + s.Parameter2_Label__c + '=' + opportunityId;
                        }

                        dto.failure_message = s.Failure_Message__c;
                        dto.success_message = s.Success_Message__c;

                        if (String.isNotBlank(accountName)) {
                            dto.success_message += ' (' + 'Account: ' + accountName + ') ';
                        }
                        if (String.isNotBlank(opportunityName)) {
                            dto.success_message += ' (' + +'Opportunity: ' + opportunityName + ') ';
                        }

                        dto.status = STATUS_SUCCESS;
                    }

                } else {
                    dto.failure_message = 'Sorry you don\'t have the permission to add credit card';
                    dto.status = STATUS_FAILURE;
                }


                break;
            }

            // http://webdev.barracuda.com:81/dbfix/mesForm?aid=0018A000009mOZcQAM&oid=0088A000009mOZcQAM

        } Catch (Exception e){
            dto.failure_message = String.valueOf(e);
            dto.status = STATUS_FAILURE;
        }

        return dto;
    }


    /**
   *
   *
   * @param recordId of an order
   *
   * @return
   *     Success: order summary
   *     Failure: error message
   *
   */
    @AuraEnabled
    public static WebDTO getOrderSummary(Id recordId){


        WebDTO dto = new WebDTO();

        try {
            String objName = '';
            if (recordId != null) {
                objName = recordId.getSobjectType().getDescribe().getName();
            }

            System.debug('#!#! objectName: ' + objName);


            dto.url = '';

            String accountId = '';
            String accountName = '';
            String opportunityName = '';
            String opportunityId = '';
            String orderId = '';

            Boolean opptySummaryCompleted = false;
            Boolean orderSummaryCompleted = false;


            dto.status = STATUS_SUCCESS;
            dto.success_message = '';


            Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
            Schema.SObjectType orderSchema = schemaMap.get('Order');
            Schema.SObjectType orderItemSchema = schemaMap.get('OrderItem');
            Schema.SObjectType opportunitySchema = schemaMap.get('Opportunity');
            Map<String, Schema.SObjectField> orderFieldMap = orderSchema.getDescribe().fields.getMap();
            Map<String, Schema.SObjectField> orderItemFieldMap = orderItemSchema.getDescribe().fields.getMap();
            Map<String, Schema.SObjectField> opportunityFieldMap = opportunitySchema.getDescribe().fields.getMap();


            // fieldMap.get(fieldName).getDescribe().getLabel();//It provides to get the object fields label.


            for (OrderItem item: [select Quantity, order.opportunity.Primary_Contact__r.Name, order.opportunityId,  order.opportunity.Name, order.opportunity.PurchaseOrderID__c, order.pricebook2id, order.pricebook2.name, Order_Number__c, OrderId, order.ordernumber, order.order_record_id__c,  Original_Order_Id__c, Original_Order_Number__c,  id, order_line_record_id__c,  OrderItemNumber, Order_Item_number__c,Original_OrderItem_Id__c,
                    OriginalOrderItemId,  Product2Id, product2.name, Product2.productCode, SKU__c from OrderItem  where orderid = :recordId order by OrderItemNumber ]) {

                if (!opptySummaryCompleted){
                    dto.success_message += 'Opportunity Record ID: ' + item.order.opportunityId + ' \n';
                    dto.success_message += 'Opportunity Name: ' + item.order.opportunity.Name + ' \n';
                    dto.success_message += 'Primary Contact: ' + item.order.opportunity.Primary_Contact__r.Name + ' \n';
                    // dto.success_message += 'Opportunity Purchase Order #: ' + item.order.opportunity.PurchaseOrderID__c + ' \n';
                    // dto.success_message += 'Opportunity Pricebook Name: ' + item.order.pricebook2.name + ' \n';

                    dto.success_message += '---------------------------\n';
                    opptySummaryCompleted = true;
                }

                if (!orderSummaryCompleted){
                    dto.success_message += 'Order Number: ' + item.Order_Number__c + ' \n';
                    dto.success_message += 'Order Record ID: ' + item.OrderId + ' \n';
                    // dto.success_message += 'Order Pricebook Name: ' + item.order.pricebook2.name + ' \n';

                    dto.success_message += '---------------------------\n';

                    orderSummaryCompleted = true;
                }


                dto.success_message += 'Order Line Number: ' + item.OrderItemNumber + ' \n';
                dto.success_message += 'Order Line Record ID: ' + item.id + ' \n';
                dto.success_message += 'Product SKU: ' + item.SKU__c + ' \n';
                dto.success_message += 'Product Name: ' + item.product2.name + ' \n';
                dto.success_message += 'Quantity: ' + item.Quantity + ' \n';
                dto.success_message += '---------------------------\n';
            }



        } Catch (Exception e){
            dto.failure_message = String.valueOf(e);
            dto.status = STATUS_FAILURE;
        }

        return dto;
    }


    /**
   *
   *
   * @param recordId of an order
   *
   * @return
   *     Success: URL of the BOS order tool
   *     Failure: a String of message that should be displayed at the pop up message
   *
   */
    @AuraEnabled
    public static WebDTO getBOSOrderURL(Id recordId){


        WebDTO dto = new WebDTO();

        try {
            String objName = '';
            if (recordId != null) {
                objName = recordId.getSobjectType().getDescribe().getName();
            }

            System.debug('#!#! objectName: ' + objName);


            dto.url = '';
            String urlParameters = '?sf_order_id=' + recordId;
            //&sf_order_id=00828282822&sf_line_item_id=00929292922&sf_line_item_id=00929292923



            For (OrderItem i: [select id, orderid, order.ordernumber, orderitemnumber from OrderItem where orderid =:recordId ]){
                urlParameters += '&sf_line_item_id=' + i.id;
            }


            String developerName = 'BOS_Order_Tool';
            for (Web_Integration_Setting__mdt s : [
                    select Base_URL__c, DeveloperName, Id, Label, Language, MasterLabel,
                            NamespacePrefix, Parameter1_Label__c, Parameter1_Value__c, Parameter2_Label__c, Parameter2_Value__c,
                            Parameter3_Label__c, Parameter3_Value__c, QualifiedApiName, Custom_Permission__c, Failure_Message__c, Success_Message__c
                    from Web_Integration_Setting__mdt
                    where DeveloperName = :developerName
            ]) {


                Boolean hasPermission = true;
                if (String.isNotBlank(s.Custom_Permission__c)) {
                    hasPermission = FeatureManagement.checkPermission(s.Custom_Permission__c);
                }

                if (hasPermission) {

                    dto.url = s.Base_URL__c + urlParameters;
                    dto.failure_message = s.Failure_Message__c;
                    dto.success_message = s.Success_Message__c;
                    dto.status = STATUS_SUCCESS;

                } else {
                    dto.failure_message = 'Sorry you don\'t have the permission to add credit card';
                    dto.status = STATUS_FAILURE;
                }


                break;
            }

        } Catch (Exception e){
            dto.failure_message = String.valueOf(e);
            dto.status = STATUS_FAILURE;
        }

        return dto;
    }

    // Aditya - New method to get Credit Card URL 
    @AuraEnabled
    public static WebDTO getCreditCardURLwithKey(Id recordId){
        System.debug('recordId...'+recordId);
        WebDTO dto = new WebDTO();
        try {
            String objName = '';
            if (recordId != null) {
                objName = recordId.getSobjectType().getDescribe().getName();
            }
            System.debug('objName...'+objName);
            dto.url = '';

            String accountId = '';
            String accountName = '';

            accountId = recordId;

            For (Account o : [select id, Name from Account where id = :recordId]) {
                accountName = o.name;
            }
            System.debug('accountName...'+accountName);
            String developerName = 'Credit_Card_' + objName;
            System.debug('developerName...'+developerName);
            for (Web_Integration_Setting__mdt s : [
                    select Base_URL__c, DeveloperName, Id, Label, Language, MasterLabel,
                            NamespacePrefix, Parameter1_Label__c, Parameter1_Value__c, Parameter2_Label__c, Parameter2_Value__c,
                            Parameter3_Label__c, Parameter3_Value__c, QualifiedApiName, Custom_Permission__c, Failure_Message__c, Success_Message__c
                    from Web_Integration_Setting__mdt
                    where DeveloperName = 'Credit_Card_Link'
            ]) {
                System.debug('Web_Integration_Setting__mdt...'+s);
                Boolean hasPermission = true;
                /*if (String.isNotBlank(s.Custom_Permission__c)) {
                    hasPermission = FeatureManagement.checkPermission(s.Custom_Permission__c);
                }*/

                if (hasPermission) {
                    if (String.isBlank(accountId)) {
                        dto.failure_message = 'The Bill to Account is missing';
                        dto.status = STATUS_FAILURE;
                    } else {
                        if (objName == 'Account') {
                            System.debug('inside Account logic...');
                            // Encryption logic
                            Blob targetBlob = Blob.valueOf(s.Parameter1_Value__c);
                            Blob cryptoKey = Crypto.generateDigest('SHA-256', targetBlob);
                            Blob exampleIv = Blob.valueOf(s.Parameter3_Value__c);
                            Long timeLong= (System.currentTimeMillis()/1000 ) + 3000;
                            System.debug('timeLong...'+ timeLong);
                            String accountIdwithTime = accountId+'.'+timeLong;
                            Blob data = Blob.valueOf(accountIdwithTime);
                            Blob encrypted = Crypto.encrypt('AES256', cryptoKey, exampleIv, data);
                            String encodedKey = EncodingUtil.base64Encode(encrypted);
                            String urlEncodedKey = EncodingUtil.urlEncode(encodedKey,'UTF-8');
                            System.debug('encrypted...'+encodedKey);
                            System.debug('urlEncodedKey...'+urlEncodedKey);
                            dto.url = s.Base_URL__c + '?' + s.Parameter1_Label__c + '=' + accountId + '&' + s.Parameter2_Label__c + '=' + urlEncodedKey;
                            System.debug('dto.url...'+dto.url);
                        }

                        dto.failure_message = s.Failure_Message__c;
                        dto.success_message = s.Success_Message__c;

                        if (String.isNotBlank(accountName)) {
                            dto.success_message += ' (' + 'Account: ' + accountName + ') ';
                        }

                        dto.status = STATUS_SUCCESS;
                    }

                } else {
                    dto.failure_message = 'Sorry you don\'t have the permission to add credit card';
                    dto.status = STATUS_FAILURE;
                }

                break;
            }
        } 
        Catch (Exception e){
            System.debug('exception...'+e.getLineNumber());
            dto.failure_message = String.valueOf(e);
            dto.status = STATUS_FAILURE;
        }

        return dto;
    }

}