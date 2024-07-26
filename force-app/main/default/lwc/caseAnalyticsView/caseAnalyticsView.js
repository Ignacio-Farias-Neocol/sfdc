import { LightningElement, track, api, wire } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import getCaseAnalytics from "@salesforce/apex/CaseAnalyticsContoller.getCaseAnalytics";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import {CurrentPageReference} from 'lightning/navigation';

export default class CaseAnalyticsView extends NavigationMixin(LightningElement) {

    @track moreRecords = false;
    @track state = {}
    @api recordId;
    agentTimeList;
    totalCaseTime = 0;
    selectedAgenDataObj;
    dataObj;
    
    @api customActions = [];
   
    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.recordId = currentPageReference.attributes.recordId;
        }
    }
    get hasRecords() {
        return this.state.records != null && this.state.records.length;
    }
    connectedCallback(){
        debugger;
        this.getCaseAnalyticsJS();
    }

    getCaseAnalyticsJS() {
        debugger;

        getCaseAnalytics({ recordId : this.recordId })
            .then(response => {
                const data = JSON.parse(response);
                this.dataObj  = data;
                let userIdTotalCaseTime = data.userIdTotalCaseTime;
                let userIds = Object.keys(userIdTotalCaseTime);
                let agentTimeList = [];
                for(let i=0;i<userIds.length;i++){
                    let minutesSeconds = userIdTotalCaseTime[userIds[i]] > 60 ? userIdTotalCaseTime[userIds[i]] % 60 : 0;
                    let hrMiutes = userIdTotalCaseTime[userIds[i]] > 3600 ? userIdTotalCaseTime[userIds[i]] % 3600 : 0;
                    let hrMin = hrMiutes > 60 ? (Math.floor(hrMiutes / 60)) : 0;
                    let hrMinSeconds = hrMiutes > 60 ? hrMiutes % 60 : 0;
                    
                    agentTimeList.push(
                        {
                            'Id' : userIds[i].split('#')[0],
                            'Name' : userIds[i].split('#')[1],
                            'Time' : userIdTotalCaseTime[userIds[i]] < 60 ? 
                                userIdTotalCaseTime[userIds[i]] + 'sec' : 
                                userIdTotalCaseTime[userIds[i]] < 3600 ?  (Math.floor(userIdTotalCaseTime[userIds[i]] / 60)) + 'min '+minutesSeconds + 'sec' : 
                                (Math.floor(userIdTotalCaseTime[userIds[i]] / 3600)) + 'hr ' + hrMin + 'min ' + hrMinSeconds + 'sec'
                        }
                    );
                }
                this.agentTimeList = agentTimeList;
                let minutesSeconds = data.totalCaseTime > 60 ? data.totalCaseTime % 60 : 0;
                let hrMiutes = data.totalCaseTime > 3600 ? data.totalCaseTime % 3600 : 0;
                let hrMin = hrMiutes > 60 ? (Math.floor(hrMiutes / 60)) : 0;
                let hrMinSeconds = hrMiutes > 60 ? hrMiutes % 60 : 0;

                this.totalCaseTime =  data.totalCaseTime < 60 ? 
                    data.totalCaseTime + 'sec' : 
                    data.totalCaseTime < 3600 ?  (Math.floor( data.totalCaseTime / 60)) + 'min '+minutesSeconds + 'sec' : 
                    (Math.floor( data.totalCaseTime / 3600)) + 'hr '+ hrMin + 'min ' + hrMinSeconds + 'sec'
            })
            .catch(error => {
                console.log(error);
            });
    }

    generateLinks(records) {
        records.forEach(record => {
            record.LinkName = '/' + record.Id
            for (const propertyName in record) {
                const propertyValue = record[propertyName];
                if (typeof propertyValue === 'object') {
                    const newValue = propertyValue.Id ? ('/' + propertyValue.Id) : null;
                    this.flattenStructure(record, propertyName + '_', propertyValue);
                    if (newValue !== null) {
                        record[propertyName + '_LinkName'] = newValue;
                    }
                }
            }
        });
    }

    handleAgentClick(event){
        let agentId = event.currentTarget.dataset.agentid;
        let userIdCaseAnalytics = this.dataObj.userIdCaseAnalytics;
        let selectedAgenDataList = userIdCaseAnalytics[agentId];
        let agentName = '';
        let agentTotalTime = 0;
        for(let i=0;i<selectedAgenDataList.length;i++){
            let selectedAgenData = selectedAgenDataList[i];
            agentName = selectedAgenData.User__r.Name;
            selectedAgenData.Name = agentName;
            agentTotalTime = agentTotalTime  + selectedAgenData.Total_Time_In_Seconds__c;
            selectedAgenData.Date = new Date(selectedAgenData.In_Time__c).toLocaleDateString();
            selectedAgenData.startTime = this.formatAMPM(new Date(selectedAgenData.In_Time__c));
            selectedAgenData.endTime = this.formatAMPM(new Date(selectedAgenData.Out_Time__c));
            let minutesSeconds = selectedAgenData.Total_Time_In_Seconds__c > 60 ? selectedAgenData.Total_Time_In_Seconds__c % 60 : 0;
            let hrMiutes = selectedAgenData.Total_Time_In_Seconds__c > 3600 ? selectedAgenData.Total_Time_In_Seconds__c % 3600 : 0;
            let hrMin = hrMiutes > 60 ? (Math.floor(hrMiutes / 60)) : 0;
            let hrMinSeconds = hrMiutes > 60 ? hrMiutes % 60 : 0;
            selectedAgenData.Time = 
                                selectedAgenData.Total_Time_In_Seconds__c < 60 ? 
                                selectedAgenData.Total_Time_In_Seconds__c + 'sec' : 
                                selectedAgenData.Total_Time_In_Seconds__c < 3600 ?  (Math.floor(selectedAgenData.Total_Time_In_Seconds__c / 60)) + 'min '+ minutesSeconds + 'sec' : 
                                (Math.floor(selectedAgenData.Total_Time_In_Seconds__c / 3600)) + 'hr ' + hrMin  + 'min ' + hrMinSeconds + 'sec';
        } 
        
        let minutesSeconds = agentTotalTime > 60 ? agentTotalTime % 60 : 0;
        let hrMiutes = agentTotalTime > 3600 ? agentTotalTime % 3600 : 0;
        let hrMin = hrMiutes > 60 ? (Math.floor(hrMiutes / 60)) : 0;
        let hrMinSeconds = hrMiutes > 60 ? hrMiutes % 60 : 0;
        this.selectedAgenDataObj = {
                                        'Name' : agentName,
                                        'agentTotalTime'  : agentTotalTime < 60 ? 
                                            agentTotalTime + 'sec' : 
                                            agentTotalTime < 3600 ?  (Math.floor(agentTotalTime / 60)) + 'min '+ minutesSeconds + 'sec' : 
                                            (Math.floor(agentTotalTime / 3600)) + 'hr ' + hrMin + 'min ' + hrMinSeconds + 'sec',
                                        'selectedAgenDataList' : selectedAgenDataList
                                   }
    }

    formatAMPM(date) {
        var hours = date.getHours();
        var minutes = date.getMinutes();
        var ampm = hours >= 12 ? 'pm' : 'am';
        hours = hours % 12;
        hours = hours ? hours : 12; // the hour '0' should be '12'
        minutes = minutes < 10 ? '0'+minutes : minutes;
        var strTime = hours + ':' + minutes + ' ' + ampm;
        return strTime;
    }

    handleRefershData(){
        this.getCaseAnalyticsJS();
    }

}