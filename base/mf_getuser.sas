/**
  @file
  @brief Returns <code>&sysuserid</code> in Workspace session, <code>
    &_secureusername</code> in Stored Process session.
  @details In a workspace session, a user is generally represented by <code>
    &sysuserid</code>.  In a Stored Process session, <code>&sysuserid</code>
    resolves to a system account (default=sassrv) and instead there are several
    metadata username variables to choose from (_metauser, _metaperson
    ,_username, _secureusername).  The OS account is represented by
    <code> _secureusername</code> whilst the metadata account is under <code>
    _metaperson</code>.

        %let user= %mf_getUser();
        %put &user;
  @param type META returns _metaperson, OS returns _secureusername.  Each of
    these are scanned to remove any @domain extensions (which can happen after
    a password change).

  @return sysuserid (if workspace server)
  @return _secureusername or _metaperson (if stored process server)

  @version 9.2
  @author Allan Bowe
  @copyright GNU GENERAL PUBLIC LICENSE v3
**/

%macro mf_getuser(type=META
)/*/STORE SOURCE*/;
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
