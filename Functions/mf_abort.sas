/**
  @file
  @brief abort gracefully according to context
  @details Can configure an abort mechanism according to site specific policies
    or the particulars of an environment.  For instance, can stream custom
    results back to the client in an STP Web App context, or completely stop
    in the case of a batch run.

  @param mac (keyword) - to contain the name of the calling macro
  @param type (keyword) - enables custom error handling to be configured
  @param msg (keyword) - message to be returned

  @version 9.2
  @author Macro People Ltd
  @copyright GNU GENERAL PUBLIC LICENSE v3
**/

%macro mf_abort(mac=, type=, msg=);
  %put ERROR: ///  mf_abort macro executing //;
  %if %length(&mac)>0 %then %put ERROR - called by &mac;
  %put ERROR - &msg;

  /* Stored Process Server web app context */
  %if %symexist(_metaperson) %then %do;
    data _null_;
      file _webout mod;
      put "msg=&msg";
      put "mac=&mac";
    run;
  %end;

  %put _all_;
  %abort cancel;
%mend;