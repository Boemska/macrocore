/**
  @file
  @brief Configures a non STP session like an STP session
  @details When running a web enabled STP in batch mode, there are a few things
    that need to be configured to avoid errors - such as setting up the _webout
    fileref, or providing dummy h54s macros.

  @version 9.2
  @author Allan Bowe
  @source https://github.com/Boemska/macrocore
  @copyright GNU GENERAL PUBLIC LICENSE v3
**/

%macro mp_stpsetup(
)/*/STORE SOURCE*/;

%if &sysprocessmode ne SAS Stored Process Server %then %do;
  filename _webout cache; /* cache mode enables pdf etc output */

  /* h54s macros need to have global scope */
  data _null_;
    call execute('%macro hfsheader();%mend;%macro hfsfooter();%mend;');
    call execute('%macro hfsOutDataset(one,two,three);%mend;');
    call execute('%macro hfsGetDataset(one,two);%mend;');
  run;
%end;
%mend;