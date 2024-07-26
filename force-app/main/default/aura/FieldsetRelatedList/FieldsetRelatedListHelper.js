/**
 * Created by rsieve on 6/13/18.
 */

({

    fetchColumns: function(component){

        return new Promise( function(resolve, reject){
            //debugger;
            var fetchGridCols = component.get('c.fetchGridColumns');
            var relatedField = '';
            if (component.get('v.relatedField') != null && component.get('v.relatedField') != ''){
                relatedField = component.get('v.relatedField');
            } else if (component.get('v.relatedFieldAlt') != null &&  component.get('v.relatedFieldAlt') != ''){
                relatedField = component.get('v.relatedFieldAlt');
            }
            fetchGridCols.setParams({fieldFullName: relatedField, fieldSetName: component.get('v.fieldset')});
            fetchGridCols.setCallback(this, function(response){
                var state = response.getState();
                if(state == 'SUCCESS'){
                    //debugger;
                    resolve(response.getReturnValue());
                }else{
                    reject(response.getError());
                }
            });
            $A.enqueueAction(fetchGridCols);

        });
    },

    fetchData: function(component, helper){
        return new Promise( function(resolve, reject){
            //debugger;
            var fetchGridData = component.get('c.fetchData');
            var relatedField = '';
            console.log('relatedField:', component.get('v.relatedField'));
            console.log('relatedFieldAlt:', component.get('v.relatedFieldAlt') );

            if (component.get('v.relatedField') != null && component.get('v.relatedField') != ''){
                relatedField = component.get('v.relatedField');
            } else if (component.get('v.relatedFieldAlt') != null &&  component.get('v.relatedFieldAlt') != ''){
                relatedField = component.get('v.relatedFieldAlt');
            }
            console.log('chosen relatedField:', relatedField);
            var recId = component.get('v.recordId')?component.get('v.recordId'):component.get('v.explicitRecordId');
            fetchGridData.setParams({recordId: recId, 
                                     fieldFullName: relatedField,
                                     fieldSetName: component.get('v.fieldset'),
                                     addlFields: [component.get('v.groupBy')]});
            fetchGridData.setCallback(this, function(response){
                var state = response.getState();
                if(state == 'SUCCESS'){
                    resolve(response.getReturnValue());
                }else{
                    reject(response.getError());
                }
            });
            $A.enqueueAction(fetchGridData);

        });
    },

    processData: function(component, helper, gridConfig, data){
        //debugger;
        var gridDataGroups = {}, flatRecs = {};
        var recordId = component.get('v.recordId')?component.get('v.recordId'):component.get('v.explicitRecordId');
        var groupBy = component.get('v.groupBy');
        var keyField = component.get('v.keyField');
        var gridData = [];

        console.log('raw input data:', data);

        //Loop through the data - building groupings
        data.forEach(function(rec){

            //examine rec for related objects - flatten properties as needed
            var flatRec = helper.flatten(rec);
            for(var i=0, count=gridConfig.length; i<count; i++){
                if(gridConfig[i].type == 'url' && flatRec[gridConfig[i].fieldName]){
                    flatRec[gridConfig[i].fieldName] = '/' + flatRec[gridConfig[i].fieldName];
                }
            }
            console.log('rec_group:', rec[groupBy]);
            if(rec[groupBy] && gridDataGroups.hasOwnProperty(rec[groupBy])){
                gridDataGroups[rec[groupBy]].push(flatRec);
            }else if(rec[groupBy]){
                gridDataGroups[rec[groupBy]] = [flatRec];
            }
            flatRecs[rec[keyField]] = flatRec;
        });

        console.log('flatRecs:' ,  flatRecs);

        //debugger;
        //Loop though the data again - nesting the groupings
        data.forEach(function(rec){
            var flatRec = flatRecs[rec[keyField]];
            if(flatRecs[rec[groupBy]]){
                if(flatRecs[rec[groupBy]].hasOwnProperty('_children')){
                    flatRecs[rec[groupBy]]._children.push(flatRec);
                }else{
                    flatRecs[rec[groupBy]]._children = [flatRec];
                }
            }
        });
        console.log('flatRecs:' ,  flatRecs);

        //debugger;
        data.forEach(function(rec){
            //Look for a root, or this contextual record
            console.log('current record:' ,  rec);
            console.log('current rec[groupBy]:' ,  rec[groupBy]);
            console.log('current rec.Id:' ,  rec.Id);
            // IY 2019-03-10. add condition to look for root when the rec[groupby] = recordId
            if(!rec[groupBy] || rec.Id == recordId  || rec[groupBy] == recordId){

                var flatRec = flatRecs[rec[keyField]];
                if(gridDataGroups.hasOwnProperty(rec[keyField])){
                    flatRec._children = gridDataGroups[rec[keyField]];
                }

                console.log('pushing:' ,  flatRec);
                gridData.push(flatRec);
            }
        });
        return gridData;
    },

    flatten: function(data){
        var result = {};
        function recurse (cur, prop) {
            if (Object(cur) !== cur) {
                result[prop] = cur;
            } else if (Array.isArray(cur)) {
                for(var i=0, l=cur.length; i<l; i++)
                    recurse(cur[i], prop + "[" + i + "]");
                if (l == 0)
                    result[prop] = [];
            } else {
                var isEmpty = true;
                for (var p in cur) {
                    isEmpty = false;
                    recurse(cur[p], prop ? prop+"."+p : p);
                }
                if (isEmpty && prop)
                    result[prop] = {};
            }
        }
        recurse(data, "");
        console.log('flat result', result);
        return result;
    }

})