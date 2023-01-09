public with sharing class TwilioSMSHelper{
    @TestVisible private static String MISSING_PHONE_ERROR = 'Missing Phone Number.';
    @TestVisible private static String MISSING_TEXTBODY_ERROR = 'SMS to sent is Empty.';
    @TestVisible private static String MISSING_TWILLIO_CONFIG_ERROR = 'Twilio configuration are missing.';  
    private static String ERROR_STATUS  = 'error';
    private static String SUCCESS_STATUS  = 'success';
     
    public with sharing class SMSDetail{
        @InvocableVariable(required=true)  public String mobileNumber;
        @InvocableVariable(required=true)  public String messageContent;
        @InvocableVariable(required=true)  public String accountId;
    }
    public with sharing class SMSSendResult{
        @AuraEnabled public String status;
        @AuraEnabled public String message ;
        @AuraEnabled public String smsTwilioStatus;
    }
    
    @InvocableMethod(label='Send SMS Using Twillio API')
    public static void sendSMSUsingTwillio(List<SMSDetail> smsToBeSent) {
        Map<String,SMSSendResult> smsDeliveryResults = new Map<String,SMSSendResult>();
        for(SMSDetail sms:smsToBeSent){
            SMSSendResult smsDeliveryDetail = TwilioSMSHelper.makeCalloutToTwillioSendSMS(sms.mobileNumber,sms.messageContent);
            if(smsDeliveryDetail.status != SUCCESS_STATUS ){
               /*
               As this operation is part of record triggered automation, displaying error message is not desirable.
               However error should be logged in logging framework. 
               Most of the org has logging framework in place with utility methods exposed
               */
           }else{
               smsDeliveryResults.put(sms.accountId, smsDeliveryDetail );
           }
       }
       logSMSInSystem(smsToBeSent,smsDeliveryResults, 'CEO');
   }
  
   @AuraEnabled
   public static SMSSendResult sendSMSUsingTwillioFromLwc(String smsToBeSent) {  
        Map<String,SMSSendResult> smsDeliveryResults = new Map<String,SMSSendResult>();
        SMSDetail sms=(SMSDetail)JSON.deserialize(smsToBeSent,SMSDetail.class);
        SMSSendResult smsDeliveryDetail = TwilioSMSHelper.makeCalloutToTwillioSendSMS(sms.mobileNumber,sms.messageContent);
        if(smsDeliveryDetail.status == SUCCESS_STATUS ){
            smsDeliveryResults.put(sms.accountId,smsDeliveryDetail);
            logSMSInSystem(new List<SMSDetail>{sms},smsDeliveryResults, 'Customer');
        }
        //returns success/error details which are used in lwc to pass relevant information to user
        return smsDeliveryDetail ;
   }     
    @TestVisible
    private static SMSSendResult validateRequiredAtrributesForSendingSMS(String mobileNumber, String textContents,Twilio_Auth_Information__mdt twillioAuthCred){
        SMSSendResult smsResultDetail = new SMSSendResult(); 
        if(String.isBlank(mobileNumber)){
            smsResultDetail.status = ERROR_STATUS ;
            smsResultDetail.message = MISSING_PHONE_ERROR ;
            return smsResultDetail;
        }  
        if(String.isBlank(textContents)){
            smsResultDetail.status = ERROR_STATUS ;
            smsResultDetail.message = MISSING_TEXTBODY_ERROR ;
            return smsResultDetail;
        }
        if(twillioAuthCred == null){
            smsResultDetail.status = ERROR_STATUS ;
            smsResultDetail.message = MISSING_TWILLIO_CONFIG_ERROR ;
            return smsResultDetail;
        }
        return smsResultDetail;
    }
    private static HttpRequest prepareRequestPayloadSMSData(String recieverMobileNumber, String textContents,Twilio_Auth_Information__mdt twilioAuthCred){
       
        String autherizationHeader = EncodingUtil.base64Encode(Blob.valueOf(twilioAuthCred.Account_SID__c+ ':' + twilioAuthCred.Auth_Token__c));
        HttpRequest smsRequest = new HttpRequest();
        smsRequest.setEndpoint(twilioAuthCred.Base_URL__c+twilioAuthCred.Account_SID__c+twilioAuthCred.API_Endpoint__c);
        smsRequest.setMethod('POST');
        smsRequest.setHeader('Accept', 'application/json');
        smsRequest.setHeader('Accept-Charset', 'utf-8');
        smsRequest.setHeader('Authorization','Basic '+ autherizationHeader );
        smsRequest.setBody('To='+EncodingUtil.urlEncode(recieverMobileNumber,'UTF-8')
                           +'&From='+EncodingUtil.urlEncode(twilioAuthCred.Orgwide_Twilio_Phone_Number__c,'UTF-8')
                           +'&Body='+EncodingUtil.urlEncode(textContents,'UTF-8'));
        return smsRequest;
    }
    public static SMSSendResult makeCalloutToTwillioSendSMS(String mobileNumber, String textContents)    { 
        Twilio_Auth_Information__mdt twilioAuthCred = Twilio_Auth_Information__mdt.getInstance('Twilio_Send_SMS');
        SMSSendResult smsResultDetail = validateRequiredAtrributesForSendingSMS(mobileNumber,textContents,twilioAuthCred );
        if(smsResultDetail.status == ERROR_STATUS ){
            return smsResultDetail ;
        }        
        Http http = new Http();
        HTTPResponse res= http.send(prepareRequestPayloadSMSData(mobileNumber,textContents,twilioAuthCred ));
        // should be implemented StatusCallback
        Map<String, Object> responseDetailsInfo = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        if(res.getStatusCode()== 201){
            smsResultDetail.status = SUCCESS_STATUS ;
            smsResultDetail.message = 'SMS is '+(String)responseDetailsInfo.get('status');
            smsResultDetail.smsTwilioStatus = (String)responseDetailsInfo.get('status');
            system.debug((String)responseDetailsInfo.get('sid'));
        }else{
            smsResultDetail.status = ERROR_STATUS ;
            if(responseDetailsInfo.get('message') != null){
                smsResultDetail.message = (String)responseDetailsInfo.get('message');
            }        
       }   
        return smsResultDetail;
    }
    private static void logSMSInSystem(List<SMSDetail> smsList, Map<String,SMSSendResult> smsDeliveryDetails, string sentToType){
        List<SMS__c> smsLogs = new List<SMS__c>();
        for(SMSDetail sms: smsList){
            SMS__c smsLog = new SMS__c();
            smsLog.Customer__c = sms.accountId;
            smsLog.Message_Content__c = sms.messageContent;
            smsLog.Sent_To_Number__c =  sms.mobilenumber;
            smsLog.Sent_To__c =  sentToType;
            
            SMSSendResult deliveryDetail = smsDeliveryDetails.get(sms.accountId);
            if(deliveryDetail != null){
                smsLog.Status__c = deliveryDetail.smsTwilioStatus ;
                smsLog.Extended_Status__c = deliveryDetail.message;
            }
            smsLogs.add(smsLog);
        }
        if(!smsLogs.isEmpty()){
            Insert smsLogs;       
        } 
    }
}