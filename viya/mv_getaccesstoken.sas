/**
  @file
  @brief Get Access and Refresh Tokens
  @details Before an access token can be obtained, the client token must be
    registered by an administrator.  This can be done using the following macro:

      %mv_getapptoken(client_id=client,client_secret=secret)

  Usage:

    filename mc url "https://raw.githubusercontent.com/Boemska/macrocore/master/macrocore.sas";
    %inc mc;

    %let client=testings;
    %let secret=MySecret;

    %mv_getapptoken(client_id=&client,client_secret=&secret)

    %mv_getaccesstoken(client_id=&client,client_secret=&secret,code=LD39EpalOf)

    A great article for explaining all these steps is available here:

    http://proc-x.com/2019/01/authentication-to-sas-viya-a-couple-of-approaches/

  @param client_id= The client name
  @param client_secret= client secret
  @param grant_type= valid values are "password" or "authorization_code" (unquoted).
    The default is authorization_code.
  @param code= If grant_type=authorization_code then provide the necessary code here
  @param user= If grant_type=password then provide the username here
  @param pass= If grant_type=password then provide the password here
  @param access_token_var= The global macro variable to contain the access token
  @param refresh_token_var= The global macro variable to contain the refresh token

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

%local fref1 fref2 libref;

/* test the validity of inputs */
%mf_abort(iftrue=(&grant_type ne authorization_code and &grant_type ne password)
  ,mac=&sysmacroname
  ,msg=%str(Invalid value for grant_type: &grant_type)
)

%mf_abort(iftrue=(&grant_type=authorization_code and %str(&code)=%str())
  ,mac=&sysmacroname
  ,msg=%str(Authorization code required)
)

%mf_abort(iftrue=(&grant_type=password and (%str(&user)=%str() or %str(&pass)=%str()))
  ,mac=&sysmacroname
  ,msg=%str(username / password required)
)

%mf_abort(iftrue=(%str(&client)=%str() or %str(&secret)=%str())
  ,mac=&sysmacroname
  ,msg=%str(client / secret must both be provided)
)

/* prepare appropriate grant type */
%let fref1=%mf_getuniquefileref();
filename &fref1 TEMP;

data _null_;
  file &fref1;
  if "&grant_type"='authorization_code' then string=cats(
   'grant_type=authorization_code&code=',symget('code'));
  else string=cats('grant_type=password&username=',symget('user')
    ,'&password=',symget(pass));
  call symputx('grantstring',cats("'",string,"'"));
run;
data _null_;infile &fref1;input;put _infile_;run;

/**
 * Request access token
 */
%let fref2=%mf_getuniquefileref();
filename &fref2 TEMP;
proc http method='POST' in=&grantstring out=&fref2
  url='localhost/SASLogon/oauth/token'
  WEBUSERNAME="&client_id"
  WEBPASSWORD="&client_secret"
  AUTH_BASIC;
  headers "Accept"="application/json"
          "Content-Type"="application/x-www-form-urlencoded";
run;
data _null_;infile &fref2;input;put _infile_;run;

/**
 * Extract access / refresh tokens
 */

%let libref=%mf_getuniquelibref();
libname &libref JSON fileref=&fref2;

/* extract the token */
data _null_;
  set &libref..root;
  call symputx("&access_token_var",access_token);
  call symputx("&refresh_token_var",refresh_token);
run;

%put &=&access_token_var;
%put &=&refresh_token_var;

libname &libref clear;
filename &fref1 clear;
filename &fref2 clear;

%mend;