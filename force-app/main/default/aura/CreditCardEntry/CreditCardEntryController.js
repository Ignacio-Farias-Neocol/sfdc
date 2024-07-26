/**
 * Created by iyeung on 1/3/19.
 */
({


    doInit : function(cmp, event, helper) {

        var action = cmp.get("c.getCreditCardURL");
        action.setParams({
            recordId: cmp.get("v.recordId")
        });
        action.setCallback(this, function(response) {

            var state = response.getState();
            if (state === "SUCCESS") {

                var ctrlClass = response.getReturnValue() ;  // this is the dto itself
                try {

                    var status = ctrlClass.status;
                    cmp.set("v.success_message", ctrlClass.success_message);
                    cmp.set("v.failure_message", ctrlClass.failure_message);


                    if (status == 'SUCCESS'){
                        cmp.set("v.status", true);
                        var url = ctrlClass.url;
                        window.open(url);
                        // http://webdev.barracuda.com:81/dbfix/mesForm

                    } else {
                        cmp.set("v.status", false);
                    }

                } catch (e){
                    throw new Error("Fail to load URL. If problem persist, please contact the administrator.  " + e);
                }

            }  else if (state === "INCOMPLETE") {
                // do something
                cmp.set("v.status", false);
                cmp.set("v.failure_message", "Incomplete request. Please contact administrator.");
                console.log("Unhanded State : Incomplete");
            } else if (state === "ERROR") {

                cmp.set("v.status", false);
                var failure_message = "";
                console.log("Call back failed.");
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " +
                            errors[0].message);
                        failure_message += errors[0].message + "\n";
                    }
                } else {
                    console.log("Unknown error");
                }
            }  else {
                // do something
                cmp.set("v.status", false);
                cmp.set("v.failure_message", "Unknown request. Please contact administrator.");
                console.log('Unknown State: ' + state );
            }

        });
        $A.enqueueAction(action);

    }


})