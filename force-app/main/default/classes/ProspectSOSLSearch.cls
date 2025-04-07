public class ProspectSOSLSearch {
    
    public static void handleProspectSOSLSearch(String searchKey){

        List<List<Prospect__c>> searchResults = [
            FIND :searchKey
            IN all fields
            RETURNING Prospect__c(Id, Business_Development_Executive__c, 
            Company_Name__c, Contact_Number__c, 
            Email__c, Name, Prospect_Name__c, 
            Prospect_Source__c, Prospect_Status__c )];

        if(!searchResults.isEmpty()){
            List<Prospect__c> prosRecs = searchResults[0];

            if(!prosRecs.isEmpty()){
                for(Prospect__c pros : prosRecs){
                    System.debug('Prospect record fetched from SOSL search: ' + pros.Prospect_Name__c + ' ' + pros.Email__c);
                }
                
            }else {
                System.debug('No Prospect record with ' + searchKey + 'found');
            }
        }else {
            System.debug('No object record with ' + searchKey + 'found');
            }
        }
         


    }
