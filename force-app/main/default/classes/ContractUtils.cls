public class ContractUtils {
    

    
    public static Set<Id> getSBQQContractIds(List<SBQQ__Subscription__c> subscriptions){
      Set<Id> cons = new Set<Id>();
      for (SBQQ__Subscription__c sub :subscriptions) {
       cons.add(sub.SBQQ_Contract__c);
      }
        return cons;
    }
    
    public static void adapteEndDateContract(Set<Id> cons){
    
        Boolean isTerminate;
        Date terminatedDate;
        Date endDate;
        
          try {
              List<Contract> conts = new List<Contract>();
                for (Contract con : [SELECT Id, EndDate, (SELECT Id, SBQQ_EndDate__c, SBQQ_TerminatedDate__c, SBQQ_Contract__c 
                                              FROM SBQQ_Subscriptions__r) FROM Contract WHERE Id IN :cons]) {
            system.debug('contrat on :: '+con)   ; 
            isTerminate = true;
            terminatedDate = con.EndDate;
            endDate = con.EndDate;
              
            for (SBQQ__Subscription__c sub : con.SBQQ_Subscriptions__r) {
                if (sub.SBQQ_TerminatedDate__c == null) {
                    isTerminate = false;
                } else if (terminatedDate < sub.SBQQ_TerminatedDate__c) {
                    terminatedDate = sub.SBQQ_TerminatedDate__c;
                }
                if (sub.SBQQ_EndDate__c != null && endDate < sub.SBQQ_EndDate__c) {
                    endDate = sub.SBQQ_EndDate__c;
                }
            }
            //End date not writable
            if (isTerminate) {
                con.EndDate = terminatedDate;
            } else {
                con.EndDate = endDate;
            }
                 conts.add(con);
        }    
        if(conts.size()>0){
        UPDATE conts;    
        } 
              }
        
         catch(Exception e) {
            Logs.error('ContractEndDateAdapterTrigger','SBQQ__Subscription__c Trigger insert & update', e);
    }
        
    }

}