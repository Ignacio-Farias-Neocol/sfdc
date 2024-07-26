global class SetAssingSerialInactiveBatchSchd implements Schedulable{
    global void execute(SchedulableContext sc) {
       
        SetAssingSerialInactiveBatch setAsgSr= new SetAssingSerialInactiveBatch();
        Database.executeBatch(setAsgSr, 1);
    }
}