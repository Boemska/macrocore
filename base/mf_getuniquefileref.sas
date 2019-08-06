/**
  @file
  @brief Returns an unused fileref
  @details Use as follows:

    filename mcore0 temp;
    filename mcore1 temp;

    %let fileref=%mf_getuniquefileref();
    %put &=fileref;

  which returns:

> mcore2

  @prefix= first part of fileref. Remember that filerefs can only be 8
    characters, so a 7 letter prefix would mean that `maxtries` should be 10.
  @param maxtries= the last part of the libref.  Provide an integer value.

  @version 9.2
  @author Allan Bowe
**/

%macro mf_getuniquefileref(prefix=mcore,maxtries=1000);
  %local x;
  %let x=0;
  %do x=0 %to &maxtries;
  %if %sysfunc(fileref(&prefix&x)) > 0 %then %do;
      %put Fileref &prefix&x is available!;
      &prefix&x
      %return;
  %end;
  %end;
  %put unable to find available fileref in range &prefix.0-&maxtries;
%mend;