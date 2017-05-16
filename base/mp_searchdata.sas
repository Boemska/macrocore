/**
  @file
  @brief Searches all character data in a library for a particular string
  @details
  Scans an entire library and creates a copy of any table
    containing a specific string in the work library.
    Only those records containing the string are written.
  Usage:

      %mp_searchdata(lib=sashelp, string=Jan)

  Outputs zero or more tables to an MPSEARCH library with specific records.

  Only searches character columns!

  @version 9.2
  @author Macro People Ltd
**/

%macro mp_searchdata(lib=sashelp
  ,ds= /* this macro will be upgraded to work for single datasets also */
  ,type=C /* this macro will be updated to work for numeric data also */
  ,string=Jan
  ,outloc=%sysfunc(pathname(work))/mpsearch
);

%local table_list table table_num table colnum col start_tm vars;
%put process began at %sysfunc(datetime(),datetime19.);

%mf_mkdir(&outloc)
libname mpsearch "&outloc";

/* get the list of tables in the library */
proc sql noprint;
select distinct memname into: table_list separated by ' '
  from dictionary.tables where upcase(libname)="%upcase(&lib)";
/* check that we have something to check */
proc sql;
%if %length(&table_list)=0 %then %put library &lib contains no tables!;
/* loop through each table */
%else %do table_num=1 %to %sysfunc(countw(&table_list,%str( )));
  %let table=%scan(&table_list,&table_num,%str( ));
  %let vars=%mf_getvarlist(&lib..&table);
  /* build sql statement */
  create table mpsearch.&table as select * from &lib..&table
    where 0
 /* loop through columns */
  %do colnum=1 %to %sysfunc(countw(&vars,%str( )));
    %let col=%scan(&vars,&colnum,%str( ));
    %put &col;
    %if %mf_getvartype(&lib..&table,&col)=C %then %do;
      /* if a char column, see if it contains the string */
      or (&col ? "&string")
    %end;
  %end;
  ;
  %if %mf_nobs(mpsearch.&table)=0 %then %do;
    drop table mpsearch.&table;
  %end;
%end;

%put process finished at %sysfunc(datetime(),datetime19.);

%mend;