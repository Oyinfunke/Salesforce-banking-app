public class BatchProspectCreation implements Database.Batchable<sObject>{
    
    public Database.QueryLocator start (Database.BatchableContext bc){
     
        return Database.getQueryLocator([SELECT Id FROM Prospect__c LIMIT 1]);
        
    }
    
    public void execute (Database.BatchableContext bc, List<sObject> scope){
        
        //Create a list to hold all instance of Prospect object created
        List<Prospect__c> prospectList = new List<Prospect__c>();
        
        //Retrieve Victor Alabi employee record from the Employee__c object using SOQL
        Employee__c empVictor = [SELECT Id, Name FROM Employee__c WHERE Name= 'Victor Alabi'];
        
         //Instantiate 11000 Prospect records using FOR Loop
        for (integer i=110; i<=11000; i++){
            Prospect__c newProspect = new Prospect__c (
           Prospect_Name__c = 'Prospect ' + i ,
            Prospect_Source__c = 'Cold Call',
            Email__c = 'pros_'+ i+'@test.com',
            Business_Development_Executive__c = empVictor.Id,
            Company_Name__c = 'Test Company_'+ i,
            Meeting_Date__c = date.today().addDays(3),
            Contact_Number__c = '+4481292003' );
            
            prospectList.add(newProspect);
        }
        
        //Insert the List (prospectList) into Salesforce Database
         Insert prospectList;
        
        For(Prospect__c p : prospectList ){
        System.debug('Name of newly created Prospect is: ' + p.Prospect_Name__c);
    }

}
    public void finish (Database.BatchableContext bc){
        System.debug('Successfully created 11000 Prospect records');
        
    }
    
}