/**
  @file
  @brief Create a type 1 Stored Process (9.2 compatible)
  @details This macro creates a Type 1 stored process, and also the necessary
    PromptGroup / File / TextStore objects.  It requires the location (or uri)
    for the App Server / Directory / Folder (Tree) objects.
    To upgrade this macro to work with type 2 (which can embed SAS code
    and is compabitible with SAS from 9.3 onwards) then the UsageVersion should
    change to 2000000 and the TextStore object updated.  The ComputeServer
    reference will also be to ServerContext rather than LogicalServer.

    This macro is idempotent - if you run it twice, it will only create an STP
    once.

  usage:

      %mm_createstp(stpname=MyNewSTP
        ,filename=mySpecialProgram.sas
        ,directory=SASEnvironment/SASCode/STPs
        ,tree=/User Folders/sasdemo
        ,outds=work.uris)

  If you wish to remove the new STP you can do so by running:

      data _null_;
        set work.uris;
        rc1 = METADATA_DELOBJ(texturi);
        rc2 = METADATA_DELOBJ(prompturi);
        rc3 = METADATA_DELOBJ(fileuri);
        rc4 = METADATA_DELOBJ(stpuri);
        putlog (_all_)(=);
      run;


  @param stpname= Stored Process name.  Avoid spaces - testing has shown that
    the check to avoid creating multiple STPs in the same folder with the same
    name does not work when the name contains spaces.
  @param stpdesc= Stored Process description (optional)
  @param filename= the name of the .sas program to run
  @param directory= The directory uri, or the actual path to the sas program
    (no trailing slash).  If more than uri is found with that path, then the
    first one will be used.
  @param tree= The metadata folder uri, or the metadata path, in which to
    create the STP.
  @param server= The server which will run the STP.  Server name or uri is fine.
  @param outds= The two level name of the output dataset.  Will contain all the
    meta uris. Defaults to work.mm_createstp.
  @param mDebug= set to 1 to show debug messages in the log

  @returns outds  dataset containing the following columns:
   - stpuri
   - prompturi
   - fileuri
   - texturi

  @version 9.2
  @author Allan Bowe
  @copyright GNU GENERAL PUBLIC LICENSE v3

**/

%macro mm_CreateSTP(
     stpname=Macro People STP
    ,stpdesc=This stp was created automatically by the mm_createstp macro
    ,filename=mm_createstp.sas
    ,directory=SASEnvironment/SASCode
    ,tree=/User Folders/sasdemo
    ,package=false
    ,streaming=true
    ,outds=work.mm_createstp
    ,mDebug=0
    ,server=SASApp - Logical Stored Process Server
  );

%local mD;
%if &mDebug=1 %then %let mD=;
%else %let mD=%str(*);
%&mD.put Executing mm_CreateSTP.sas;
%&mD.put _local_;

%mf_verifymacvars(stpname filename directory tree)
%mp_dropmembers(%scan(&outds,2,.))

/* check uris */
data _null_;
  length id $20 dirtype $256;
  rc=metadata_resolve("&directory",dirtype,id);
  call symputx('checkdirtype',dirtype,'l');
run;

%if &checkdirtype ne Directory %then %do;
  %mm_getDirectories(path=&directory,outds=&outds ,mDebug=&mDebug)
  %if %mf_nobs(&outds)=0 or %sysfunc(exist(&outds))=0 %then %do;
    %put WARNING: The directory object does not exist for &directory;
    %return;
  %end;
%end;
%else %do;
  data &outds;
    directoryuri="&directory";
  run;
%end;

/* get tree info */
%mm_getTree(tree=&tree, inds=&outds, outds=&outds, mDebug=&mDebug)

/* check to be sure the STP does not already exist */
data &outds;
  length id type loc $256;
  call missing(id,type,loc);
  drop id type rc loc;
  set &outds;
  loc=cats(treepath,"/&stpname");
  rc=metadata_pathobj(' ',loc,'StoredProcess',type,id);
  put (_all_)(=);
  if rc>0 then do;
    putlog "WARNING: An STP already exists at " treepath "/&stpname.";
    putlog "WARNING- It will not be overwritten.";
    stop;
  end;
  else output;
run;
%if %mf_nobs(&outds)=0 %then %return;

data &outds (keep=stpuri prompturi fileuri texturi);
  length stpuri prompturi fileuri texturi serveruri $256 ;
  set &outds;

  /* final checks on uris */
  length id $20 type $256;
  __rc=metadata_resolve(treeuri,type,id);
  if type ne 'Tree' then do;
    putlog 'WARNING:  Invalid tree URI: ' treeuri;
    stopme=1;
  end;
  __rc=metadata_resolve(directoryuri,type,id);
  if type ne 'Directory' then do;
    putlog 'WARNING:  Invalid directory URI: ' directoryuri;
    stopme=1;
  end;

/* get server info */
  __rc=metadata_resolve("&server",type,serveruri);
  if type ne 'LogicalServer' then do;
    __rc=metadata_getnobj("omsobj:LogicalServer?@Name='&server'",1,serveruri);
    if serveruri='' then do;
      putlog "WARNING:  Invalid server: &server";
      stopme=1;
    end;
  end;

  if stopme=1 then do;
    putlog (_all_)(=);
    stop;
  end;

  /* create empty prompt */
  rc1=METADATA_NEWOBJ('PromptGroup',prompturi,'Parameters');
  rc2=METADATA_SETATTR(prompturi, 'UsageVersion', '1000000');
  rc3=METADATA_SETATTR(prompturi, 'GroupType','2');
  rc4=METADATA_SETATTR(prompturi, 'Name','Parameters');
  rc5=METADATA_SETATTR(prompturi, 'PublicType','Embedded:PromptGroup');
  GroupInfo="<PromptGroup promptId='PromptGroup_%sysfunc(datetime())_&sysprocessid'"
    !!" version='1.0'><Label><Text xml:lang='en-GB'>Parameters</Text>"
    !!"</Label></PromptGroup>";
  rc6 = METADATA_SETATTR(prompturi, 'GroupInfo',groupinfo);

  if sum(of rc1-rc6) ne 0 then do;
    putlog 'WARNING: Issue creating prompt.';
    if prompturi ne . then do;
      putlog '  Removing orphan: ' prompturi;
      rc = METADATA_DELOBJ(prompturi);
      put rc=;
    end;
    stop;
  end;

  /* create a file uri */
  rc7=METADATA_NEWOBJ('File',fileuri,'SP Source File');
  rc8=METADATA_SETATTR(fileuri, 'FileName',"&filename");
  rc9=METADATA_SETATTR(fileuri, 'IsARelativeName','1');
  rc10=METADATA_SETASSN(fileuri, 'Directories','MODIFY',directoryuri);
  if sum(of rc7-rc10) ne 0 then do;
    putlog 'WARNING: Issue creating file.';
    if fileuri ne . then do;
      putlog '  Removing orphans:' prompturi fileuri;
      rc = METADATA_DELOBJ(prompturi);
      rc = METADATA_DELOBJ(fileuri);
      put (_all_)(=);
    end;
    stop;
  end;

  /* create a TextStore object */
  rc11= METADATA_NEWOBJ('TextStore',texturi,'Stored Process');
  rc12= METADATA_SETATTR(texturi, 'TextRole','StoredProcessConfiguration');
  rc13= METADATA_SETATTR(texturi, 'TextType','XML');
  storedtext='<?xml version="1.0" encoding="UTF-8"?><StoredProcess>'
    !!"<ResultCapabilities Package='&package' Streaming='&streaming'/>"
    !!"<OutputParameters/></StoredProcess>";
  rc14= METADATA_SETATTR(texturi, 'StoredText',storedtext);
  if sum(of rc11-rc14) ne 0 then do;
    putlog 'WARNING: Issue creating TextStore.';
    if texturi ne . then do;
      putlog '  Removing orphans: ' prompturi fileuri texturi;
      rc = METADATA_DELOBJ(prompturi);
      rc = METADATA_DELOBJ(fileuri);
      rc = METADATA_DELOBJ(texturi);
      put (_all_)(=);
    end;
    stop;
  end;

  /* create meta obj */
  rc15= METADATA_NEWOBJ('ClassifierMap',stpuri,"&stpname");
  rc16= METADATA_SETASSN(stpuri, 'Trees','MODIFY',treeuri);
  rc17= METADATA_SETASSN(stpuri, 'ComputeLocations','MODIFY',serveruri);
  rc18= METADATA_SETASSN(stpuri, 'SourceCode','MODIFY',fileuri);
  rc19= METADATA_SETASSN(stpuri, 'Prompts','MODIFY',prompturi);
  rc20= METADATA_SETASSN(stpuri, 'Notes','MODIFY',texturi);
  rc21= METADATA_SETATTR(stpuri, 'PublicType', 'StoredProcess');
  rc22= METADATA_SETATTR(stpuri, 'TransformRole', 'StoredProcess');
  rc23= METADATA_SETATTR(stpuri, 'UsageVersion', '1000000');
  rc24= METADATA_SETATTR(stpuri, 'Desc', "&stpdesc");

  /* tidy up if error */
  if sum(of rc15-rc24) ne 0 then do;
    putlog 'WARNING: Issue creating STP.';
    if stpuri ne . then do;
      putlog '  Removing orphans: ' prompturi fileuri texturi stpuri;
      rc = METADATA_DELOBJ(prompturi);
      rc = METADATA_DELOBJ(fileuri);
      rc = METADATA_DELOBJ(texturi);
      rc = METADATA_DELOBJ(stpuri);
      put (_all_)(=);
    end;
  end;
  else do;
    fullpath=cats('_program=',treepath,"/&stpname");
    putlog "NOTE: Stored Process Created!";
    putlog "NOTE- "; putlog "NOTE-"; putlog "NOTE-" fullpath;
    putlog "NOTE- "; putlog "NOTE-";
  end;
  output;
  stop;
run;
%mend;