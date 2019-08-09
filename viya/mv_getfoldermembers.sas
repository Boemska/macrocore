/**
  @file mv_getfoldermembers.sas
  @brief Gets a list of folders (and ids) for a given root
  @details Works for both root level and below, oauth or password. Default is
    oauth, and the token is expected in a global ACCESS_TOKEN variable.

    %mv_getfoldermembers(root=/Public)


  @param root= The path for which to return the list of folders
  @param outds= The output dataset to create (default is work.mv_getfolders)
  @param access_token_var= The global macro variable to contain the access token
  @param grant_type= valid values are "password" or "authorization_code" (unquoted).
    The default is authorization_code.


  @version VIYA V.03.04
  @author Allan Bowe
  @source https://github.com/Boemska/macrocore

  <h4> Dependencies </h4>
  @li mf_abort.sas
  @li mf_getuniquefileref.sas
  @li mf_getuniquelibref.sas
  @li mf_isblank.sas

**/

%macro mv_getfoldermembers(root=/
    ,access_token_var=ACCESS_TOKEN
    ,grant_type=authorization_code
    ,outds=mv_getfolders
  );

%if %mf_isblank(&root)=1 %then %let root=/;

%mf_abort(iftrue=(&grant_type ne authorization_code and &grant_type ne password)
  ,mac=&sysmacroname
  ,msg=%str(Invalid value for grant_type: &grant_type)
)
options noquotelenmax;

/* request the client details */
%local fname1 libref1;
%let fname1=%mf_getuniquefileref();
filename &fname1 TEMP;
%let libref1=%mf_getuniquelibref();

%if "&root"="/" %then %do;
  /* if root just list root folders */
  proc http method='GET' out=&fname1
      url='http://localhost/folders/rootFolders';
      headers "Authorization"="Bearer &&&access_token_var";
  run;
  libname &libref1 JSON fileref=&fname1;
  data &outds;
    set &libref1..items;
  run;
%end;
%else %do;
  /* first get parent folder id */
  proc http method='GET' out=&fname1
      url="http://localhost/folders/folders/@item?path=&root";
      headers "Authorization"="Bearer &&&access_token_var";
  run;
  data _null_;infile &fname1;input;putlog _infile_;run;
  libname &libref1 JSON fileref=&fname1;
  /* now get the followon link to list members */
  data _null_;
    set &libref1..links;
    if rel='members' then call symputx('href',quote(trim(href)),'l');
  run;
  %local fname2 libref2;
  %let fname2=%mf_getuniquefileref();
  filename &fname2 TEMP;
  %let libref2=%mf_getuniquelibref();
  proc http method='GET' out=&fname2
      url=%unquote(%superq(href));
      headers "Authorization"="Bearer &&&access_token_var";
  run;
  libname &libref2 JSON fileref=&fname2;
  data &outds;
    set &libref2..items;
  run;
  filename &fname2 clear;
  libname &libref2 clear;
%end;


/* clear refs */
filename &fname1 clear;
libname &libref1 clear;

%mend;