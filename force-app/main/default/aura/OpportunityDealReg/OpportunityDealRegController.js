/**
 * Created by iyeung on 1/3/19.
 */
/*
({


    doInit : function(cmp, event, helper) {

        var action = cmp.get("c.getDealRegURL");
        action.setParams({
            recordId: cmp.get("v.recordId")
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var url = response.getReturnValue() ;  // url string
                window.open(url);
                // window.open('https://www.barracuda.com/web_api/create_dealreg_from_sf/{!Opportunity.Id}?uname=webprod&pswd=14273371c52b0b162c5748169c69ad17');
            }
        });
        $A.enqueueAction(action);

    }


})
*/

({


    doInit : function(cmp, event, helper) {


    },

    /**
     * Event which fires when start button is clicked in prechat.
     *
     * @param cmp - The component for this state.
     * @param evt - The Aura event.
     * @param hlp - The helper for this state.
     */
    handleSubmitButtonClick: function(cmp, event, helper) {


        // reset when there is an error
        cmp.set("v.isDataLoading", true);

        var action = cmp.get("c.getDealRegURL");
        action.setParams({
            recordId: cmp.get("v.recordId"),
            comments: cmp.get("v.approval_comments")
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

                        // 2019-03-10: change to submit approval and use trigger to send deal reg to web team
                        // var url = ctrlClass.url;
                        // window.open(url);
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

            // reset when there is an error
            cmp.set("v.isDataLoading", false);


        });

        // Disable the button to prevent double check
        // var button = event.getSource();
        // button.set('v.disabled',true);

        $A.enqueueAction(action);
    }


})