@isTest
public class ProspectRecUpdate_Test {
    @TestSetup
    static void testData(){
        // Create Prospect records with matching emails from the emailMap in the class being tested
        List<Prospect__c> prosRec = new List<Prospect__c>();
        
        // Creating test data that matches the email keys in ProspectRecUpdate.updateProspectRec()
        for(Integer i=978; i<=997; i++){
            prosRec.add(new Prospect__c(
                Prospect_Name__c = 'Prospect' + i,
                Email__c = 'pros_' + i + '@test.com'
            ));
        } 
        insert prosRec;
    }
    
    @isTest
    public static void testProspectRecUpdate(){
        // Execute the method being tested
        Test.startTest();
        ProspectRecUpdate.updateProspectRec();
        Test.stopTest();
        
        // Query the updated records
        List<Prospect__c> updatedProspects = [SELECT Id, Prospect_Name__c, Email__c 
                                             FROM Prospect__c 
                                             WHERE Email__c LIKE '%softcode.com'];
        
        // Define expected values for verification
        Map<String, String> expectedEmailMap = new Map<String, String>{
            'Prospect997' => 'john@softcode.com',
            'Prospect996' => 'peter@softcode.com',
            'Prospect995' => 'chris@softcode.com',
            'Prospect994' => 'mercy@softcode.com',
            'Prospect993' => 'godwin@softcode.com',
            'Prospect992' => 'joy@softcode.com',
            'Prospect991' => 'success@softcode.com',
            'Prospect990' => 'cheelo@softcode.com',
            'Prospect989' => 'muees@softcode.com',
            'Prospect988' => 'godwin@softcode.com',
            'Prospect987' => 'mary@softcode.com',
            'Prospect986' => 'allen@softcode.com',
            'Prospect985' => 'anne@softcode.com',
            'Prospect984' => 'milimomo@softcode.com',
            'Prospect983' => 'shade@softcode.com',
            'Prospect982' => 'julliet@softcode.com',
            'Prospect981' => 'babs@softcode.com',
            'Prospect980' => 'craig@softcode.com',
            'Prospect979' => 'tom@softcode.com',
            'Prospect978' => 'jollie@softcode.com'
        };
        
        // Verify the number of records updated
        System.assertEquals(20, updatedProspects.size(), 'All 20 prospects should be updated');
        
        // Verify each record was updated with the correct email
        for(Prospect__c pros : updatedProspects) {
            String expectedEmail = expectedEmailMap.get(pros.Prospect_Name__c);
            System.assertEquals(expectedEmail, pros.Email__c, 
                               'Email for ' + pros.Prospect_Name__c + ' is not updated correctly');
        }
    }
}