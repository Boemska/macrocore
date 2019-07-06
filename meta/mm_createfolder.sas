/**
  @file
  @brief Create a metadata folder
  @details This macro was inspired by Paul Homes who wrote an early
    version (mkdirmd.sas) in 2010. The original is described here:
    https://platformadmin.com/blogs/paul/2010/07/mkdirmd/

    The macro will NOT create a new ROOT folder - not
    because it can't, but more because that is generally not something
    your administrator would like you to do!

    The macro is idempotent - if you run it twice, it will only create a folder
    once.

  usage:

    %mm_createfolder(path=/Tests/some folder)

  @param path= Name of the folder to create.
  @param mdebug= set DBG to 1 to disable DEBUG messages

  @version 9.4
  @author Allan Bowe

**/

%macro mm_createfolder(path=,mDebug=0);
%local dbg errorcheck;
%if &mDebug=0 %then %let dbg=*;
%let errorcheck=1;

data _null_;
  length objId parentFolderObjId objType parent child $200
    folderPath $1000;
  call missing (of _all_);
  folderPath = cats(symget('path'));

  * remove any trailing slash ;
  if ( substr(folderPath,length(folderPath),1) = '/' ) then
    folderPath=substr(folderPath,1,length(folderPath)-1);

  * name must not be blank;
  if ( folderPath = '' ) then do;
    put "%str(ERR)OR: &sysmacroname PATH parameter value must be non-blank";
  end;

  * must have a starting slash ;
  if ( substr(folderPath,1,1) ne '/' ) then do;
    put "%str(ERR)OR: &sysmacroname PATH parameter value must have starting slash";
    stop;
  end;

  * check if folder already exists ;
  rc=metadata_pathobj('',cats(folderPath,"(Folder)"),"",objType,objId);
  if rc ge 1 then do;
    put "NOTE: Folder " folderPath " already exists!";
    stop;
  end;

  * do not create a root (one level) folder ;
  if countc(folderPath,'/')=1 then do;
    put "%str(ERR)OR: &sysmacroname will not create a new ROOT folder";
    stop;
  end;

  * check that parent folder exists ;
  child=scan(folderPath,-1,'/');
  parent=substr(folderpath,1,length(folderpath)-length(child)-1);
  put parent=;
  rc=metadata_pathobj('',cats(parent,"(Folder)"),"",objType,parentFolderObjId);
  if rc<1 then do;
    put "%str(ERR)OR: &sysmacroname: parent folder does not exist! " parent;
    put (_all_)(=);
    stop;
  end;

  call symputx('parentFolderObjId',parentFolderObjId,'l');
  call symputx('child',child,'l');
  call symputx('errorcheck',0,'l');

  &dbg put (_all_)(=);
run;

%if &errorcheck=1 %then %return;

/* now create the folder */

filename __newdir temp;
options noquotelenmax;
%local inmeta;
%let inmeta=<AddMetadata><Reposid>$METAREPOSITORY</Reposid><Metadata>
  <Tree Name='&child' PublicType='Folder' TreeType='BIP Folder' UsageVersion='1000000'>
  <ParentTree><Tree ObjRef='&parentFolderObjId'/></ParentTree></Tree></Metadata>
  <NS>SAS</NS><Flags>268435456</Flags></AddMetadata>;

proc metadata in="&inmeta"
  out=__newdir verbose;
run;

%if &mDebug ne 0 %then %do;
  /* write the response to the log for debugging */
  data _null_;
    infile __newdir lrecl=32767;
    input;
    put _infile_;
  run;
%end;

filename __newdir clear;

%mend;