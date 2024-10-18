/**
 * @description       : 
 * @author            : Ignacio F.
 * @group             : 
 * @last modified on  : 07-26-2024
 * @last modified by  : Ignacio F.
**/
public with sharing class NEO_PerformanceUtils {
    
    // Define the current time, current CPU Time, Current DML Statements, and Current SOQL Queries
    public Long currentTime;
    public Long currentCPUTime;
    public Integer currentDMLStatements;
    public Integer currentSOQLQueries;
    public Long currentHeapSize;

    // Constructor that takes the current time, current CPU Time, Current DML Statements, and Current SOQL Queries
    public NEO_PerformanceUtils() {
        this.currentTime = System.now().getTime();
        this.currentCPUTime = Limits.getCpuTime();
        this.currentDMLStatements = Limits.getDMLStatements();
        this.currentSOQLQueries = Limits.getQueryRows();
        this.currentHeapSize = Limits.getHeapSize();
    }

    // Create a method that calculates all the variables against the defined variables and debugs the result
    public void calculatePerformance() {
        // Get the current time
        Long newTime = System.now().getTime();
        // Get the current CPU Time
        Long newCPUTime = Limits.getCpuTime();
        // Get the current DML Statements
        Integer newDMLStatements = Limits.getDMLStatements();
        // Get the current SOQL Queries
        Integer newSOQLQueries = Limits.getQueryRows();
        // Get the current Heap Size
        Integer newHeapSize = Limits.getHeapSize();

        // Calculate the time difference
        Long timeDifference = newTime - currentTime;
        // Calculate the CPU Time difference
        Long cpuTimeDifference = newCPUTime - currentCPUTime;
        // Calculate the DML Statements difference
        Integer dmlStatementsDifference = newDMLStatements - currentDMLStatements;
        // Calculate the SOQL Queries difference
        Integer soqlQueriesDifference = newSOQLQueries - currentSOQLQueries;
        // Calculate the Heap Size difference
        Long heapSizeDifference = newHeapSize - currentHeapSize;

        System.debug('Time Difference: ' + timeDifference + 'ms');
        System.debug('CPU Time Difference: ' + cpuTimeDifference + 'ms');
        System.debug('DML Statements Difference: ' + dmlStatementsDifference);
        System.debug('SOQL Queries Difference: ' + soqlQueriesDifference);
        System.debug('Heap Size Difference: ' + heapSizeDifference);
    }
}