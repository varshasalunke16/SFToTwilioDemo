import { LightningElement,api,wire } from 'lwc';
import { getRecord, getFieldValue,getRecordNotifyChange } from 'lightning/uiRecordApi';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import sendSMSUsingTwillio from '@salesforce/apex/TwilioSMSHelper.sendSMSUsingTwillioFromLwc'
import PHONE_FIELD from '@salesforce/schema/Account.Phone';
const fields = [PHONE_FIELD];

export default class SendSMSToCustomer extends NavigationMixin(LightningElement){
    @api recordId;
    PESTER_MODE = 'pester';
    PHONE_MISSING_ERROR = 'Phone number is missing for this account.';
    ERROR_TYPE = 'error';
    SUCCESS_TYPE = 'success';
    calloutIsStarted = false;
    @wire(getRecord, { recordId: '$recordId', fields })
    goldAccount;   

    sendSMSFromAccount(){          
       if(getFieldValue(this.goldAccount,PHONE_FIELD) == null){
           this.showNotification(this.ERROR_TYPE,this.PHONE_MISSING_ERROR,this.ERROR_TYPE);
           return;
        }
        let smsPayload = { 
            mobileNumber: getFieldValue(this.goldAccount.data,PHONE_FIELD) ,
            messageContent: this.template.querySelector("lightning-textarea").value,
            accountId : this.recordId
        };
        this.calloutIsStarted = true; 
        sendSMSUsingTwillio({smsToBeSent : JSON.stringify(smsPayload)}).then((result)=>{
            this.showNotification(result.status,result.message,result.status);
            this.calloutIsStarted = false; 
            if(result.status == this.SUCCESS_TYPE){
                this.updateRecordView() ;
            }
        }).catch(error=>{
            this.showNotification(this.ERROR_TYPE,JSON.stringify(error),this.ERROR_TYPE);
            return;
        });
    }
    updateRecordView() {
        this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: this.recordId,
                    actionName: 'view',
                },
        });
     }
    showNotification(titleValue,messageValue,variantValue){
        const evt = new ShowToastEvent({
            title: titleValue,
            message: messageValue,
            variant: variantValue,
            mode: this.PESTER_MODE 
        });
        this.dispatchEvent(evt);
    }
    
}