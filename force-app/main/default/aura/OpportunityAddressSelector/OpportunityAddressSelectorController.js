/**
 * Created by iyeung on 10/31/18.
 */
({

    doInit: function(cmp, event, helper) { 
        helper.loadAllData(cmp, event );
        helper.getHasPerm(cmp);

        // for billing  address
        // cmp.set("v.nBCountryOptions", helper.getCountryOptions());
        // cmp.set("v.nBProvinceOptions", helper.getProvinceOptions(cmp.get("v.nBCountry")));
    },

    onShipToCheckboxChange:  function(cmp, event, helper) {
        //Gets the checkbox group based on the checkbox id
        var availableCheckboxes = cmp.find('rowSelectionCheckboxIdST');
        var resetCheckboxValue  = false;
        if (Array.isArray(availableCheckboxes)) {
            //If more than one checkbox available then individually resets each checkbox
            availableCheckboxes.forEach(function(checkbox) {
                checkbox.set('v.value', resetCheckboxValue);
            });
        } else {
            //if only one checkbox available then it will be unchecked
            availableCheckboxes.set('v.value', resetCheckboxValue);
        }
        //mark the current checkbox selection as checked
        event.getSource().set("v.value",true);
        // save the id being selected
        cmp.set("v.selectedShipToId", event.getSource().get("v.text"));

    },

    onBillToCheckboxChange:  function(cmp, event, helper) {
        //Gets the checkbox group based on the checkbox id
        var availableCheckboxes = cmp.find('rowSelectionCheckboxIdBT');
        var resetCheckboxValue  = false;
        if (Array.isArray(availableCheckboxes)) {
            //If more than one checkbox available then individually resets each checkbox
            availableCheckboxes.forEach(function(checkbox) {
                checkbox.set('v.value', resetCheckboxValue);
            });
        } else {
            //if only one checkbox available then it will be unchecked
            availableCheckboxes.set('v.value', resetCheckboxValue);
        }
        //mark the current checkbox selection as checked
        event.getSource().set("v.value",true);
        // save the id being selected
        cmp.set("v.selectedBillToId", event.getSource().get("v.text"));
    },

    handleUpdateBillTo: function(cmp, event, helper) {
        helper.handleAddrUpdate(cmp, event, "billTo");
    },

    handleUpdateShipTo: function(cmp, event, helper) {
        helper.handleAddrUpdate(cmp, event, "shipTo");
    },

    handleNewBillTo: function(cmp, event, helper) {
        helper.handleAddrNew(cmp, event, "billTo");
    },

    handleNewShipTo: function(cmp, event, helper) {
        helper.handleAddrNew(cmp, event, "shipTo");
    },

    onBillToRadio: function(cmp, evt) {
        var selected = evt.getSource().get("v.text");
        alert("Address id: " + selected);
    },

    onShipToRadio: function(cmp, evt) {
        var selected = evt.getSource().get("v.text");
        alert("Address id: " + selected);
    },

    nBUpdateProvinces: function(cmp, event, helper) {
        cmp.set("v.nBProvinceOptions", helper.getProvinceOptions(cmp.get("v.nBCountry")));
        if(!cmp.get("v.nBCountry")){
            cmp.set("v.nBProvince", "");
        }
    },

    nSUpdateProvinces: function(cmp, event, helper) {
        cmp.set("v.nSProvinceOptions", helper.getProvinceOptions(cmp.get("v.nSCountry")));
        if(!cmp.get("v.nSCountry")){
            cmp.set("v.nSProvince", "");
        }
    },


    handleShipToOptionChange: function (cmp, event) {
        // This will contain the string of the "value" attribute of the selected option
        var selectedOptionValue = event.getParam("value");
        cmp.set("v.selectedShipToSource", selectedOptionValue); // Pass the Ship To Source selection to the shippingContact LWC
        // the expected value is source of bill to address : account, distributor, reseller
        // alert("Option selected with value: '" + selectedOptionValue + "'");
        if (selectedOptionValue == "distributor"){
            cmp.set("v.shipToAddresses", cmp.get("v.shipToAddressesDistributor"));
        } else if (selectedOptionValue == "reseller"){
            cmp.set("v.shipToAddresses", cmp.get("v.shipToAddressesReseller"));
        } else if (selectedOptionValue  == "account"){
            cmp.set("v.shipToAddresses", cmp.get("v.shipToAddressesAccount"));
        }
    },

    handleBillToOptionChange: function (cmp, event) {
        // This will contain the string of the "value" attribute of the selected option
        var selectedOptionValue = event.getParam("value");
        // the expected value is source of bill to address : account, distributor, reseller
        // alert("Option selected with value: '" + selectedOptionValue + "'");
        if (selectedOptionValue == "distributor"){
            cmp.set("v.billToAddresses", cmp.get("v.billToAddressesDistributor"));
        } else if (selectedOptionValue == "reseller"){
            cmp.set("v.billToAddresses", cmp.get("v.billToAddressesReseller"));
        } else if (selectedOptionValue  == "account"){
            cmp.set("v.billToAddresses", cmp.get("v.billToAddressesAccount"));
        }
    },

   updateShipToDetails : function (cmp, event) {
        var updateShipAction = cmp.get("c.UpdateShipDetails");
        updateShipAction.setParams({
            acctList : cmp.get("v.shipToContactDetails")
        });
        updateShipAction.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                alert('Success');
            }
            else{
                if(response.getError()[0].fieldErrors!=null)
                {

                  if(response.getError()[0].fieldErrors["Ship_To_Email__c"] !=null)
                  {
                    alert('Error : '+response.getError()[0].fieldErrors["Ship_To_Email__c"][0].message);
                  }
                  else if(response.getError()[0].fieldErrors["Ship_To_Contact__c"] !=null)
                  {
                    alert('Error : '+response.getError()[0].fieldErrors["Ship_To_Email__c"][0].message);
                  }
                }                
            }
        });
        $A.enqueueAction(updateShipAction);
    },

	updateBillToDetails : function (cmp, event) {
        var updateBillAction = cmp.get("c.UpdateBillDetails");
        updateBillAction.setParams({
            acctList : cmp.get("v.billToContactDetails")
        });
        updateBillAction.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                alert('Success');
            }
            else{
                alert('error'+response.getError());
            }
        });
        $A.enqueueAction(updateBillAction);
    },

    closeModal : function(component, event, helper) {

        $A.get("e.force:refreshView").fire();
        $A.get("e.force:closeQuickAction").fire();
       
    }
})