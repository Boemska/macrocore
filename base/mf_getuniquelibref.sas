/**
  @file
  @brief Returns an unused libref
  @details Use as follows:

    libname mcore0 (work);
    libname mcore1 (work);
    libname mcore2 (work);

    %let libref=%mf_getuniquelibref();
    %put &=libref;

  which returns:

> mcore3

  @prefix= first part of libref.  Remember that librefs can only be 8 characters,
    so a 7 letter prefix would mean that maxtries should be 10.
  @param maxtries= the last part of the libref.  Provide an integer value.

  @version 9.2
  @author Allan Bowe
**/


%macro mf_getuniquelibref(prefix=mcore,maxtries=1000);
  %local x;
  %let x=0;
  %do x=0 %to &maxtries;
  %if %sysfunc(libref(&prefix&x)) ne 0 %then %do;
      %put Libref &prefix&x is available!;
      &prefix&x
      %return;
  %end;
  %end;
  %put unable to find available libref in range &prefix.0-&maxtries;
%mend;