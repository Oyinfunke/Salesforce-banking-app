public class ProspectRecFetch {
    
    public static void fetchProspectRec(){
        Set<String> prospectId = new Set<String> {
        			'PS-00956',
            		'PS-00955',
            		'PS-00954',
            		'PS-00953',
            		'PS-00952',
            		'PS-00951',
            		'PS-00950'
            };
                
         List<Prospect__c> retrieveProspectRec = [SELECT Id, Name, Prospect_Name__c FROM Prospect__c WHERE Name IN : prospectId];
        
        if (!retrieveProspectRec.isEmpty()){
        	For (Prospect__c p : retrieveProspectRec ){
            System.debug('Retrieved Prospect Id is: ' + p.Id + ' Retrieved Prospect Name is: ' + p.Prospect_Name__c);
        }
            
        }
        else {
            System.debug('Prospect Records not found');
        }
    }
}