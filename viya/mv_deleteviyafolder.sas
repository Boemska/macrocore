/**
  @file mv_deleteviyafolder.sas
  @brief Creates a viya folder if that foloder does not already exist
  @details Expects oauth token in a global macro variable (default
    ACCESS_TOKEN).

    options mprint;
    %mv_createfolder(path=/Public/test/blah)
    %mv_deleteviyafolder(path=/Public/test)


  @param path= The full path of the folder to be deleted
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

%macro mv_deleteviyafolder(path=
    ,access_token_var=ACCESS_TOKEN
    ,grant_type=authorization_code
  );

%mf_abort(iftrue=(%mf_isblank(&path)=1)
  ,mac=&sysmacroname
  ,msg=%str(path value must be provided)
)
%mf_abort(iftrue=(%length(&path)=1)
  ,mac=&sysmacroname
  ,msg=%str(path value must be provided)
)
%mf_abort(iftrue=(&grant_type ne authorization_code and &grant_type ne password)
  ,mac=&sysmacroname
  ,msg=%str(Invalid value for grant_type: &grant_type)
)

options noquotelenmax;

%put &sysmacroname: fetching details for &path ;
%local fname1;
%let fname1=%mf_getuniquefileref();
proc http method='GET' out=&fname1
  url="http://localhost/folders/folders/@item?path=&path";
  headers "Authorization"="Bearer &&&access_token_var";
run;
/*data _null_;infile &fname1;input;putlog _infile_;run;*/
%mf_abort(iftrue=(&SYS_PROCHTTP_STATUS_CODE ne 200)
  ,mac=&sysmacroname
  ,msg=%str(&SYS_PROCHTTP_STATUS_CODE &SYS_PROCHTTP_STATUS_PHRASE)
)

%put &sysmacroname: grab the follow on link ;
%local libref1;
%let libref1=%mf_getuniquelibref();
libname &libref1 JSON fileref=&fname1;
data _null_;
  set &libref1..links;
  if rel='deleteRecursively' then
    call symputx('href',quote(trim(href)),'l');
run;

%put &sysmacroname: perform the delete operation ;
%local fname2;
%let fname2=%mf_getuniquefileref();
proc http method='DELETE'
    out=&fname2
    url=%unquote(%superq(href));
    headers "Authorization"="Bearer &&&access_token_var"
            'Accept'='*/*'; /**/
run;

%mf_abort(iftrue=(&SYS_PROCHTTP_STATUS_CODE ne 204)
  ,mac=&sysmacroname
  ,msg=%str(&SYS_PROCHTTP_STATUS_CODE &SYS_PROCHTTP_STATUS_PHRASE)
)

%put &sysmacroname: &path successfully deleted;

/* clear refs */
filename &fname1 clear;
filename &fname2 clear;
libname &libref1 clear;

%mend;