@isTest
public with sharing class SpamProspectsDelete_Test {
    
    @TestSetup
    //create Prospect rec with "Referral" as Prospect_source
    static void testData(){
        List<Prospect__c> prosData = new List<Prospect__c>();

        for(Integer i=1; i<=6; i++){
            prosData.add(new Prospect__c(
                Prospect_Name__c = 'Prospect_' + i,
                Prospect_Source__c = 'Referral',
                Email__c = 'pros' + i + '@gmail.com'
            ));
        }
        insert prosData;
        
    }
    //test method
    @isTest
    static void testSpemProspectDelete(){
        Test.startTest();
        SpamProspectsDelete.deleteProspectRec('Referral');
        Test.stopTest();

        //Query if deleted test still exists
        List<Prospect__c> deletedProsRecs =[
            SELECT Id, Prospect_Source__c 
            FROM Prospect__c 
            WHERE Prospect_Source__c = 'Referral' ];

        if(deletedProsRecs.isEmpty()){
            System.debug('All Prospect with Referral as Source has been deleted');
        }

        //Assert
        Assert.areEqual(0, deletedProsRecs.size(),'No Prospectrecord should be returned');
    }
}