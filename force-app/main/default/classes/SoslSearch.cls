public class SoslSearch {
    public static void handleSearchResult(String searchName){
        //SOSL query to retrieve search 
        List<List<sObject>> searchResult = [
            FIND :searchName
            IN ALL FIELDS 
            RETURNING Prospect__c(Id,Company_Name__c,Prospect_Name__c,Name ), Customer__c(Name, Email__c), Employee__c(Name)	];
        
        List<Prospect__c> prospect = (List<Prospect__c>)searchResult[0];
        List<Customer__c> customer = (List<Customer__c>)searchResult[1];
        List<Employee__c> employee =(List<Employee__c>)searchResult[2];
        
        if(!prospect.isEmpty()){
        	for(Prospect__c p : prospect){
            	System.debug(p.Prospect_Name__c + ' is a Prospect and works at ' + p.Company_Name__c);
            
        }   
            }
        
        else{
                System.debug('No Prospect found in search');
     }
        if(!customer.isEmpty()){
        	for(Customer__c c : customer){
            	System.debug(c.Name + ' is a Customer.');
            
        }   
            }
        
        else{
                System.debug('No Customer found in search.');
        
    }
        
        if(!employee.isEmpty()){
        	for(Employee__c e : employee){
            	System.debug(e.Name + ' is an Employee.');
            
        }   
            }
        
        else{
                System.debug('No Employee found in search.');
        
    	}     
    }
}