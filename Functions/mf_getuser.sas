/**
  @file
  @brief Returns <code>&sysuserid</code> in Workspace session, <code>
    &_secureusername</code> in Stored Process session.
  @details In a workspace session, a user is generally represented by <code>
    &sysuserid</code>.  In a Stored Process session, <code>&sysuserid</code>
    resolves to a system account (default=sassrv) and instead there are several
    metadata username variables to choose from (_metauser, _metaperson
    ,_username, _secureusername).  Of these, _secureusername is the most
    consistent.  This is also scanned to remove any potential @domain extension.

        %let user= %mf_getUser();
        %put &user;
  @param type META returns _metaperson, OS returns _secureusername.  Each of
    these are scanned to remove any @domain extensions (which can happen after
    a password change).

  @return sysuserid (if workspace server)
  @return _secureusername (if stored process server)

  @version 9.2
  @author Allan Bowe
  @copyright GNU GENERAL PUBLIC LICENSE v3
**/

%macro mf_getuser(type=META);
  %local user metavar;
  %if &type=OS %then %let metavar=_secureusername;
  %else %let metavar=_metaperson;

  %if %symexist(&metavar) %then %do;
    %if %length(&&&metavar)=0 %then %let user=&sysuserid;
    /* sometimes SAS will add @domain extension - remove for consistency */
    %else %let user=%scan(&&&metavar,1,@);
  %end;
  %else %let user=&sysuserid;

  %quote(&user)

%mend;
