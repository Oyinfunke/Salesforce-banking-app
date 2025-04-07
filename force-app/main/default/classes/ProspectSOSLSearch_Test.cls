@isTest
public class ProspectSOSLSearch_Test {
    
    @TestSetup
    static void testData(String searchKey){

        //create prospect records
        List<Prospect__c> prosRecs = new List<Prospect__c>();

        for(Integer i=0; i<10; i++){
            prosRecs.add(new  Prospect__c(
                Prospect_Name__c = searchKey + i,
                Email__c = searchKey + '_' + i + '@softcode.com',
                Business_Development_Executive__c = 'Victor Alabi',
                Company_Name__c = 'Softcode',
                Contact_Number__c = '+44764829062',
                Prospect_Source__c = 'Referral',
                Prospect_Status__c = ''
            ));
        }
        insert prosRecs;
        
    }
    //test method
    @isTest
    static void testProspectSOSLSearch(String searchKey){
        Test.startTest();
        ProspectSOSLSearch.handleProspectSOSLSearch();
        Test.stopTest();

        //Assert
        Assert.areEqual(expected, actual, msg)
    }
}