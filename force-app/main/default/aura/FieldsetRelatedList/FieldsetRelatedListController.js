/**
 * Created by rsieve on 6/13/18.
 */

({
    init: function(component, event, helper){

        console.log('init');
        console.log('fieldSet: ' + component.get('v.fieldset'));
        console.log('recordId: ' + component.get('v.recordId'));
        console.log('ExrecordId: ' + component.get('v.explicitRecordId'));
        console.log('objName: ' + component.get('v.sObjectName'));

        var errHandle = function(err){
            console.log('err', err)
        };
		var promises = [helper.fetchColumns(component), helper.fetchData(component, helper)];
        Promise.all(promises)
        .then( function(responses){
            component.set('v.gridColumns', JSON.parse(JSON.stringify(responses[0])));
            console.log('raw return data:', responses[1]);
            var data = helper.processData(component, helper, component.get('v.gridColumns'), responses[1]);
            //debugger;
            component.set('v.gridData', data);
            console.log('keyfield:', component.get('v.keyField'));
            console.log('gridColumns:', component.get('v.gridColumns'));
            console.log('gridData:', component.get('v.gridData'));
        }, errHandle);
        /*
        helper.fetchColumns(component)
            .then( function(res){
                component.set('v.gridColumns', JSON.parse(JSON.stringify(res)));
                return helper.fetchData(component, helper);
            }, errHandle)
            .then( function(res){
                var data = helper.processData(component, helper, component.get('v.gridColumns'), res);
                //debugger;
                component.set('v.gridData', data);
                console.log('keyfield', component.get('v.keyField'));
                console.log('gridColumns', component.get('v.gridColumns'));
                console.log('gridData', component.get('v.gridData'));
            }, errHandle);
       */
    }

})