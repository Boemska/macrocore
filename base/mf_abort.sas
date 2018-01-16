/**
  @file
  @brief abort gracefully according to context
  @details Can configure an abort mechanism according to site specific policies
    or the particulars of an environment.  For instance, can stream custom
    results back to the client in an STP Web App context, or completely stop
    in the case of a batch run.

  @param mac= to contain the name of the calling macro
  @param type= enables custom error handling to be configured
  @param msg= message to be returned
  @param iftrue= supply a condition under which the macro should be executed.

  @version 9.2
  @author Allan Bowe
  @copyright GNU GENERAL PUBLIC LICENSE v3
**/

%macro mf_abort(mac=mf_abort.sas, type=, msg=, iftrue=%str(1=1)
)/*/STORE SOURCE*/;

  %if not(%eval(%unquote(&iftrue))) %then %return;

  %put NOTE: ///  mf_abort macro executing //;
  %if %length(&mac)>0 %then %put NOTE- called by &mac;
  %put NOTE - &msg;

  /* Stored Process Server web app context */
  %if %symexist(_metaperson) %then %do;
    data _null_;
      file _webout mod;
      put "msg=&msg";
      put "mac=&mac";
    run;
    filename _webout clear;
    /* no other way to abort an STP session */
    /* see https://blogs.sas.com/content/sgf/2017/07/28/controlling-stored-process-execution-through-request-initialization-code-injection/*/
    data _null_;
      abort cancel;
    run;
    endsas;
  %end;

  %put _all_;
  %abort cancel;
%mend;