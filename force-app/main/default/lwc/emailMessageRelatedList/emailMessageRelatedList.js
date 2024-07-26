import { LightningElement, track, api, wire } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import RelatedListHelper from "./emailMessageRelatedListHelper";
import {loadStyle} from 'lightning/platformResourceLoader';
import relatedListResource from '@salesforce/resourceUrl/relatedListResource';
import initDataMethod from "@salesforce/apex/EmailMessageRelatedListController.initData";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import {CurrentPageReference} from 'lightning/navigation';

export default class EmailMessageRelatedList extends NavigationMixin(LightningElement) {

    @track moreRecords = false;
    @track state = {}
    @api sobjectApiName = 'EmailMessage';
    @api relatedFieldApiName = 'RelatedToId';
    @api numberOfRecords = 1000;
    @api sortedBy = 'MessageDate';
    @api sortedDirection = "DESC";
    @api rowActionHandler;
    @api fields = 'Subject,FromAddress,TextBody,MessageDate';
    @api columns = 
        [
            { label: 'Subject', fieldName: 'Subject', type: 'text' },
            { label: 'From Address', fieldName: 'FromAddress', type: 'text', cellAttributes: { alignment: 'left' }  },
            { label: 'Text Body', fieldName: 'TextBody', type: "text" , cellAttributes: { alignment: 'left' }},
            { label: 'Message Date', fieldName: 'MessageDate', type: "date",
                typeAttributes:{
                    year: "numeric",
                    month: "2-digit",
                    day: "2-digit",
                    hour: "2-digit",
                    minute: "2-digit"
                }, cellAttributes: { alignment: 'left' } }
        ];
    @api customActions = [];
    helper = new RelatedListHelper();
    renderedCallback() {
        loadStyle(this, relatedListResource + '/relatedList.css')
    }

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.recordId = currentPageReference.attributes.recordId;
        }
    }

    @api
    get recordId() {
        return this.state.recordId;
    }

    set recordId(value) {
        if(this.recordId){
            return;
        }
        this.state.recordId = value;
        this.init();
    }
    get hasRecords() {
        return this.state.records != null && this.state.records.length;
    }
    connectedCallback(){
        debugger;
        //this.init();
    }

    init() {
        this.state.showRelatedList = this.recordId != null;
        if (! (this.recordId
            && this.sobjectApiName
            && this.relatedFieldApiName
            && this.fields
            && this.columns)) {
            this.state.records = [];
            return;
        }

        this.state.fields = this.fields
        this.state.relatedFieldApiName= this.relatedFieldApiName
        this.state.recordId= this.recordId
        this.state.numberOfRecords= this.numberOfRecords
        this.state.sobjectApiName= this.sobjectApiName
        this.state.sortedBy= this.sortedBy
        this.state.sortedDirection= this.sortedDirection
        this.state.customActions= this.customActions
        this.fetchData(this.state);
        
    }

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;

        if (this.rowActionHandler) {
            this.rowActionHandler.call()
        } else {
            switch (actionName) {
                case "delete":
                    this.handleDeleteRecord(row);
                    break;
                case "edit":
                    this.handleEditRecord(row);
                    break;
                default:
            }
        }
    }

    handleGotoRelatedList() {
        this[NavigationMixin.Navigate]({
            type: "standard__recordRelationshipPage",
            attributes: {
                recordId: this.recordId,
                relationshipApiName: this.state.parentRelationshipApiName,
                actionName: "view",
                objectApiName: this.sobjectApiName
            }
        });
    }

    handleCreateRecord() {
        const newEditPopup = this.template.querySelector("c-related-list-new-edit-popup");
        newEditPopup.recordId = null
        newEditPopup.recordName = null        
        newEditPopup.sobjectApiName = this.sobjectApiName;
        newEditPopup.sobjectLabel = this.state.sobjectLabel;
        newEditPopup.show();
    }

    handleEditRecord(row) {
        const newEditPopup = this.template.querySelector("c-related-list-new-edit-popup");
        newEditPopup.recordId = row.Id;
        newEditPopup.recordName = row.Name;
        newEditPopup.sobjectApiName = this.sobjectApiName;
        newEditPopup.sobjectLabel = this.state.sobjectLabel;
        newEditPopup.show();
    }

    handleDeleteRecord(row) {
        const newEditPopup = this.template.querySelector("c-related-list-delete-popup");
        newEditPopup.recordId = row.Id;
        newEditPopup.recordName = row.Name;
        newEditPopup.sobjectLabel = this.state.sobjectLabel;
        newEditPopup.show();
    }

    handleRefreshData() {
        this.init();
    }

    fetchData(state) {
        debugger;
        let jsonData = Object.assign({}, state)
        jsonData.numberOfRecords = state.numberOfRecords + 1
        jsonData = JSON.stringify(jsonData)
        initDataMethod({ jsonData })
            .then(response => {
                const data1 = JSON.parse(response)
                const data = this.processData(data1, state);
                //this.state.records = data.records;
                if(data.records.length > 2){
                    this.moreRecords = true;
                }
                this.state.allRecords = data.records;
                this.state.iconName = data.iconName;
                this.state.sobjectLabel = data.sobjectLabel;
                this.state.sobjectLabelPlural = data.sobjectLabelPlural;
                this.state.title = data.title;
                this.state.parentRelationshipApiName = data.parentRelationshipApiName;
                this.state.columns = this.initColumnsWithActions(this.columns, this.customActions);
                this.setRecordsViewAll();
            })
            .catch(error => {
                console.log(error);
            });
    }

    setRecordsViewAll(){
        if(this.isViewAllOn){
            this.state.records = this.state.allRecords;
        }else{
            const records = this.state.allRecords.slice(0, 2);
            this.state.records = records;
        }
    }

    processData(data, state){
        const records = data.records;
        this.generateLinks(records)
        if (records.length > state.numberOfRecords) {
            records.pop()
            data.title = `${data.sobjectLabelPlural} (${state.numberOfRecords}+)`
        } else {
            data.title = `${data.sobjectLabelPlural} (${Math.min(state.numberOfRecords, records.length)})`
        }     
        return data
    }


    initColumnsWithActions(columns, customActions) {
        /*
        if (!customActions.length) {
            customActions = [
                { label: 'Edit', name: 'edit' },
                { label: 'Delete', name: 'delete' }
            ]
        }
        */
        //return [...columns, { type: 'action', typeAttributes: { rowActions: customActions } }]
        return [...columns];
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

    flattenStructure(topObject, prefix, toBeFlattened) {
        for (const propertyName in toBeFlattened) {
            const propertyValue = toBeFlattened[propertyName];
            if (typeof propertyValue === 'object') {
                this.flattenStructure(topObject, prefix + propertyName + '_', propertyValue);
            } else {
                topObject[prefix + propertyName] = propertyValue;
            }
        }
    }

    numberWithCommas(x) {
        return x.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
    }

    isViewAllOn = false;
    handleViewAll(event){
        if(this.isViewAllOn){
            this.isViewAllOn = false;
        }else{
            this.isViewAllOn = true;
        }
        this.setRecordsViewAll();
    }   
}