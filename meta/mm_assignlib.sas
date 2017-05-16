/**
  @file
  @brief Assigns a library using meta engine via LIBREF
  @details Queries metadata to get the library NAME which can then be used in
    a libname statement with the meta engine.

  usage:

      %mm_assign_lib(SOMEREF);

  @param libref the libref (not name) of the metadata library
  @param mDebug= set to 1 to show debug messages in the log
  @param mAbort= set to 1 to call %mf_abort().

  @returns libname statement

  @version 9.2
  @author Macro People Ltd
  @copyright GNU GENERAL PUBLIC LICENSE v3

**/

%macro mm_assignlib(
     libref
    ,mDebug=0
    ,mAbort=0
  );
%if &mDebug=1 %then %let mDebug=;
%else %let mDebug=%str(*);
%if &mAbort=1 %then %let mAbort=;
%else %let mAbort=%str(*);

%if %sysfunc(libref(&libref)) %then %do;
  data _null_;
    length lib_uri LibName $200;
    call missing(of _all_);
    nobj=metadata_getnobj("omsobj:SASLibrary?@Libref='&libref'",1,lib_uri);
    if nobj=1 then do;
       rc=metadata_getattr(lib_uri,"Name",LibName);
       call symputx('LIB',libname,'L');
    end;
    else if nobj>1 then do;
      &mDebug.putlog "ERROR: More than one library with libref=&libref";
      &mAbort.call execute('%mf_abort(msg=
        ERROR: More than one library with libref='!!"&libref
        ,mac=mm_assignlib.sas)");
    end;
    else do;
      &mDebug.putlog "ERROR: Library &libref not found in metadata";
      &mAbort.call execute('%mf_abort(msg=ERROR: Library '!!"&libref"
        !!' not found in metadata,mac=mm_assignlib.sas)');
    end;
  run;

  libname &libref meta library="&lib";
  %if %sysfunc(libref(&libref)) %then %do;
    %&mDebug.put ERROR: mm_assignlib macro could not assign &libref;
    %&mAbort.mf_abort(
      msg=ERROR: mm_assignlib macro could not assign &libref
      ,mac=mm_assignlib.sas);
  %end;
%end;
%else %do;
  %&mDebug.put NOTE: Library &libref is already assigned;
%end;
%mend;