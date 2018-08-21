/**
  @file
  @brief Assigns a meta engine library using LIBREF
  @details Queries metadata to get the library NAME which can then be used in
    a libname statement with the meta engine.

  usage:

      %mm_assign_lib(SOMEREF);

  <h4> Dependencies </h4>
  @li mf_abort.sas

  @param libref the libref (not name) of the metadata library
  @param mDebug= set to 1 to show debug messages in the log
  @param mAbort= set to 1 to call %mf_abort().

  @returns libname statement

  @version 9.2
  @author Allan Bowe
  @copyright GNU GENERAL PUBLIC LICENSE v3

**/

%macro mm_assignlib(
     libref
    ,mDebug=0
    ,mAbort=0
)/*/STORE SOURCE*/;

%local mD;
%if &mDebug=1 %then %let mD=;
%else %let mD=%str(*);
%&mD.put Executing mm_assignlib.sas;
%&mD.put _local_;

%if &mAbort=1 %then %let mAbort=;
%else %let mAbort=%str(*);

%if %sysfunc(libref(&libref)) %then %do;
  %local mf_abort msg; %let mf_abort=0;
  data _null_;
    length lib_uri LibName $200;
    call missing(of _all_);
    nobj=metadata_getnobj("omsobj:SASLibrary?@Libref='&libref'",1,lib_uri);
    if nobj=1 then do;
       rc=metadata_getattr(lib_uri,"Name",LibName);
       put (_all_)(=);
       call symputx('LIB',libname,'L');
    end;
    else if nobj>1 then do;
      call symputx('mf_abort',1);
      call symputx('msg',"More than one library with libref=&libref");
    end;
    else do;
      call symputx('mf_abort',1);
      call symputx('msg',"Library &libref not found in metadata");
    end;
  run;
  %mf_abort(iftrue= (&mf_abort=1)
    ,mac=mm_assignlib.sas
    ,msg=&msg
  )
  libname &libref meta library="&lib";
  %if %sysfunc(libref(&libref)) %then %do;
    %mf_abort(msg=mm_assignlib macro could not assign &libref
      ,mac=mm_assignlib.sas);
  %end;
%end;
%else %do;
  %&mD.put NOTE: Library &libref is already assigned;
%end;
%mend;