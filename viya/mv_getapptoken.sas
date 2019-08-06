/**
  @file
  @brief Get an App Token and Secret
  @details When building apps on SAS Viya, an app id and secret is required.
  This macro will obtain the Consul Token and use that to call the Web Service.

    more info: https://developer.sas.com/reference/auth/#register
    and: http://proc-x.com/2019/01/authentication-to-sas-viya-a-couple-of-approaches/

  The default viyaroot location is /opt/sas/viya/config

  M3 required due to proc http headers

  Usage:

    filename mc url "https://raw.githubusercontent.com/Boemska/macrocore/master/macrocore.sas";
    %inc mc;

    %mv_getapptoken(client_id=client,client_secret=secret)

  @param client_id= The client name
  @param client_secret= client secret
  @param grant_type= valid values are "password" or "authorization_code" (unquoted)

  @version VIYA V.03.04
  @author Allan Bowe
  @source https://github.com/Boemska/macrocore

  <h4> Dependencies </h4>
  @li mf_abort.sas
  @li mf_getuniquefileref.sas
  @li mf_getuniquelibref.sas
  @li mf_loc.sas

**/

%macro mv_getapptoken(client_id=someclient
    ,client_secret=somesecret
    ,grant_type=authorization_code
  );
%local consul_token fname1 fname2 fname3 libref access_token;

%mf_abort(iftrue=(&grant_type ne authorization_code and &grant_type ne password)
  ,mac=&sysmacroname
  ,msg=%str(Invalid value for grant_type: &grant_type)
)
options noquotelenmax;
/* first, get consul token needed to get client id / secret */
data _null_;
  infile "%mf_loc(VIYACONFIG)/etc/SASSecurityCertificateFramework/tokens/consul/default/client.token";
  input token:$64.;
  call symputx('consul_token',token);
run;

/* request the client details */
%let fname1=%mf_getuniquefileref();
filename &fname1 TEMP;
proc http method='POST' out=&fname1
    url='http://localhost/SASLogon/oauth/clients/consul?callback=false&serviceId=app';
    headers "X-Consul-Token"="&consul_token";
run;

%let libref=%mf_getuniquelibref();
libname &libref JSON fileref=&fname1;

/* extract the token */
data _null_;
  set &libref..root;
  call symputx('access_token',access_token);
run;
%put &=access_token;

/**
 * register the new client
 */
%let fname2=%mf_getuniquefileref();
filename &fname2 TEMP;
data _null_;
  file &fname2;
  clientid=quote(trim(symget('client_id')));
  clientsecret=quote(trim(symget('client_secret')));
  granttype=quote(trim(symget('grant_type')));
  put '{"client_id":' clientid ',"client_secret":' clientsecret
    ',"scope":"openid","authorized_grant_types": [' granttype ',"refresh_token"],'
    '"redirect_uri": "urn:ietf:wg:oauth:2.0:oob"}';
run;
data _null_;
  infile &fname2;
  input;
  putlog _infile_;
run;

%let fname3=%mf_getuniquefileref();
filename &fname3 TEMP;
proc http method='POST' in=&fname2 out=&fname3
    url='http://localhost/SASLogon/oauth/clients';
    headers "Content-Type"="application/json"
            "Authorization"="Bearer &access_token";
run;

/* show response */
data _null_;
  infile &fname3;
  input;
  putlog _infile_;
run;

%put Please provide the following details to the developer:;
%put ;
%put CLIENT_ID=&client_id;
%put CLIENT_SECRET=&client_secret;
%put GRANT_TYPE=&grant_type;
%put;
%if &grant_type=authorization_code %then %do;
  %put The developer must also register below and select 'openid' to get the grant code:;
  %put ;
  %put &SYSTCPIPHOSTNAME/SASLogon/oauth/authorize?client_id=&client_id%str(&)response_type=code;
  %put; %put;
%end;

/* clear refs */
filename &fname1 clear;
filename &fname2 clear;
filename &fname3 clear;
libname &libref clear;

%mend;