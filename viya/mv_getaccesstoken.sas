/**
  @file
  @brief Get an additional access token using a refresh token
  @details Before an access token can be obtained, a refresh token is required
    For that, check out the `mv_getrefreshtoken` macro.

  Usage:

    * prep work - register client, get refresh token, save it for later use ;
    %let client=testin88gtss;
    %let secret=MySecret;
    %mv_getapptoken(client_id=&client,client_secret=&secret)
    %mv_getrefreshtoken(client_id=&client,client_secret=&secret,code=wKDZYTEPK6)
    data _null_;
    file "~/refresh.token";
    put "&refresh_token";
    run;

    * now do the things n stuff;
    data _null_;
      infile "~/refresh.token";
      input;
      call symputx('refresh_token',_infile_);
    run;
    %mv_getaccesstoken(client_id=&client
      ,client_secret=&secret
    )

    A great article for explaining all these steps is available here:

    https://blogs.sas.com/content/sgf/2019/01/25/authentication-to-sas-viya/

  @param client_id= The client name
  @param client_secret= client secret
  @param grant_type= valid values are "password" or "authorization_code" (unquoted).
    The default is authorization_code.
  @param user= If grant_type=password then provide the username here
  @param pass= If grant_type=password then provide the password here
  @param access_token_var= The global macro variable to contain the access token
  @param refresh_token_var= The global macro variable containing the refresh token

  @version VIYA V.03.04
  @author Allan Bowe
  @source https://github.com/Boemska/macrocore

  <h4> Dependencies </h4>
  @li mf_abort.sas
  @li mf_getuniquefileref.sas

**/

%macro mv_getaccesstoken(client_id=someclient
    ,client_secret=somesecret
    ,grant_type=authorization_code
    ,code=
    ,user=
    ,pass=
    ,access_token_var=ACCESS_TOKEN
    ,refresh_token_var=REFRESH_TOKEN
  );
%global &access_token_var &refresh_token_var;
options noquotelenmax;

%local fref1 libref;

/* test the validity of inputs */
%mf_abort(iftrue=(&grant_type ne authorization_code and &grant_type ne password)
  ,mac=&sysmacroname
  ,msg=%str(Invalid value for grant_type: &grant_type)
)

%mf_abort(iftrue=(&grant_type=password and (%str(&user)=%str() or %str(&pass)=%str()))
  ,mac=&sysmacroname
  ,msg=%str(username / password required)
)

%mf_abort(iftrue=(%str(&client)=%str() or %str(&secret)=%str())
  ,mac=&sysmacroname
  ,msg=%str(client / secret must both be provided)
)


/**
 * Request access token
 */
%let fref1=%mf_getuniquefileref();
proc http method='POST'
  in="grant_type=refresh_token%nrstr(&)refresh_token=&&&refresh_token_var"
  out=&fref1
  url='localhost/SASLogon/oauth/token'
  WEBUSERNAME="&client_id"
  WEBPASSWORD="&client_secret"
  AUTH_BASIC;
  headers "Accept"="application/json"
          "Content-Type"="application/x-www-form-urlencoded";
run;
data _null_;infile &fref1;input;put _infile_;run;

/**
 * Extract access / refresh tokens
 */

%let libref=%mf_getuniquelibref();
libname &libref JSON fileref=&fref1;

/* extract the token */
data _null_;
  set &libref..root;
  call symputx("&access_token_var",access_token);
  call symputx("&refresh_token_var",refresh_token);
run;

%put ;
%put &access_token_var=&&&access_token_var;
%put ;
%put &refresh_token_var=&&&refresh_token_var;
%put ;
/*
libname &libref clear;
filename &fref1 clear;
filename &fref2 clear;
*/
%mend;