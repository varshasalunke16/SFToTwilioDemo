@isTest
public class AccountTotalSpendAndClassificationTest{
    
    @testSetup static void generateAccountAndOpportunties() {
        // Most of the org will have test data factory framework and utility method exposed to create test data
        // Here direcly creating record as test data framework is not present in this Developer demo org
        Account customer = new Account( Name ='Test Acc 1',Phone = '0123456789');
        insert customer ;
        
        Customer_Classification_Configuration__mdt classificationConfig = Customer_Classification_Configuration__mdt.getInstance('Total_Customer_Spend_Account_Config');
        Decimal amountWithNoClassification = classificationConfig.Lowest_Amount_For_Bronze_Classification__c - 1;
        
        List<opportunity> opportunities = new List<Opportunity>();
        opportunities.add(new Opportunity(Name='Test Opp1',
                                          AccountId=customer.Id,
                                          Amount=amountWithNoClassification ,
                                          StageName='Closed Won',
                                          CloseDate=System.today()));
        opportunities.add(new Opportunity(Name='Bronze Status Opp',
                                          AccountId=customer.Id,
                                          Amount=classificationConfig.Lowest_Amount_For_Bronze_Classification__c ,
                                          StageName='Proposal/Price Quote',
                                          CloseDate=System.today()));
        opportunities.add(new Opportunity(Name='Silver Status Opp',
                                          AccountId=customer.Id,
                                          Amount=classificationConfig.Lowest_Amount_For_Silver_Classification__c,
                                          StageName='Proposal/Price Quote',
                                          CloseDate=System.today()));
        opportunities.add(new Opportunity(Name='Gold Status Opp',
                                          AccountId=customer.Id,
                                          Amount=classificationConfig.Lowest_Amount_For_Gold_Classification__c,
                                          StageName='Proposal/Price Quote',
                                          CloseDate=System.today()));
        insert opportunities;
    }
    @isTest private static void testBlankClassification(){
         Customer_Classification_Configuration__mdt classificationConfig = Customer_Classification_Configuration__mdt.getInstance('Total_Customer_Spend_Account_Config');
         Decimal amountWithNoClassification = classificationConfig.Lowest_Amount_For_Bronze_Classification__c - 1;
        
         Account customer = [SELECT Customer_Classification__c,Total_Customer_Spend__c FROM Account WHERE Name='Test Acc 1'];
         System.assertEquals(amountWithNoClassification ,customer.Total_Customer_Spend__c,'Only 1 Opportunity is closed won');
         System.assertEquals(null,customer.Customer_Classification__c,'Total Spend is below the threshold for account classification');
    }
    @isTest private static void testBronzeClassification(){
        Customer_Classification_Configuration__mdt classificationConfig = Customer_Classification_Configuration__mdt.getInstance('Total_Customer_Spend_Account_Config');
        Decimal amountWithNoClassification = classificationConfig.Lowest_Amount_For_Bronze_Classification__c - 1;
        
        Account customer = [SELECT Customer_Classification__c,Total_Customer_Spend__c FROM Account WHERE Name='Test Acc 1'];
         System.assertEquals(amountWithNoClassification ,customer.Total_Customer_Spend__c,'Only 1 Opportunity is closed won');
         System.assertEquals(null,customer.Customer_Classification__c,'Total Spend is below the threshold for account classification');
         
         Opportunity opp = [SELECT Id,StageName FROM Opportunity WHERE Name='Bronze Status Opp'];
         opp.stageName = 'closed won';
         update opp ;
         
         customer = [SELECT Customer_Classification__c,Total_Customer_Spend__c FROM Account WHERE Name='Test Acc 1'];
         System.assertEquals(amountWithNoClassification  + classificationConfig.Lowest_Amount_For_Bronze_Classification__c,
                             customer.Total_Customer_Spend__c,'Now 2 Opportunities are closed won, classification should change to bronze.');
         System.assertEquals('BRONZE',customer.Customer_Classification__c,'Total Spend quailify for Bronze classification');
    }
     @isTest private static void testSilverClassification(){
          Customer_Classification_Configuration__mdt classificationConfig = Customer_Classification_Configuration__mdt.getInstance('Total_Customer_Spend_Account_Config');
          Decimal amountWithNoClassification = classificationConfig.Lowest_Amount_For_Bronze_Classification__c - 1;
        
         Account customer = [SELECT Customer_Classification__c,Total_Customer_Spend__c FROM Account WHERE Name='Test Acc 1'];
         System.assertEquals(amountWithNoClassification ,customer.Total_Customer_Spend__c,'Only 1 Opportunity is closed won');
         System.assertEquals(null,customer.Customer_Classification__c,'Total Spend is below the threshold for account classification');
         
         Opportunity opp = [SELECT Id,StageName FROM Opportunity WHERE Name='Silver Status Opp'];
         opp.stageName = 'closed won';
         update opp ;
         
         customer = [SELECT Customer_Classification__c,Total_Customer_Spend__c FROM Account WHERE Name='Test Acc 1'];
         System.assertEquals(amountWithNoClassification  + classificationConfig.Lowest_Amount_For_Silver_Classification__c,
                             customer.Total_Customer_Spend__c,'Now 2 Opportunities are closed won, classification should change to Silver.');
         System.assertEquals('SILVER',customer.Customer_Classification__c,'Total Spend quailify for Silver classification');
    }
     @isTest private static void testGoldClassification(){
        Customer_Classification_Configuration__mdt classificationConfig = Customer_Classification_Configuration__mdt.getInstance('Total_Customer_Spend_Account_Config');
        Decimal amountWithNoClassification = classificationConfig.Lowest_Amount_For_Bronze_Classification__c - 1;
        
        Account customer = [SELECT Customer_Classification__c,Total_Customer_Spend__c FROM Account WHERE Name='Test Acc 1'];
         System.assertEquals(amountWithNoClassification, customer.Total_Customer_Spend__c,'Only 1 Opportunity is closed won');
         System.assertEquals(null,customer.Customer_Classification__c,'Total Spend is below the threshold for account classification');
         Test.startTest();
             Opportunity opp = [SELECT Id,StageName FROM Opportunity WHERE Name='Gold Status Opp'];
             opp.stageName = 'closed won';
             update opp ;
         Test.stopTest();
         customer = [SELECT Customer_Classification__c,Total_Customer_Spend__c FROM Account WHERE Name='Test Acc 1'];
         System.assertEquals(amountWithNoClassification + classificationConfig.Lowest_Amount_For_Gold_Classification__c,
                             customer.Total_Customer_Spend__c,'Now 2 Opportunities are closed won, classification should change to Gold.');
         System.assertEquals('GOLD',customer.Customer_Classification__c,'Total Spend quailify for Gold classification');
        
    }
}