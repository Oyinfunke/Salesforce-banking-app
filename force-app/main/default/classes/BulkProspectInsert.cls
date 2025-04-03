public class BulkProspectInsert {
    
    public static void createBulkProspectRec (){
        
        //Create a list to hold all instance of Prospect object created
        List<Prospect__c> bulkProspectRec = new List<Prospect__c>();
        
        //Retrieve Victor Alabi employee record from the Employee__c object using SOQL
        Employee__c empVictor = [SELECT Id, Name FROM Employee__c WHERE Name= 'Victor Alabi'];
        
        //Instantiate 11000 Prospect records using FOR Loop
        For(integer i = 110; i<=1000; i++){
            Prospect__c newProspect = new Prospect__c(
            Prospect_Name__c = 'Prospect ' + i ,
            Prospect_Source__c = 'Cold Call',
            Email__c = 'pros_'+ i+'@test.com',
            Business_Development_Executive__c = empVictor.Id,
            Company_Name__c = 'Test Company_'+ i,
            Meeting_Date__c = date.today().addDays(3),
            Contact_Number__c = '+4481292003'
            );
            
            //Add each instance of the Prospect record created to the List collection (bulkProspectRec)
            bulkProspectRec.add(newProspect);
        }
        
        //Insert the List (bulkProspectRec) into Salesforce Database
         Insert bulkProspectRec;
        
        For(Prospect__c p : bulkProspectRec ){
            System.debug('Name of newly created Prospect is: ' + p.Prospect_Name__c);
            
        }
    }
}