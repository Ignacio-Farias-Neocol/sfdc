import { LightningElement, api } from 'lwc';

export default class CustomIconComponent extends LightningElement {
  //These attributes will be set when defining column for the data table
  @api iconVariant;
  @api iconName;
  @api iconTitle;
  @api iconSize;
  @api iconAltText;
}