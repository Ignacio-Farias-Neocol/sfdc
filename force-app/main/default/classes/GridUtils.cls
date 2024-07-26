/**
 * Created by rsieve on 5/17/18.
 */

public with sharing class GridUtils {

        public static map<string, string> gridTypes = new map<string, string>{
                'STRING'        => 'text',
                'TEXTAREA'      => 'text',
                'DOUBLE'        => 'number',
                'INTEGER'       => 'number',
                'REFERENCE'     => 'url',
                'URL'           => 'url',
                'DATETIME'      => 'date',
                'PICKLIST'      => 'text',
                'BOOLEAN'       => 'boolean',
                'DATE'          => 'date',
                'DATETIME'      => 'datetime',
                'EMAIL'         => 'email',
                'CURRENCY'      => 'currency',
                'PHONE'         => 'phone'



        };
}