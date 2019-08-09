/**
  @file mf_isblank
  @brief Checks whether a macro variable is empty (blank)

  @return output returns 1 (if blank) else 0

  @version 9.2
**/


%macro mf_isblank(param
)/*/STORE SOURCE*/;

  %sysevalf(%superq(param)=,boolean)

%mend;