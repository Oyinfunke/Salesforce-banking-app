public class BulkProspectCreation {
    public static void createBulkProspect(){
        Employee__c empVictor = [SELECT Id,Name FROM Employee__c WHERE Name = 'Victor Alabi' LIMIT 1];
        
        List<Prospect__c> prospectList = new List<Prospect__c>();
        
        for(integer i=1; i<=100; i++){
            Prospect__c newProspect = new Prospect__c(
            Prospect_Name__c = 'Prospect ' + i ,
            Prospect_Source__c = 'Cold Call',
            Email__c = 'pros_'+ i+'@test.com',
            Business_Development_Executive__c = empVictor.Id,
            Company_Name__c = 'Test Company_'+ i,
            Meeting_Date__c = date.today().addDays(3),
            Contact_Number__c = '+4481292003'
            );
            
            prospectList.add(newProspect);
        }
        
        insert prospectList;
        
        for (Prospect__c pros :prospectList ){
            System.debug('Newly created Prospect is ' + pros.Prospect_Name__c);
        }
    }

}