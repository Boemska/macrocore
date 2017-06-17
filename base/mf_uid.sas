/**
  @file
  @brief Creates a Unique ID based on system time in a friendly format
  @details format = YYYYMMDD_HHMMSS_<sysjobid>_<3randomDigits>

        %put %mf_uid();

  @version 9.2
  @author Allan Bowe
  @copyright GNU GENERAL PUBLIC LICENSE v3
**/

%macro mf_uid();
  %local today now;
  %let today=%sysfunc(today(),yymmddn8.);
  %let now=%sysfunc(compress(%sysfunc(time(),time8.),:));

  &today._&now._&sysjobid._%sysevalf(%sysfunc(ranuni(0))*1000,CEIL)

%mend;