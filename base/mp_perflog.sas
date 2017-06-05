/**
  @file
  @brief Logs the time the macro was executed in a control dataset.
  @details If the dataset does not exist, it is created.  Usage:

    %mp_perflog(started)
    %mp_perflog()
    %mp_perflog(startanew,libds=work.newdataset)
    %mp_perflog(finished,libds=work.newdataset)
    %mp_perflog(finished)


  @param label Provide label to go into the control dataset
  @param libds= Provide a dataset in which to store performance stats.  Default
              name is <code>work.mp_perflog</code>;

  @version 9.2
  @author Allan Bowe
  @source https://github.com/macropeople/macrocore
  @copyright GNU GENERAL PUBLIC LICENSE v3
**/

%macro mp_perflog(label,libds=work.mp_perflog);

  %if not (%mf_existds(&libds)) %then %do;
    data &libds;
      length sysjobid $10 label $50 dttm 8.;
      format dttm datetime19.3;
      call missing(of _all_);
      stop;
    run;
  %end;

  proc sql;
    insert into &libds values ("&sysjobid","&label",%sysfunc(datetime()));
  quit;

%mend;