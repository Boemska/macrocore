/**
  @file
  @brief Checks whether a dataset OR a view exists.
  @details Can be used in open code, eg as follows:

      %if %mf_existds(libds=work.someview) %then %put  yes it does!;

  @param libds library.dataset
  @return output returns 1 or 0
  @warning Not yet tested on tables registered in metadata but not
      physically present
  @version 9.2
  @author Allan Bowe
  @copyright GNU GENERAL PUBLIC LICENSE v3
**/

%macro mf_existds(libds
)/*/STORE SOURCE*/;
/* if exist() finds no dataset, it could still be there in a case sensitive
   database / environment.  So try to actually open it to make sure. */
%if %sysfunc(exist(&libds)) ne 1 & %sysfunc(exist(&libds,VIEW)) ne 1 %then %do;
  %if %sysfunc(close(%sysfunc(open(&libds,i))))=0 %then 1;
  %else 0;
%end;
%else 1;

%mend;