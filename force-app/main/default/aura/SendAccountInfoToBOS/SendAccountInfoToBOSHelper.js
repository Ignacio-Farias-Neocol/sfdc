({
    getEndpoint: function(component, resolve, reject) {

        let connectAction = component.get("c.getBosUrl");

        connectAction.setCallback(this, function(response){
            if (response.getState() === "SUCCESS") { 
                var results = response.getReturnValue()
                    .reduce((a,v) => { a[v.DeveloperName] = v; return a; }, {});
                var bosUrl = results.BOS_Partner_Account.Base_URL__c;
                
                component.set('v.endpoint', bosUrl);
            
                if(resolve) {
                    console.log('resolving getEndpoint');
                    resolve('getEndpoint succeeded');
                }
            }
            else {
                if(reject) {
                    console.log('rejecting getEndpoint');
                    reject(Error(response.getError()[0].message));
                }
            }
        });
        $A.enqueueAction(connectAction);
    },
    getData: function(component, resolve, reject) {


        let urlEncodedDataPairs = [];
        let urlEncodedData = "";
        let recordId = component.get("v.recordId");
        //let url = component.get("v.endpoint");

        //This is how the Javascript controller gets the function from the Apex controller
        let sendAction = component.get("c.getAccountInfo");

       //This sets the parameters of the Apex controller function
        sendAction.setParams({
            "id" : recordId
        });

        sendAction.setCallback(this, function(response) {

            //This saves the state of the response (successful or not).
            if (response.getState() === "SUCCESS") { 
               
                //This sets the object of the response in the component
                component.set("v.account", response.getReturnValue());
                    
                //Now that the object we got from the server is saved in the component,
                //we get it from the component to use its data.
                let account = component.get("v.account");

                // Turn the data object into an array of URL-encoded key/value pairs.
                if(typeof account.Name !== 'undefined')
                   urlEncodedDataPairs.push("account_name" + '=' + encodeURIComponent(account.Name));
                if(typeof account.Bill_To_Contact__c !== 'undefined')
                   urlEncodedDataPairs.push("bill_contact" + '=' + encodeURIComponent(account.Bill_To_Contact__c));
                if(typeof account.Ship_To_Contact__c !== 'undefined')
                   urlEncodedDataPairs.push("ship_contact" + '=' + encodeURIComponent(account.Ship_To_Contact__c));
                if(typeof account.ShippingStreet !== 'undefined')
                    urlEncodedDataPairs.push("ship_street" + '=' + encodeURIComponent(account.ShippingStreet));
                if(typeof account.ShippingCity !== 'undefined')
                   urlEncodedDataPairs.push("ship_city" + '=' + encodeURIComponent(account.ShippingCity));
                if(typeof account.ShippingState !== 'undefined')
                   urlEncodedDataPairs.push("ship_state" + '=' + encodeURIComponent(account.ShippingStateCode));
                if(typeof account.ShippingPostalCode !== 'undefined')
                   urlEncodedDataPairs.push("ship_pcode" + '=' + encodeURIComponent(account.ShippingPostalCode));
                if(typeof account.ShippingCountry !== 'undefined')
                   urlEncodedDataPairs.push("ship_country" + '=' + encodeURIComponent(account.ShippingCountryCode));
                if(typeof account.BillingStreet !== 'undefined')
                   urlEncodedDataPairs.push("bill_street" + '=' + encodeURIComponent(account.BillingStreet));
                if(typeof account.BillingCity !== 'undefined')
                   urlEncodedDataPairs.push("bill_city" + '=' + encodeURIComponent(account.BillingCity));
                if(typeof account.BillingState !== 'undefined')
                   urlEncodedDataPairs.push("bill_state" + '=' + encodeURIComponent(account.BillingStateCode));
                if(typeof account.BillingPostalCode !== 'undefined')
                   urlEncodedDataPairs.push("bill_pcode" + '=' + encodeURIComponent(account.BillingPostalCode));
                if(typeof account.BillingCountry !== 'undefined')
                   urlEncodedDataPairs.push("bill_country" + '=' + encodeURIComponent(account.BillingCountryCode));
                if(typeof account.Bill_To_Email__c !== 'undefined')
                   urlEncodedDataPairs.push("bill_contact_email" + '=' + encodeURIComponent(account.Bill_To_Email__c));
                if(typeof account.Ship_To_Email__c !== 'undefined')
                   urlEncodedDataPairs.push("ship_contact_email" + '=' + encodeURIComponent(account.Ship_To_Email__c));
                if(typeof account.Id !== 'undefined')
                   urlEncodedDataPairs.push("account_id" + '=' + encodeURIComponent(account.Id));
                if(typeof account.Phone !== 'undefined')
                   urlEncodedDataPairs.push("bill_phone" + '=' + encodeURIComponent(account.Phone));
                if(typeof account.Type !== 'undefined')
                   urlEncodedDataPairs.push("type" + '=' + encodeURIComponent(account.Type));
                if(typeof account.VAT_Number__c !== 'undefined')
                   urlEncodedDataPairs.push("vat_id" + '=' + encodeURIComponent(account.VAT_Number__c));
                if(typeof account.Tax_Exempt_Number__c !== 'undefined')
                   urlEncodedDataPairs.push("tax_ex" + '=' + encodeURIComponent(account.Tax_Exempt_Number__c));
                if(typeof account.Portal_Account_ID__c !== 'undefined')
                   urlEncodedDataPairs.push("portal_id" + '=' + encodeURIComponent(account.Portal_Account_ID__c));
                if(typeof account.Partner_Number__c !== 'undefined')
                   urlEncodedDataPairs.push("partner_number" + '=' + encodeURIComponent(account.Partner_Number__c));
                if(typeof account.Requestor_Buyer__c !== 'undefined')
                   urlEncodedDataPairs.push("buyer" + '=' + encodeURIComponent(account.Requestor_Buyer__c));
                if(typeof account.Requestor_Buyer_email__c !== 'undefined')
                   urlEncodedDataPairs.push("buyer_email" + '=' + encodeURIComponent(account.Requestor_Buyer_email__c));
                if(typeof account.Account_Status__c !== 'undefined')
                   urlEncodedDataPairs.push("account_status" + '=' + encodeURIComponent(account.Account_Status__c));
                if(typeof account.Payment__Terms__c !== 'undefined')
                   urlEncodedDataPairs.push("payment_terms" + '=' + encodeURIComponent(account.Payment__Terms__c));

                urlEncodedDataPairs.push("option" + '=' + "create_or_update_account");
                urlEncodedDataPairs.push("is_apollo" + '=' + 1);

                // Combine the pairs into a single string and replace all %-encoded spaces to 
                // the '+' character; matches the behaviour of browser form submissions.
                urlEncodedData = urlEncodedDataPairs.join('&').replace(/%20/g, '+');

                component.set('v.urlEncodedData', urlEncodedData);

                if(resolve) {
                    console.log('resolving getData');
                    resolve('getData succeeded');
                }

            } else if(reject) {
                console.log('rejecting saveResponse');
                let errors = response.getError();
                if(errors){
                    if(errors[0] && errors[0].message){
                        console.log('Error Message: ' + errors[0].message);
                        reject(Error(errors[0].message));
                    }else{  
                        console.log('Unknown error');
                        reject(Error('Unknown error'));
                    }     
                }
            }
        });
        //This executes the function in the APEX controller
        $A.enqueueAction(sendAction);  
    },
    sendRequest: function(component) {
        let url = component.get("v.endpoint");
        let urlEncodedData = component.get("v.urlEncodedData");
        let xhr = new XMLHttpRequest();

        let responseAction = component.get("c.updateSharedPartnerAccount");
        let accountId = component.get('v.recordId');
        /*
        // Define what happens on successful data submission
        xhr.addEventListener('load', function(event) {
            var resultsToast = $A.get("e.force:showToast");
            resultsToast.setParams({
                "title" : "Success",
                "message" : "Yeah! Data sent and response loaded.",
                "type" : "success"
            });
            resultsToast.fire();
        });
        */
        // Define what happens on failed data submission
        xhr.addEventListener("error", function(event) {
            console.log("Oops! An error occurs while loading account data\nPlease contact your Salesforce Administrator.");
            let resultsToast = $A.get("e.force:showToast");
            resultsToast.setParams({
                "title" : "Error",
                "message" : "Oops! An error occurs while loading account data",
                "type" : "error"
            });
            resultsToast.fire();
        });

        xhr.onreadystatechange = $A.getCallback(function(e) {
            if (xhr.readyState === 4) {
                if (this.status === 200) {
                    
                    let result = JSON.parse(this.responseText);
                    console.log("Response: " + JSON.stringify(result));
                    
                    component.set('v.result', JSON.stringify(result));

                    responseAction.setParams({
                        "accountId" : accountId,
                        "responseJson" : JSON.stringify(result)
                    });
                   
                    responseAction.setCallback(this, function(response){
                        let state = response.getState();
                        if(state === "SUCCESS" && (result.status === 0 || result.status === 1)){

                            let title = (result.status === 0) ? "Error" : "Success";
                            let type = (result.status === 0) ? "error" : "success";
                        
                            let responseToast = $A.get("e.force:showToast");
                            responseToast.setParams({
                                "title" : title,
                                "message" : "Yeah! "+result.message,
                                "type" : type
                            });
                            responseToast.fire();
                        }else{
                            let errors = response.getError();
                            if(errors){
                                if(errors[0] && errors[0].message){
                                    console.log("Error: " + errors[0].message);
                                }else{  
                                    console.log("Unknown error");
                                 
                                }
                            }
                        }
                    }); 
                    $A.enqueueAction(responseAction);

                }else{
                    let error = '';
                    if(this.status === 0) {
                        error = 'Request has been terminated\nPossible causes: the network is offline, Origin is not allowed by Access-Control-Allow-Origin, the page is being unloaded, etc.';
                    }else{
                        error = this.statusText;
                    }
                    console.log("Error Message: " + error);
                }
            }
        });

        xhr.ontimeout = function () {
            console.log('request timeout'); 
            reject('request timeout');
        }
        // Set up our request
        xhr.open('POST', url, true);
        xhr.withCredentials = true;

        // Add the required HTTP header for form data POST requests
        xhr.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
        
        // Finally, send our data.
        xhr.send(urlEncodedData);
        //});

        $A.get("e.force:closeQuickAction").fire();
    },
    sendData: function(component, resolve, reject) {
        let url = component.get("v.endpoint");
        let urlEncodedData = component.get("v.urlEncodedData");
        let xhr = new XMLHttpRequest();

        let responseAction = component.get("c.updateSharedPartnerAccount");
        let accountId = component.get('v.recordId');
        
        xhr.timeout = 50000;

        // Define what happens on successful data submission
        xhr.addEventListener('load', function(event) {
            var resultsToast = $A.get("e.force:showToast");
            resultsToast.setParams({
                "title" : "Success",
                "message" : "Yeah! Data sent and response loaded.",
                "type" : "success"
            });
            resultsToast.fire();
        });
        
        // Define what happens on failed data submission
        xhr.addEventListener("error", function(event) {
            console.log("Oops! An error occurs while loading account data\nPlease contact your Salesforce Administrator.");
            let resultsToast = $A.get("e.force:showToast");
            resultsToast.setParams({
                "title" : "Error",
                "message" : "Oops! An error occurs while loading account data",
                "type" : "error"
            });
            resultsToast.fire();
        });

        xhr.onreadystatechange = $A.getCallback(function(e) {
            if (xhr.readyState === 4) {
                if (this.status === 200) {
                    let result = JSON.parse(this.responseText);
                    //alert("Response: status=" + reponseObj.status + ", account=" + reponseObj.bos_account_id+", message=" + reponseObj.message);
                    component.set('v.result', JSON.stringify(result));
                    
                    ////
                    //let responseAction = component.get("c.updateSharedPartnerAccount");
                    responseAction.setParams({
                        "accountId" : accountId,
                        "responseJson" : JSON.stringify(result)
                    });
                   
                    responseAction.setCallback(this, function(response){
                        let state = response.getState();
                        if(state === "SUCCESS" && (result.status === 0 || result.status === 1)){

                            if(resolve) {
                                console.log('resolving saveResult');
                                resolve('saveResult succeeded');

                                let title = (result.status === 0) ? "Error" : "Success";
                                let type = (result.status === 0) ? "error" : "success";
                            
                                let responseToast = $A.get("e.force:showToast");
                                responseToast.setParams({
                                    "title" : title,
                                    "message" : "Yeah! "+result.message,
                                    "type" : type
                                });
                                responseToast.fire();
                            }
                        }else{
                            if(reject) {
                                console.log('rejecting saveResponse');
                                let errors = response.getError();
                                if(errors){
                                    if(errors[0] && errors[0].message){
                                        console.log("Error Message: " + errors[0].message);
                                        reject(Error(errors[0].message));
                                    }else{  
                                        console.log("Unknown error");
                                        reject(Error("Unknown error"));
                                    }
                                }
                            }
                        }
                    }); 
                    
                    console.log('Queueing responseAction');
                    $A.enqueueAction(responseAction);
                    ////
                    
                    console.log("Response: " + JSON.stringify(result));
                    resolve();
                }else{
                    let error = '';
                    if(this.status === 0) {
                        error = 'Request has been terminated\nPossible causes: the network is offline, Origin is not allowed by Access-Control-Allow-Origin, the page is being unloaded, etc.';
                    }else{
                        error = this.statusText;
                    }
                    console.log("Error Message: " + error);
                    reject(error);
                }
            }
        });

        xhr.ontimeout = function () {
            console.log('request timeout'); 
            reject('request timeout');
        }
        // Set up our request
        xhr.open('POST', url, true);
        xhr.withCredentials = true;

        // Add the required HTTP header for form data POST requests
        xhr.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
        
        // Finally, send our data.
        xhr.send(urlEncodedData);
        //});

        $A.get("e.force:closeQuickAction").fire();
    },
    makeRequest: function(component, resolve, reject) {

        let url = component.get("v.endpoint");
        let urlEncodedData = component.get("v.urlEncodedData");
        let xhr = new XMLHttpRequest();

        let responseAction = component.get("c.updateSharedPartnerAccount");
        let accountId = component.get('v.recordId');
        
        xhr.timeout = 50000;

        // Define what happens on failed data submission
        xhr.addEventListener("error", function(event) {
            console.log("Oops! An error occurs while loading account data\nPlease contact your Salesforce Administrator.");
            let resultsToast = $A.get("e.force:showToast");
            resultsToast.setParams({
                "title" : "Error",
                "message" : "Oops! An error occurs while loading account data",
                "type" : "error"
            });
            resultsToast.fire();
        });

        return new Promise(function (resolve, reject) {
            xhr.onreadystatechange = $A.getCallback(function(e) {
                if (xhr.readyState === 4) {
                    if (this.status === 200) {
                        let result = JSON.parse(this.responseText);
                        //alert("Response: status=" + reponseObj.status + ", account=" + reponseObj.bos_account_id+", message=" + reponseObj.message);
                        component.set('v.result', JSON.stringify(result));
                        
                        console.log("Response: " + JSON.stringify(result));
                        resolve(JSON.stringify(result));
                    }else{
                        let error = '';
                        if(this.status === 0) {
                            error = 'Request has been terminated\nPossible causes: the network is offline, Origin is not allowed by Access-Control-Allow-Origin, the page is being unloaded, etc.';
                        }else{
                            error = this.statusText;
                        }
                        console.log('Status: ' + this.status + ' Error: ' + error);
                        reject(error);
                    }
                }
            });

            xhr.ontimeout = function () {
                console.log('request timeout'); 
                reject('request timeout');
            }
            // Set up our request
            xhr.open('POST', url, true);
            xhr.withCredentials = true;

            // Add the required HTTP header for form data POST requests
            xhr.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
            
            // Finally, send our data.
            xhr.send(urlEncodedData);
            //});

            $A.get("e.force:closeQuickAction").fire();
        });
    },
    saveResponse: function(component, responseJson) {
        
        console.log('Saving response: '+responseJson);
        let responseAction = component.get("c.updateSharedPartnerAccount");
        let result = JSON.parse(responseJson);

        responseAction.setParams({
            "accountId" : component.get('v.recordId'),
            "responseJson" : responseJson
        });

        responseAction.setCallback(this, function(response){
            let state = response.getState();
            if(state === "SUCCESS" && (result.status === 0 || result.status === 1)){

                let title = (result.status === 0) ? "Error" : "Success";
                let type = (result.status === 0) ? "error" : "success";
            
                let responseToast = $A.get("e.force:showToast");
                responseToast.setParams({
                    "title" : title,
                    "message" : "Yeah! "+result.message,
                    "type" : type
                });
                responseToast.fire();
            }
            else{
                console.log('rejecting saveResponse');
                let errors = response.getError();
                if(errors){
                    if(errors[0] && errors[0].message){
                        console.log("Error: " + errors[0].message);
                    }else{  
                        console.log("Unknown error");
                    }
                }
            }
        });
        $A.enqueueAction(resultAction);
    },
    helperFunctionAsPromise : function(component, helperFunction) {
        return new Promise($A.getCallback(function(resolve, reject) {
            helperFunction(component, resolve, reject);
        }));
    },
	sendAccountToBOS: function(component, url) {
		
  		var xhr = new XMLHttpRequest();
        var urlEncodedDataPairs = [];
        var urlEncodedData = "";
        var recordId = component.get("v.recordId");
        
        //This is how the Javascript controller gets the function from the Apex controller
        var action = component.get("c.getAccountInfo");

        var saveResponseObj = component.get("c.updateSharedPartnerAccount");

		//This sets the parameters of the Apex controller function
        action.setParams({
            "id" : recordId
        });

        action.setCallback(this, function(response) {

        	//This saves the state of the response (successful or not).
           	var state = response.getState();
            if(state === "SUCCESS"){

                //This sets the object of the response in the component
               	component.set("v.account", response.getReturnValue());
                    
                //Now that the object we got from the server is saved in the component,
                //we get it from the component to use its data.
               	var account = component.get("v.account");
                
                //alert(JSON.stringify(account));

				// Turn the data object into an array of URL-encoded key/value pairs.
                if(typeof account.Name !== 'undefined')
            	   urlEncodedDataPairs.push("account_name" + '=' + encodeURIComponent(account.Name));
                if(typeof account.Bill_To_Contact__c !== 'undefined')
            	   urlEncodedDataPairs.push("bill_contact" + '=' + encodeURIComponent(account.Bill_To_Contact__c));
                if(typeof account.Ship_To_Contact__c !== 'undefined')
            	   urlEncodedDataPairs.push("ship_contact" + '=' + encodeURIComponent(account.Ship_To_Contact__c));
            	if(typeof account.ShippingStreet !== 'undefined')
                    urlEncodedDataPairs.push("ship_street" + '=' + encodeURIComponent(account.ShippingStreet));
                if(typeof account.ShippingCity !== 'undefined')
            	   urlEncodedDataPairs.push("ship_city" + '=' + encodeURIComponent(account.ShippingCity));
                if(typeof account.ShippingStateCode !== 'undefined')
                   urlEncodedDataPairs.push("ship_state" + '=' + encodeURIComponent(account.ShippingStateCode));
                else if(typeof account.ShippingState !== 'undefined')
                   urlEncodedDataPairs.push("ship_state" + '=' + encodeURIComponent(account.ShippingState));
                if(typeof account.ShippingPostalCode !== 'undefined')
            	   urlEncodedDataPairs.push("ship_pcode" + '=' + encodeURIComponent(account.ShippingPostalCode));
                if(typeof account.ShippingCountryCode !== 'undefined')
            	   urlEncodedDataPairs.push("ship_country" + '=' + encodeURIComponent(account.ShippingCountryCode));
                if(typeof account.BillingStreet !== 'undefined')
            	   urlEncodedDataPairs.push("bill_street" + '=' + encodeURIComponent(account.BillingStreet));
                if(typeof account.BillingCity !== 'undefined')
            	   urlEncodedDataPairs.push("bill_city" + '=' + encodeURIComponent(account.BillingCity));
                if(typeof account.BillingStateCode !== 'undefined')
                   urlEncodedDataPairs.push("bill_state" + '=' + encodeURIComponent(account.BillingStateCode));
                else if (typeof account.BillingState !== 'undefined')
                   urlEncodedDataPairs.push("bill_state" + '=' + encodeURIComponent(account.BillingState));
                if(typeof account.BillingPostalCode !== 'undefined')
            	   urlEncodedDataPairs.push("bill_pcode" + '=' + encodeURIComponent(account.BillingPostalCode));
                if(typeof account.BillingCountryCode !== 'undefined')
            	   urlEncodedDataPairs.push("bill_country" + '=' + encodeURIComponent(account.BillingCountryCode));
                if(typeof account.Bill_To_Email__c !== 'undefined')
            	   urlEncodedDataPairs.push("bill_contact_email" + '=' + encodeURIComponent(account.Bill_To_Email__c));
                if(typeof account.Ship_To_Email__c !== 'undefined')
            	   urlEncodedDataPairs.push("ship_contact_email" + '=' + encodeURIComponent(account.Ship_To_Email__c));
                if(typeof account.Id !== 'undefined')
            	   urlEncodedDataPairs.push("account_id" + '=' + encodeURIComponent(account.Id));
                if(typeof account.Phone !== 'undefined')
            	   urlEncodedDataPairs.push("bill_phone" + '=' + encodeURIComponent(account.Phone));
                if(typeof account.Type !== 'undefined')
            	   urlEncodedDataPairs.push("type" + '=' + encodeURIComponent(account.Type));
                if(typeof account.VAT_Number__c !== 'undefined')
            	   urlEncodedDataPairs.push("vat_id" + '=' + encodeURIComponent(account.VAT_Number__c));
                if(typeof account.Tax_Exempt_Number__c !== 'undefined')
            	   urlEncodedDataPairs.push("tax_ex" + '=' + encodeURIComponent(account.Tax_Exempt_Number__c));
                if(typeof account.Portal_Account_ID__c !== 'undefined')
            	   urlEncodedDataPairs.push("portal_id" + '=' + encodeURIComponent(account.Portal_Account_ID__c));
                if(typeof account.Partner_Number__c !== 'undefined')
            	   urlEncodedDataPairs.push("partner_number" + '=' + encodeURIComponent(account.Partner_Number__c));
                if(typeof account.Requestor_Buyer__c !== 'undefined')
            	   urlEncodedDataPairs.push("buyer" + '=' + encodeURIComponent(account.Requestor_Buyer__c));
                if(typeof account.Requestor_Buyer_email__c !== 'undefined')
            	   urlEncodedDataPairs.push("buyer_email" + '=' + encodeURIComponent(account.Requestor_Buyer_email__c));
                if(typeof account.Account_Status__c !== 'undefined')
            	   urlEncodedDataPairs.push("account_status" + '=' + encodeURIComponent(account.Account_Status__c));
                if(typeof account.Payment__Terms__c !== 'undefined')
            	   urlEncodedDataPairs.push("payment_terms" + '=' + encodeURIComponent(account.Payment__Terms__c));

                urlEncodedDataPairs.push("option" + '=' + "create_or_update_account");
                urlEncodedDataPairs.push("is_apollo" + '=' + 1);

                try {
                    // Combine the pairs into a single string and replace all %-encoded spaces to 
                    // the '+' character; matches the behaviour of browser form submissions.
                    urlEncodedData = urlEncodedDataPairs.join('&').replace(/%20/g, '+');

                    xhr.addEventListener("error", function(event) {

                        console.log("Oops! An error occurs while loading account data");
                        let resultsToast = $A.get("e.force:showToast");
                        resultsToast.setParams({
                            "title" : "Error",
                            "message" : "Oops! An error occurs while loading account data",
                            "type" : "error"
                        });
                        resultsToast.fire();
                    });

                    // Define what happens on successful data submission
                    xhr.addEventListener('load', function(event) {
                        //alert('Yeah! Data sent and response loaded.');
                        var resultsToast = $A.get("e.force:showToast");
                        resultsToast.setParams({
                            "title" : "Success",
                            "message" : "Yeah! Data sent and response loaded.",
                            "type" : "success"
                        });
                        resultsToast.fire();
                    });

                    xhr.onreadystatechange = function() {
                        if (this.readyState == 4 && this.status == 200) {
                            console.log("Response: " + this.responseText);
                            //alert("Response: " + this.responseText);
                        }
                    };
                    
                    // Set up our request
                    xhr.open('POST', url, true);
                    xhr.withCredentials = true;

                    // Add the required HTTP header for form data POST requests
                    xhr.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
                    //xhr.setRequestHeader('Authorization', 'Basic ' + btoa(username+':'+password));
                    
                    // Finally, send our data.
                    xhr.send(urlEncodedData);
                }
                catch(e){ 
                    console.log("Error Message: " + e.message);
                }

                $A.get("e.force:closeQuickAction").fire();

            } else {
            	//This is a common way to handle possible errors.
            	var errors = response.getError();
                if(errors){
                    if(errors[0] && errors[0].message){
                        console.log("Error Message: " + errors[0].message);
                    }else{
                        console.log("Unknown error");
                    }
                }
            }
        });
        //This executes the function in the APEX controller
        $A.enqueueAction(action);
        
    },
    connectToBOS: function(component, event, helper) {

        var action = component.get("c.getBosUrl");

        action.setCallback(this, function(response){
            if (response.getState() === "SUCCESS") { 
                var results = response.getReturnValue()
                .reduce((a,v) => { a[v.DeveloperName] = v; return a; }, {});
                var bosUrl = results.BOS_Partner_Account.Base_URL__c;
                //alert('BOS URL: '+ bosUrl);
                this.sendAccountToBOS(component, bosUrl);
            }
            else if (response.getState() === "ERROR") {
                $A.log("Errors", response.getError());
            }
        });
        $A.enqueueAction(action);
    },
    saveResultBOS: function(component, recordId, result) {

        let saveResult = component.get("c.updateSharedPartnerAccount");
        saveResult.setParams({
            "accountId" : recordId,
            "responseJson" : JSON.stringify(result)
        });
      
        saveResult.setCallback(this, function(response){
            var state = response.getState();
            if(state === "SUCCESS" && (result.status === 0 || result.status === 1)){
                
                let title = (result.status === 0) ? "Error" : "Success";
                let type = (result.status === 0) ? "error" : "success";
                //console.log("BOS result updated successfully...");
                let resultsToast = $A.get("e.force:showToast");
                resultsToast.setParams({
                    "title" : title,
                    "message" : "Yeah! "+result.message,
                    "type" : type
                });
                resultsToast.fire();
            }else{
                var errors = response.getError();
                if(errors){
                    if(errors[0] && errors[0].message){
                        console.log("Error Message: " + errors[0].message);
                    }else{  
                        console.log("Unknown error");
                    }
                }
            }
        });
        $A.enqueueAction(saveResult);
    }
})