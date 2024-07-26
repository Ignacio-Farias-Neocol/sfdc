/**
 * Created by iyeung on 11/1/18.
 */
({

    // temporary solution, will need to use country and state picklist
    /*
    countryProvinceMap: {
        US: [
            {'label': 'California', 'value': 'CA'},
            {'label': 'Texas', 'value': 'TX'},
            {'label': 'Washington', 'value': 'WA'},
        ],
        CN: [
            {'label': 'GuangDong', 'value': 'GD'},
            {'label': 'GuangXi', 'value': 'GX'},
            {'label': 'Sichuan', 'value': 'SC'},
        ],
        VA: [],
    },
    */

    /*
    countryOptions: [
        {'label': 'United States', 'value': 'US'},
        {'label': 'China', 'value': 'CN'},
        {'label': 'Vatican', 'value': 'VA'},
    ],
    */
    countryProvinceMap: {},
    countryOptions: [],



    getProvinceOptions: function(country) {
        return this.countryProvinceMap.get(country);
    },
    getCountryOptions: function() {
        return this.countryOptions;
    },

    handleAddrUpdate: function (cmp, event, addressType) {



        var addressId;
        var addresses;
        if (addressType == 'billTo') {
            // find the Address being used
            addressId = cmp.get("v.selectedBillToId");
            addresses = cmp.get("v.billToAddresses");
        } else if (addressType == 'shipTo') {
            // find the Address being used
            addressId = cmp.get("v.selectedShipToId");
            addresses = cmp.get("v.shipToAddresses");
        }
        var theAddress;
        addresses.forEach(function(element) {
            if (element.Id == addressId){
                theAddress = element;
            }
        });

        if (theAddress == null){
            alert("Please choose an address");
        } else {


            cmp.set("v.isDataLoading", true); // set hourglass

            var action = cmp.get("c.createUpdateAddress");
            // operation: update - update address to opportunity only,  createUpdate - create new address and update opportunity Address

            var jsonAddress = JSON.stringify(theAddress);

            action.setParams({
                recordId: cmp.get("v.recordId"),
                operation: "update",
                accountType: "",
                addressType: addressType,
                addressObj: jsonAddress
            });
            action.setCallback(this, function(response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    var ctrlClass = response.getReturnValue() ;  // this is the class itself
                    this.setAllProperties(cmp, ctrlClass);
                }
            });
            $A.enqueueAction(action);
        }


    },



    handleAddrNew: function (cmp, event, addressType) {




        var theAddress = new Object();
        var accountType;

        if (addressType == 'billTo') {
            theAddress.Street__c  =  cmp.get("v.nBStreet");
            theAddress.City__c  =  cmp.get("v.nBCity");
            theAddress.Zip_Postal_Code__c  =  cmp.get("v.nBPostalCode");

            var countryId =  cmp.get("v.nBCountry");
            var countryName = this.getByValue(this.countryOptions, countryId );
            var stateId = cmp.get("v.nBProvince");
            var stateArray = this.countryProvinceMap.get(countryId);
            if (stateArray != null) {
                var stateName = this.getByValue(stateArray, stateId);
            }

            // to do: figure how to populate relation in javascript
            // theAddress.putSObject('State__r', new State__c(Name=stateName.label));
            // theAddress.putSObject('Country__r', new Country__c(Name=countryName.label));

            theAddress.State__c  =  stateId;
            theAddress.Country__c  = countryId;

            accountType = cmp.find("billToSourceId").get('v.value'); 




        } else if (addressType == 'shipTo') {
            theAddress.Street__c  =  cmp.get("v.nSStreet");
            theAddress.City__c  =  cmp.get("v.nSCity");
            theAddress.Zip_Postal_Code__c  =  cmp.get("v.nSPostalCode");

            var countryId =  cmp.get("v.nSCountry");
            var countryName = this.getByValue(this.countryOptions, countryId );
            var stateId = cmp.get("v.nSProvince");
            var stateArray = this.countryProvinceMap.get(countryId);
            if (stateArray != null) {
                var stateName = this.getByValue(stateArray, stateId);
            }

            // to do: figure how to populate relation in javascript
            // theAddress.putSObject('State__r', new State__c(Name=stateName.label));
            // theAddress.putSObject('Country__r', new Country__c(Name=countryName.label));


            theAddress.State__c  =  cmp.get("v.nSProvince");
            theAddress.Country__c  =  cmp.get("v.nSCountry");

            var shipToSource = cmp.find("shipToSourceId");
            accountType = shipToSource.get('v.value');

        }

        if (accountType == null || accountType == ''){
            alert("Please pick an address source");
        } else if (theAddress.Street__c == ''  || theAddress.Street__c == null ||
            theAddress.Country__c == ''  || theAddress.Country__c == null ||
            theAddress.City__c == ''  || theAddress.City__c == null
        ){
            alert("Please complete the address");
        } else {


            cmp.set("v.isDataLoading", true); // set hourglass

            var action = cmp.get("c.createUpdateAddress");
            // operation: update - update address to opportunity only,  createUpdate - create new address and update opportunity Address

            var jsonAddress = JSON.stringify(theAddress);

            action.setParams({
                recordId: cmp.get("v.recordId"),
                operation: "createUpdate",
                accountType: accountType,
                addressType: addressType,
                addressObj: jsonAddress
            });
            action.setCallback(this, function(response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    var ctrlClass = response.getReturnValue() ;  // this is the class itself
                    this.setAllProperties(cmp, ctrlClass);
                }
            });
            $A.enqueueAction(action);
        }


    },

    getByValue: function (arr, value) {

        for (var i=0, iLen=arr.length; i<iLen; i++) {

            if (arr[i].value == value) return arr[i];
        }
    },

    compareLabel: function(a,b) {
        if (a.label < b.label)
            return -1;
        if (a.label > b.label)
            return 1;
        return 0;
    },


    setAllProperties: function(cmp, ctrlClass) {


        cmp.set("v.isDataLoading", true); // set hourglass
        try {

            var countryMap = ctrlClass.countryMap;
            this.countryOptions = []; // reset country list
            for (var key in countryMap) {
                var countryElement = new Object();
                countryElement.label = countryMap[key].Name;
                countryElement.value = key;
                this.countryOptions.push(countryElement);
            }
            // this.countryOptions.sort(compareLabel);
            cmp.set("v.nBCountryOptions", this.countryOptions);
            cmp.set("v.nSCountryOptions", this.countryOptions);


            var countryStateMap = ctrlClass.countryStateMap;
            
            cmp.set("v.billToContactDetails",ctrlClass.opptyBillToAccount);
            cmp.set("v.shipToContactDetails",ctrlClass.opptyShipToAccount);
            cmp.set("v.billShipEditable",ctrlClass.billShipEditable);
            
            
            this.countryProvinceMap = new Map();
            for (var countryKey in countryStateMap) {

                var stateMap = countryStateMap[countryKey];

                var stateArray = [];
                for (var stateKey in stateMap) {
                    var stateElement = new Object();
                    stateElement.label = stateMap[stateKey].Name;
                    stateElement.value = stateMap[stateKey].Id;
                    stateArray.push(stateElement);
                }
                this.countryProvinceMap.set(countryKey, stateArray);

                // debug only
                /*
                if (countryKey == 'a1U3C0000001HAIUA2'){
                    alert('FOUND UNITED state: ' + stateArray);
                    alert('FOUND UNITED country key: ' + countryKey);
                    var thisArray = this.countryProvinceMap.get(countryKey);
                    alert('FOUND UNITED state value text: ' + thisArray[0].value + ' ' +  thisArray[0].label);
                }
                */
            }

            cmp.set("v.account", ctrlClass.opptyAccount);
            cmp.set("v.opportunity", ctrlClass.oppty);

            cmp.set("v.distributor", ctrlClass.opptyDistributor);
            cmp.set("v.reseller", ctrlClass.opptyReseller);

            // populate bill to drop down and available address
            var billToOptions = ctrlClass.billToOptions;
            var options = [];
            billToOptions.forEach(function (element) {
                // list of account object
                options.push({value: element.optionType, label: element.optionName});
            });
            cmp.set("v.billToOptions", options);

            // set the first one as default for bill to
            var billToSource = cmp.find("billToSourceId");
            // alert('bill to source obj:' + billToSource);
            if (options.length > 0) {
                billToSource.set("v.value", options[0].value);
                // set the billTo address list accoridngly
                if (options[0].value == "distributor") {
                    cmp.set("v.billToAddresses", ctrlClass.opptyDistributorAddressesBT);
                    cmp.set("v.billToAddressesDistributor", ctrlClass.opptyDistributorAddressesBT);
                } else if (options[0].value == "reseller") {
                    cmp.set("v.billToAddresses", ctrlClass.opptyResellerAddressesBT);
                    cmp.set("v.billToAddressesReseller", ctrlClass.opptyResellerAddressesBT);
                } else if (options[0].value == "account") {
                    cmp.set("v.billToAddresses", ctrlClass.opptyAccountAddressesBT);
                    cmp.set("v.billToAddressesAccount", ctrlClass.opptyAccountAddressesBT);
                }
            }


            // populate ship to drop down and available address
            var sOptions = [];


            var shipToOptions = ctrlClass.shipToOptions;
            shipToOptions.forEach(function (element) {
                // list of account object
                sOptions.push({value: element.optionType, label: element.optionName});
                if (element.optionType == "distributor") {
                    cmp.set("v.shipToAddressesDistributor", ctrlClass.opptyDistributorAddressesST);
                } else if (element.optionType == "reseller") {
                    cmp.set("v.shipToAddressesReseller", ctrlClass.opptyResellerAddressesST);
                } else if (element.optionType == "account") {
                    cmp.set("v.shipToAddressesAccount", ctrlClass.opptyAccountAddressesST);
                }

            });
            cmp.set("v.shipToOptions", sOptions);



            // set default
            // 2018-11-07 TO DO: the component is not visible. so it is undefined at this point
            var shipToSource = cmp.find("shipToSourceId");
            if (sOptions.length > 0) {
                // shipToSource.set("v.value", sOptions[0].value);
                // set the ship address list accoridngly
                /*
                if (sOptions[0].value == "distributor") {
                    cmp.set("v.shipToAddresses", ctrlClass.opptyDistributorAddressesST);
                    cmp.set("v.shipToAddressesDistributor", ctrlClass.opptyDistributorAddressesST);
                } else if (sOptions[0].value == "reseller") {
                    cmp.set("v.shipToAddresses", ctrlClass.opptyResellerAddressesST);
                    cmp.set("v.shipToAddressesReseller", ctrlClass.opptyResellerAddressesST);
                } else if (sOptions[0].value == "account") {
                    cmp.set("v.shipToAddresses", ctrlClass.opptyAccountAddressesST);
                    cmp.set("v.shipToAddressesAccount", ctrlClass.opptyAccountAddressesST);
                }
                */
            }

            // everything is done reset spinner
            cmp.set("v.isDataLoading", false);


        } catch (e){

            // reset when there is an error
            cmp.set("v.isDataLoading", false);

            throw new Error("Component failed. Please try again. If problem persist, please contact the administrator. " + e);



        }


    },

    // load all the data for attributes in parent component
    loadAllData: function (cmp, event) {

        var action = cmp.get("c.getClass");
        action.setParams({
            recordId: cmp.get("v.recordId")
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {

                var ctrlClass = response.getReturnValue() ;  // this is the class itself
                try {
                    this.setAllProperties(cmp, ctrlClass);
                    cmp.set("v.selectedTabId", "shipToTab");  // finished loading, set the default to ship to

                } catch (e){
                    throw new Error("Fail to load address information. If problem persist, please contact the administrator.  " + e);
                }

            }  else if (state === "INCOMPLETE") {
                // make sure that reset any hour glass
                cmp.set("v.isDataLoading", false);
                // do something
                console.log("Unhanded State : Incomplete");
            } else if (state === "ERROR") {
                // make sure that reset any hour glass
                cmp.set("v.isDataLoading", false);
                console.log("Call back of c.getClass failed.");
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " +
                            errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            }  else {
                // make sure that reset any hour glass
                cmp.set("v.isDataLoading", false);
                console.log('Unknown State: ' + state );
            }
        });
        $A.enqueueAction(action);
    },

    getHasPerm : function (cmp) {
        
        var getUserHasPerm = cmp.get("c.hasCustomPermission");
        
        getUserHasPerm.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {  
        cmp.set("v.updatePrimDisabled", response.getReturnValue());
            }
            else{
                alert('error'+response.getError());
            }
        });
        $A.enqueueAction(getUserHasPerm);
    }

})