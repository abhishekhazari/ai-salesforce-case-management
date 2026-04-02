import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import getAIResponse from '@salesforce/apex/AIController.getAIResponse';

import AI_RESPONSE from '@salesforce/schema/Case.AI_Response__c';
import AI_PRIORITY from '@salesforce/schema/Case.AI_Priority__c';
import AI_PROCESSED from '@salesforce/schema/Case.AI_Processed__c';
import CUSTOMER_SUMMARY from '@salesforce/schema/Case.Customer_Summary__c';
import DESCRIPTION_FIELD from '@salesforce/schema/Case.Description';

const FIELDS = [
    AI_RESPONSE,
    AI_PRIORITY,
    AI_PROCESSED,
    CUSTOMER_SUMMARY,
    DESCRIPTION_FIELD
];

export default class AiCaseViewer extends LightningElement {
    @api recordId;
    loading = false;
    errorMessage = '';
    generatedResponse = '';

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    caseRecord;

    get response() {
        return this.generatedResponse || getFieldValue(this.caseRecord.data, AI_RESPONSE);
    }

    get priority() {
        return getFieldValue(this.caseRecord.data, AI_PRIORITY);
    }

    get processed() {
        return getFieldValue(this.caseRecord.data, AI_PROCESSED);
    }

    get summary() {
        return getFieldValue(this.caseRecord.data, CUSTOMER_SUMMARY);
    }

    get description() {
        return getFieldValue(this.caseRecord.data, DESCRIPTION_FIELD);
    }

    handleGenerate() {
        this.loading = true;
        this.errorMessage = '';

        getAIResponse({ description: this.description })
            .then(result => {
                this.generatedResponse = result;
            })
            .catch(error => {
                this.errorMessage = error.body ? error.body.message : 'Unknown error';
            })
            .finally(() => {
                this.loading = false;
            });
    }
}