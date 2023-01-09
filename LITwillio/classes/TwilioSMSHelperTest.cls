@isTest
public class TwilioSMSHelperTest{
    public class TwillioHttpCalloutMockSuccess implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            String responseBody = '{'+
                                    '"status":"Sent"'+
                                  '}';
            HTTPResponse smsCalloutResponse = new HTTPResponse();
            smsCalloutResponse.setStatusCode(201);
            smsCalloutResponse.setBody(responseBody);
            return smsCalloutResponse;
        }
    }
    public class TwillioHttpCalloutMockFail implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            String responseBody = '{'+
                                    '"message":"Failed due to internal error in twillio"'+
                                  '}';
            HTTPResponse smsCalloutResponse = new HTTPResponse();
            smsCalloutResponse.setStatusCode(500);
            smsCalloutResponse.setBody(responseBody);
            return smsCalloutResponse;
        }
    }
    @isTest private static void testEmptyMessageBodyOrPhoneNumber(){
        TwilioSMSHelper.SMSSendResult response = TwilioSMSHelper.makeCalloutToTwillioSendSMS('0123456789','');
        system.assertEquals(TwilioSMSHelper.MISSING_TEXTBODY_ERROR ,response.message ,'Error is expected when SMS body is blank.');
        response = TwilioSMSHelper.makeCalloutToTwillioSendSMS('','Hello!');
        system.assertEquals(TwilioSMSHelper.MISSING_PHONE_ERROR ,response.message ,'Error is expected when no number is specified.');
    }
    @isTest private static void testTwillioConfigMissing(){
        TwilioSMSHelper.SMSSendResult response = TwilioSMSHelper.validateRequiredAtrributesForSendingSMS('0123456789','Missing Twillio Auth?',null);
        system.assertEquals(TwilioSMSHelper.MISSING_TWILLIO_CONFIG_ERROR ,response.message ,'Error is expected when no twillio config present in org.');
    }
    @isTest private static void testSuccessfulMessageSent(){
        Test.setMock(HttpCalloutMock.class, new TwillioHttpCalloutMockSuccess());
        Test.startTest();
            TwilioSMSHelper.SMSSendResult response = TwilioSMSHelper.makeCalloutToTwillioSendSMS('0123456789','Hello Again!');
        Test.stopTest();
        system.assertEquals('SMS is Sent' ,response.message ,'SMS should be sent successfully.');
    }
    @isTest private static void testMessageFailure(){
        Test.setMock(HttpCalloutMock.class, new TwillioHttpCalloutMockFail());
        Test.startTest();
            TwilioSMSHelper.SMSSendResult response = TwilioSMSHelper.makeCalloutToTwillioSendSMS('0123456789','Hello Again!');
        Test.stopTest();
        system.assertEquals('Failed due to internal error in twillio' ,response.message ,'SMS should be Failed.');
    }  
    @isTest private static void testSuccessfulMessageSentFromLWC(){
        Test.setMock(HttpCalloutMock.class, new TwillioHttpCalloutMockSuccess());
        Test.startTest();
            TwilioSMSHelper.SMSSendResult response = TwilioSMSHelper.sendSMSUsingTwillioFromLwc('{"mobileNumber":"0123456789","messageContent":"Hello From LWC"}');
        Test.stopTest();
        system.assertEquals('SMS is Sent' ,response.message ,'SMS should be sent successfully.');
    }
    @isTest private static void testMessageFailureFromLWC(){
        Test.setMock(HttpCalloutMock.class, new TwillioHttpCalloutMockFail());
        Test.startTest();
            TwilioSMSHelper.SMSSendResult response = TwilioSMSHelper.sendSMSUsingTwillioFromLwc('{"mobileNumber":"0123456789","messageContent":"Hello From LWC"}');
        Test.stopTest();
        system.assertEquals('Failed due to internal error in twillio' ,response.message ,'SMS should be Failed.');
    }  
    @isTest private static void testSuccessfulMessageSentFromFlow(){
        Test.setMock(HttpCalloutMock.class, new TwillioHttpCalloutMockSuccess());
        TwilioSMSHelper.SMSDetail smsForCEOFromFlow = new TwilioSMSHelper.SMSDetail();
        smsForCEOFromFlow.mobileNumber = '0123456789';
        smsForCEOFromFlow.messageContent = 'Hello from flow.';
        List<TwilioSMSHelper.SMSDetail> inputsFromFlow = new  list<TwilioSMSHelper.SMSDetail>();
        inputsFromFlow.add(smsForCEOFromFlow);
        Test.startTest();
           TwilioSMSHelper.sendSMSUsingTwillio(inputsFromFlow);
        Test.stopTest();
        system.assertEquals(1 ,[SELECT count() FROM SMS__c ] ,'SMS should be sent successfully.');
    }
}