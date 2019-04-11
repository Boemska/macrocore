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
  %if not %symexist(h54sDebuggingMode) %then %do;
    %let h54sDebuggingMode=0;
  %end;
  /* Stored Process Server web app context */
  %if %symexist(_metaperson) %then %do;
    options obs=max replace nosyntaxcheck mprint;
    /* extract log error / warning, if exist */
    %local logloc logline;
    %global logmsg; /* capture global messages */
    %if %symexist(SYSPRINTTOLOG) %then %let logloc=&SYSPRINTTOLOG;
    %else %let logloc=%qsysfunc(getoption(LOG));
    proc printto log=log;run;
    %if %length(&logloc)>0 %then %do;
      %let logline=0;
      data _null_;
        infile &logloc lrecl=5000;
        input; putlog _infile_;
        i=1;
        retain logonce 0;
        if (_infile_=:'WARNING' or _infile_=:'ERROR') and logonce=0 then do;
          call symputx('logline',_n_);
          logonce+1;
        end;
      run;
      /* capture log including lines BEFORE the error */
      %if &logline>0 %then %do;
        data _null_;
          infile &logloc lrecl=5000;
          input;
          i=1;
          stoploop=0;
          if _n_ ge &logline-5 and stoploop=0 then do until (i>12);
            call symputx('logmsg',catx('\n',symget('logmsg'),_infile_));
            input;
            i+1;
            stoploop=1;
          end;
          if stoploop=1 then stop;
        run;
      %end;
    %end;

    /* send response in Boemska h54s JSON format */
    data _null_;
      file _webout mod lrecl=32000;
      length msg $32767;
      if symexist('usermessage') then usermessage=quote(trim(symget('usermessage')));
      else usermessage='"blank"';
      if symexist('logmessage') then logmessage=quote(trim(symget('logmessage')));
      else logmessage='"blank"';
      sasdatetime=datetime();
      msg=cats(symget('msg'),'\n\nLog Extract:\n',symget('logmsg'));
      /* escape the quotes */
      msg=tranwrd(msg,'"','\"');
      /* ditch the CRLFs as chrome complains */
      msg=compress(msg,,'kw');
      /* quote without quoting the quotes (which are escaped instead) */
      msg=cats('"',msg,'"');
      if symexist('_debug') then debug=symget('_debug');
      if debug=131 then put "--h54s-data-start--";
      put '{"abort" : [{';
      put ' "MSG":' msg ;
      put ' ,"MAC": "' "&mac" '"}],';
      put '"usermessage" : ' usermessage ',';
      put '"logmessage" : ' logmessage ',';
      put '"errormessage" : "aborted by mf_abort macro",';
      put '"requestingUser" : "' "&_metauser." '",';
      put '"requestingPerson" : "' "&_metaperson." '",';
      put '"executingPid" : ' "&sysjobid." ',';
      put '"sasDatetime" : ' sasdatetime ',';
      put '"status" : "success"}';
      if debug=131 then put "--h54s-data-end--";
      rc = stpsrvset('program error', 0);
    run;
    %let syscc=0;
    data _null_;
      abort return 0;
    run;
    endsas;
  %end;

  %put _all_;
  %abort cancel;
%mend;
