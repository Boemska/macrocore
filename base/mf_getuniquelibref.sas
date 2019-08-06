/**
  @file
  @brief Returns an unused libref
  @details Use as follows:

    libname mclib0 (work);
    libname mclib1 (work);
    libname mclib2 (work);

    %let libref=%mf_getuniquelibref();
    %put &=libref;

  which returns:

> mclib3

  @prefix= first part of libref.  Remember that librefs can only be 8 characters,
    so a 7 letter prefix would mean that maxtries should be 10.
  @param maxtries= the last part of the libref.  Provide an integer value.

  @version 9.2
  @author Allan Bowe
**/


%macro mf_getuniquelibref(prefix=mclib,maxtries=1000);
  %local x;
  %let x=0;
  %do x=0 %to &maxtries;
  %if %sysfunc(libref(&prefix&x)) ne 0 %then %do;
      %put Libref &prefix&x was available and returned by &sysmacroname;
      &prefix&x
      %return;
  %end;
  %end;
  %put unable to find available libref in range &prefix.0-&maxtries;
%mend;