/**
  @file
  @brief Returns the position of a variable in dataset (varnum attribute).
  @details Uses varnum function to determine position.

Usage:

    data test;
       format str $1.  num datetime19.;
       stop;
    run;
    %put %mf_getVarNum(libds=test, var=str);
    %put %mf_getVarNum(libds=test, var=num);
    %put %mf_getVarNum(libds=test, var=renegade);

returns:

  > 1

  > 2

  > NOTE: Variable renegade does not exist in test

  @param libds Two part dataset (or view) reference.
  @param var Variable name for which a position should be returned
  @returns outputs variable number

  @author Allan Bowe
  @version 9.2
  @copyright GNU GENERAL PUBLIC LICENSE v3
**/

%macro mf_getVarNum(libds=sashelp.class /* two level ds name */
      , var= /* variable name from which to return the format */
    );
  %local dsid vnum rc;
  /* Open dataset */
  %let dsid = %sysfunc(open(&libds));
  %if &dsid > 0 %then %do;
    /* Get variable number */
    %let vnum = %sysfunc(varnum(&dsid, &var));
    %if(&vnum <= 0) %then %do;
       %put NOTE: Variable &var does not exist in &libds;
       %let vnum = %str( );
    %end;
  %end;
  %else %put dataset &ds not opened! (rc=&dsid);

  /* Close dataset */
  %let rc = %sysfunc(close(&dsid));

  /* Return variable number */
    &vnum.

%mend;