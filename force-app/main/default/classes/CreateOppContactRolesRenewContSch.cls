global class CreateOppContactRolesRenewContSch implements schedulable{
    global void execute(SchedulableContext sc){
        CreateOppContactRolesRenewCont cocrc = new CreateOppContactRolesRenewCont();
        Database.executeBatch(cocrc, 1);
    } 
}