/**
  @file mv_createwebservice.sas
  @brief Creates a JobExecution object if it doesn't already exist
  @details Expects oauth token in a global macro variable (default
    ACCESS_TOKEN).

    options mprint;
    filename mycode temp;
    data _null_;
      file mycode;
      put "data;file _webout; put 'Hello, wurrld';run;";
    run;
    %mv_createwebservice(path=/Public, name=testJob, precode=mycode)

  for more info: https://developer.sas.com/apis/rest/Compute/#create-a-job-definition

  @param path= The full path where the service will be created
  @param name= The name of the service
  @param desc= The description of the service
  @param precode= FILEREF of code to be attached to the beginning of the service
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

%macro mv_createwebservice(path=
    ,name=
    ,desc=Created by the mv_createwebservice.sas macro
    ,precode=
    ,access_token_var=ACCESS_TOKEN
    ,grant_type=authorization_code
  );
/* initial validation checking */
%mf_abort(iftrue=(%mf_isblank(&path)=1)
  ,mac=&sysmacroname
  ,msg=%str(path value must be provided)
)
%mf_abort(iftrue=(%length(&path)=1)
  ,mac=&sysmacroname
  ,msg=%str(path value must be provided)
)
%mf_abort(iftrue=(%mf_isblank(&name)=1)
  ,mac=&sysmacroname
  ,msg=%str(name value must be provided)
)
%mf_abort(iftrue=(&grant_type ne authorization_code and &grant_type ne password)
  ,mac=&sysmacroname
  ,msg=%str(Invalid value for grant_type: &grant_type)
)

options noquotelenmax;

/* fetching folder details for provided path */
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

/* path exists. Grab follow on link to check members */
%local libref1;
%let libref1=%mf_getuniquelibref();
libname &libref1 JSON fileref=&fname1;
data _null_;
  set &libref1..links;
  if rel='members' then call symputx('membercheck',quote(trim(href)),'l');
  else if rel='self' then call symputx('parentFolderUri',href,'l');
run;
data _null_;
  set &libref1..root;
  call symputx('folderid',id,'l');
run;
%local fname2;
%let fname2=%mf_getuniquefileref();
proc http method='GET'
    out=&fname2
    url=%unquote(%superq(membercheck));
    headers "Authorization"="Bearer &&&access_token_var"
            'Accept'='application/vnd.sas.collection+json'
            'Accept-Language'='string';
run;
/*data _null_;infile &fname2;input;putlog _infile_;run;*/
%mf_abort(iftrue=(&SYS_PROCHTTP_STATUS_CODE ne 200)
  ,mac=&sysmacroname
  ,msg=%str(&SYS_PROCHTTP_STATUS_CODE &SYS_PROCHTTP_STATUS_PHRASE)
)

/* check that job does not already exist in that folder */
%local libref2;
%let libref2=%mf_getuniquelibref();
libname &libref2 JSON fileref=&fname2;
%local exists; %let exists=0;
data _null_;
  set &libref2..items;
  if contenttype='jobDefinition' and upcase(name)="%upcase(&name)" then
    call symputx('exists',1,'l');
run;
%mf_abort(iftrue=(&exists=1)
  ,mac=&sysmacroname
  ,msg=%str(Job &name already exists in &path)
)

%local fname3;
%let fname3=%mf_getuniquefileref();
data _null_;
  file &fname3 TERMSTR=' ';
  string=cats('{"version": 0,"name":"'
  	,"&name"
  	,'","type":"Compute","parameters":[{"name":"_addjesbeginendmacros"'
    ,',"type":"CHARACTER","defaultValue":"false"}]'
    ,',"code":"');
  put string @@;
  put 'filename _webout temp;';
run;

data _null_;
  infile &precode;
  file &fname3 TERMSTR=' ' mod;
  input;
  put _infile_;
run;

data _null_;
  file &fname3 mod TERMSTR=' ';
  put 'filename _web filesrvc parenturi=\"&SYS_JES_JOB_URI\" name=\"_webout.htm\";' @@;
  put '%let rc=%sysfunc(fcopy(_webout,_web)); %put &=rc;' @@;
  put '"}';
run;

/* now we can create the job!! */
%local fname4;
%let fname4=%mf_getuniquefileref();
proc http method='POST'
    in=&fname3
    out=&fname4
    url="/jobDefinitions/definitions?parentFolderUri=&parentFolderUri";
    headers 'Content-Type'='application/vnd.sas.job.definition+json'
            "Authorization"="Bearer &&&access_token_var"
            "Accept"="application/vnd.sas.job.definition+json";
run;
data _null_;infile &fname4;input;putlog _infile_;run;
%mf_abort(iftrue=(&SYS_PROCHTTP_STATUS_CODE ne 201)
  ,mac=&sysmacroname
  ,msg=%str(&SYS_PROCHTTP_STATUS_CODE &SYS_PROCHTTP_STATUS_PHRASE)
)

%put &sysmacroname: Job &name successfully created in &path;


/* clear refs */

filename &fname1 clear;
filename &fname2 clear;
filename &fname3 clear;
filename &fname4 clear;
libname &libref1 clear;
libname &libref2 clear;

%mend;