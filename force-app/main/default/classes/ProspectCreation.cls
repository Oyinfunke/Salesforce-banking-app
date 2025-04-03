public class ProspectCreation {
    public static String createProspect(){
        
        Employee__c empVictor = [SELECT Id, Name FROM Employee__c  WHERE Name = 'Victor Alabi'];
        
        Prospect__c newProspect = new Prospect__c(
        	Prospect_Name__c = 'Peter Silas',
            Prospect_Source__c = 'Cold Call',
            Email__c = 'psilas@test.com',
            Business_Development_Executive__c = empVictor.Id,
            Company_Name__c = 'Test Company',
            Meeting_Date__c = date.today().addDays(3),
            Contact_Number__c = '+4481292003'
        );
        	insert newProspect;
        
        	System.debug('Newly created Prospect is ' + newProspect.Prospect_Name__c);	
            return newProspect.Prospect_Name__c;
    }

}