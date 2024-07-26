/**
 * Created by iyeung on 2019-08-07.
 */

({

    // load all the data for attributes in parent component
    loadAllData: function (cmp, event) {

        var action = cmp.get("c.getSerialHistory");
        action.setParams({
            recordId: cmp.get("v.recordId")
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {

                console.log("state : success");

                var historyDTOJSON =  response.getReturnValue();
                var historyDTOObj = JSON.parse(historyDTOJSON)  ;
                // var historyDTO = response.getReturnValue();
                // var historyDTOStr = JSON.stringify(historyDTO);
                console.log("historyDTOStr :" + historyDTOJSON);
                console.log("historyDTO :" + historyDTOObj);

                try {
                    cmp.set("v.serialHistory", historyDTOObj);

                } catch (e){
                    throw new Error("Fail to serial history. If problem persist, please contact the administrator.  " + e);
                }

            }  else if (state === "INCOMPLETE") {
                // do something
                console.log("Unhanded State : Incomplete");
            } else if (state === "ERROR") {
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
                console.log('Unknown State: ' + state );
            }
        });
        $A.enqueueAction(action);
    }


});