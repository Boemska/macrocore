/**
  @file
  @brief Logs a key value pair a control dataset
  @details If the dataset does not exist, it is created.  Usage:

    %mp_setkeyvalue(someindex,22,type=N)
    %mp_setkeyvalue(somenewindex,somevalue,class=some class)


  @param key Provide a key on which to perform the lookup
  @param value Provide a value
  @param class= Optionally, provide a class.   The PK is class / key.
  @param type= either C or N will populate valc and valn respectively.  C is
               default.
  @param libds= define the target table to hold the parameters

  @version 9.2
  @author Allan Bowe
  @source https://github.com/macropeople/macrocore
  @copyright GNU GENERAL PUBLIC LICENSE v3
**/

%macro mp_setkeyvalue(key,value,type=C,class=,libds=work.mp_setkeyvalue);

  %if not (%mf_existds(&libds)) %then %do;
    data &libds;
      length class $10 key $32 valc $256 valn 8;
      call missing(of _all_);
      stop;
    run;
  %end;

  proc sql;
    delete from &libds
      where class=coalescec(symget('class'),'') and key=symget('key');
    insert into &libds
      set class=symget('class')
        ,key=symget('key')
  %if &type=C %then %do;
        ,valc=symget('value')
  %end;
  %else %do;
        ,valn=symgetn('value')
  %end;
  ;
  quit;

%mend;