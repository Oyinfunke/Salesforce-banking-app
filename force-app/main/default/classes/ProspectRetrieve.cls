public class ProspectRetrieve {
    
public static void retrieveProspectRec(){
        
        Set<Id> prospectSetIds = new Set<Id>();
        
        List<Prospect__c> prospectList = [
            SELECT Id, Name, Email__c, Prospect_Source__c, Prospect_Status__c
            FROM Prospect__c
            ORDER BY Name DESC
            LIMIT 1000
        ];
        
        for(Prospect__c p : prospectList){
            prospectSetIds.add(p.Id); 
            System.debug('Prospect Name is: ' + p.Name + ', Prospect Id is: ' + p.Id + ', Prospect Email is: ' + p.Email__c + ' ,Prospect Status: ' + p.Prospect_Status__c + ' ,Prospect Source: ' + p.Prospect_Source__c);
        }
            
    }

}