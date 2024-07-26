import LightningDatatable from 'lightning/datatable';
import iconCell from './iconCell.html';
import serialCardCell from './serialCardCell.html';

export default class CustomDatable extends LightningDatatable {
   static customTypes = {
       iconCustomType: {
           template: iconCell,
           standardCellLayout: true,

           // Provide template data here if needed
           typeAttributes: ['iconVariant', 'iconName', 'iconSize', 'iconTitle']
       },
       serialCardCustomType:{
           template: serialCardCell,
           standardCellLayout:false,
           typeAttributes:['serial']
       }
      //more custom types here
   };
}