//Apex class to retrieve Prospect's ID, Name & Email. Retrieved records will be store in a set collection.
public class ProspectSetFetch {
    
    //Method to fetch Prospect Records.
    public static void retrieveProspectDetails(){
        
        //Create a set collection to store retrieved Prospect's details
        Set<Id> prospectId = new Set<Id>();
        
        //Querying the SF DB to retrieve prospect records in bulk (as a list collection).
        List<Prospect__c> retrievedProspect = [
            SELECT Id, Prospect_Name__c, Name, Email__c
            FROM Prospect__c
            ORDER BY Name ASC
            LIMIT 100
        ];
        
        //Add the required details (Id, Email__c,...) in the retrieved collection into the Set collection using a FOR Loop.
        For(Prospect__c p : retrievedProspect){
            prospectId.add(p.Id);
            System.debug('Retrieved Prospect Name: ' + p.Prospect_Name__c + ' ,Prospect Id: ' + p.Id + ' , Email: ' + p.Email__c);
        }
      
    }

}