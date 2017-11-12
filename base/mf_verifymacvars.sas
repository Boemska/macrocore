/**
  @file
  @brief Checks if a set of macro variables exist / contain values.
  @details Writes ERROR to log if abortType is SOFT, else will call %mf_abort.
  Usage:

      %let var1=x;
      %let var2=y;
      %put %mf_verifymacvars(var1 var2);

  Returns:
  > 1

  @param verifyvars space separated list of macro variable names
  @param makeupcase= set to YES to convert all variable VALUES to
    uppercase.
  @param mAbort= Abort Type.  Default is SOFT (writes error to log).
    Set to any other value to call mf_abort (which can be configured to abort in
    various fashions according to context).

  @warning will not be able to verify the following variables due to
    naming clash!
      - verifyVars
      - verifyVar
      - verifyIterator
      - makeUpcase

  @version 9.2
  @author Allan Bowe
  @copyright GNU GENERAL PUBLIC LICENSE v3
**/


%macro mf_verifymacvars(
     verifyVars  /* list of macro variable NAMES */
    ,makeUpcase=NO  /* set to YES to make all the variable VALUES uppercase */
    ,mAbort=SOFT
)/*/STORE SOURCE*/;

  %local verifyIterator verifyVar abortmsg;
  %do verifyIterator=1 %to %sysfunc(countw(&verifyVars,%str( )));
    %let verifyVar=%qscan(&verifyVars,&verifyIterator,%str( ));
    %if not %symexist(&verifyvar) %then %do;
      %let abortmsg= Variable &verifyVar is MISSING;
      %goto exit_error;
    %end;
    %if %length(&&&verifyVar)=0 %then %do;
      %let abortmsg= Variable &verifyVar is EMPTY;
      %goto exit_error;
    %end;
    %if &makeupcase=YES %then %do;
      %let &verifyVar=%upcase(&&&verifyvar);
    %end;
  %end;

  %goto exit_success;
  %exit_error:
    %if &mAbort=SOFT %then %put ERROR: &abortmsg;
    %else %mf_abort(mac=mf_verifymacvars,type=&mfabort,msg=&abortmsg);
  %exit_success:

%mend;
