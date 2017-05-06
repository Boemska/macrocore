/**
  @file
  @brief Assigns a library using meta engine via LIBREF
  @details Queries metadata to get the library NAME which can then be used in
    a libname statement with the meta engine.

  usage:

      %mm_assign_lib(SOMEREF);

  @param libref the libref (not name) of the metadata library
  @param mDebug= set to anything but * or 0 to show debug messages in the log
  @param mAbort= set to anything but * or 0 to call %mf_abort().

  @returns libname statement

  @version 9.2
  @author Macro People Ltd
  @copyright GNU GENERAL PUBLIC LICENSE v3

**/

%macro mm_assignlib(
     libref
    ,mDebug=%str(*)
    ,mAbort=%str(*)
  );
%if &mDebug=0 %then %let mDebug=%str(*);
%else %if %str(&mDebug) ne %str(*) %then %let mDebug=;
%if &mAbort=0 %then %let mAbort=%str(*);
%else %if %str(&mAbort) ne %str(*) %then %let mAbort=;

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