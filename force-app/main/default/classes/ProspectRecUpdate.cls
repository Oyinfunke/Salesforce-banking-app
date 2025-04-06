public class ProspectRecUpdate {
   
    public static void updateProspectRec(){
        
        Map<String, String> emailMap = new Map<String, String>{
            
            	'pros_997@test.com' => 'john@softcode.com',
                
                'pros_996@test.com' => 'peter@softcode.com',
                
                'pros_995@test.com' => 'chris@softcode.com',
                
                'pros_994@test.com' => 'mercy@softcode.com',
                
                'pros_993@test.com' => 'godwin@softcode.com',
                
                'pros_992@test.com' => 'joy@softcode.com',
                
                'pros_991@test.com' => 'success@softcode.com',
                
                'pros_990@test.com' => 'cheelo@softcode.com',
                
                'pros_989@test.com' => 'muees@softcode.com',
                
                'pros_988@test.com' => 'godwin@softcode.com',
                    
                'pros_987@test.com' => 'mary@softcode.com',
                
                'pros_986@test.com' => 'allen@softcode.com',
                    
                'pros_985@test.com' => 'anne@softcode.com',
                
                'pros_984@test.com' => 'milimomo@softcode.com',
                    
                'pros_983@test.com' => 'shade@softcode.com',
                
                'pros_982@test.com' => 'julliet@softcode.com',
                    
                'pros_981@test.com' => 'babs@softcode.com',
                
                'pros_980@test.com' => 'craig@softcode.com',
                    
                'pros_979@test.com' => 'tom@softcode.com',
                
                'pros_978@test.com' => 'jollie@softcode.com'
       };
     
           
           List<Prospect__c> prospectsList = [
               SELECT Id, Name, Email__c, Prospect_Name__c
               FROM Prospect__c
               WHERE Email__c IN :emailMap.keySet()];
        
        for(Prospect__c p : prospectsList){
            if(emailMap.containsKey(p.Email__c)){
                p.Email__c = emailMap.get(p.Email__c);
            }  
        }
        
        update prospectsList;
        
        for (Prospect__c i : prospectsList){
        System.debug('The new Prospects Emails that were updated are: ' + i.Email__c);
        }
    }


}