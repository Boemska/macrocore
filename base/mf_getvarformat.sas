/**
  @file
  @brief Returns the format of a variable
  @details Uses varfmt function to identify the format of a particular variable.
  Usage:

      data test;
         format str $1.  num datetime19.;
         stop;
      run;
      %put %mf_getVarFormat(test,str);
      %put %mf_getVarFormat(work.test,num);
      %put %mf_getVarFormat(test,renegade);

  returns:

      $1.
      DATETIME19.
      NOTE: Variable renegade does not exist in test

  @param libds Two part dataset (or view) reference.
  @param var Variable name for which a format should be returned
  @returns outputs format

  @author Allan Bowe
  @version 9.2
  @copyright GNU GENERAL PUBLIC LICENSE v3
**/

%macro mf_getVarFormat(libds /* two level ds name */
      , var /* variable name from which to return the format */
)/*/STORE SOURCE*/;
  %local dsid vnum vformat rc;
  /* Open dataset */
  %let dsid = %sysfunc(open(&libds));
  %if &dsid > 0 %then %do;
    /* Get variable number */
    %let vnum = %sysfunc(varnum(&dsid, &var));
    /* Get variable format */
    %if(&vnum > 0) %then %let vformat=%sysfunc(varfmt(&dsid, &vnum));
    %else %do;
       %put NOTE: Variable &var does not exist in &libds;
       %let vformat = %str( );
    %end;
  %end;
  %else %put dataset &libds not opened! (rc=&dsid);

  /* Close dataset */
  %let rc = %sysfunc(close(&dsid));
  /* Return variable format */
  &vformat
%mend;