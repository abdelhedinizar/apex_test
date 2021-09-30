trigger ContractEndDateAdapterTrigger on SBQQ__Subscription__c (before insert, before update, after insert, after update) {
     
    Set<Id> cons = new Set<Id>();
    if(Trigger.isBefore){
      cons = ContractUtils.getSBQQContractIds(Trigger.new);
    }
    if(Trigger.isAfter){
        ContractUtils.adapteEndDateContract(cons);
    }
}