/**
  @file
  @brief Create a metadata folder
  @details This macro was inspired by Paul Homes who wrote an early
    version (mkdirmd.sas) in 2010. The original is described here:
    https://platformadmin.com/blogs/paul/2010/07/mkdirmd/

    The below has been updated to work robustly in later environments
    (9.2 onwards) and will now also create all the relevant parent
    directories.  The macro will NOT create a new ROOT folder - not
    because it can't, but more because that is generally not something
    your administrator would like you to do!

    The macro is idempotent - if you run it twice, it will only create a folder
    once.

  usage:

    %mm_createfolder(path=/Tests/some folder/a/b/c/d)

  @param path= Name of the folder to create.
  @param mdebug= set DBG to 1 to disable DEBUG messages
  @param outds= output dataset with 2 vars: folderpath and folderuri

  @version 9.2
  @author Allan Bowe (inspired from Paul Homes original)

**/

%macro mm_createfolder(path=,mDebug=0,outds=mm_createfolder);
%local dbg;
%if &mDebug=0 %then %let dbg=*;

data &outds(keep=folderPath folderuri);
  length objId parentFolderObjId objType  PathComponent rootpath $200
    folderPath walkpath folderuri $1000;
  call missing (of _all_);
  folderPath = cats(symget('path'));

  * remove any trailing slash ;
  if ( substr(folderPath,length(folderPath),1) = '/' ) then
    folderPath=substr(folderPath,1,length(folderPath)-1);

  * name must not be blank;
  if ( folderPath = '' ) then do;
    put "%str(ERR)OR: &sysmacroname PATH parameter value must be non-blank";
    stop;
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

  * do not create a root folder ;
  if countc(folderPath,'/')=1 then do;
    put "%str(ERR)OR: &sysmacroname will not create a new ROOT folder";
    stop;
  end;

  rootpath='/'!!scan(folderPath,1,'/');
  rc=metadata_pathobj('',cats(rootpath,"(Folder)"),"",objType,objId);
  if rc<1 then do;
    put "%str(ERR)OR: &sysmacroname: root folder does not exist! " rootpath;
    put (_all_)(=);
    stop;
  end;

  * walk the path creating (or ignoring) each folder in turn;
  pathIndex=2;
  parentFolderObjId=objId;
  walkpath=rootpath;
  do until (0);
    * get the next path component in the folder tree path
      (using forward slash delimiters);
    PathComponent = scan(folderPath, pathIndex, '/');

    * when the path component is blank we have reached the end;
    if ( PathComponent eq '' ) then leave;

    put 'NOTE: Looking for path tree folder: ' PathComponent;
    walkpath=cats(walkpath,'/',PathComponent);
    objid='';
    rc=metadata_pathobj('',cats(walkpath,"(Folder)"),"",objType,objId);

    if rc =1 then do;
      put 'NOTE- Found: ' walkpath ' uri: ' objid;
      parentFolderObjId=objid;
      goto loop_next;
    end;
    else if ( rc > 1 ) then do;
      put "%str(ERR)OR: multiple matching metadata objects found for tree folder: " walkpath;
      stop;
    end;

    put / 'NOTE- Attempting to create metadata folder: ' walkpath;
    * now we can do the easy bit - creating the tree folder iself;
    folderuri='';
    rc = metadata_newobj('Tree', folderuri, PathComponent, '', parentFolderObjId, 'SubTrees');
    put 'NOTE- metadata_newobj: ' rc= folderuri= parentFolderObjId= ;
    if ( rc = -1 ) then do;
      put "%str(ERR)OR: failed to connect to the metadata server";
      stop;
    end;
    else if ( rc = -2 ) then do;
      put "%str(ERR)OR: failed to create new metadata Tree object for folder: " walkpath;
      stop;
    end;
    else if ( rc ne 0 ) then do;
      put "%str(ERR)OR: unknown error creating new metadata Tree object for folder: " walkpath;
      stop;
    end;

    * tag the new tree folder with the attribute TreeType=BIP Folder;
    rc = metadata_setattr(folderuri, 'TreeType', 'BIP Folder');
    &dbg put 'NOTE- metadata_setattr (TreeType): ' rc= ;
    if ( rc ne 0 ) then do;
      put "%str(ERR)OR: failed to set TreeType attribute for new folder: " walkpath;
      stop;
    end;

    * tag the new tree folder with the SAS 9.2 attribute PublicType=Folder;
    rc = metadata_setattr(folderuri, 'PublicType', 'Folder');
    &dbg put 'NOTE- metadata_setattr (PublicType): ' rc=;
    if ( rc ne 0 ) then do;
      put "%str(ERR)OR: failed to set PublicType attribute for new folder: " walkpath;
      stop;
    end;

    * tag the new tree folder with the SAS 9.2 attribute UsageVersion=1000000;
    rc = metadata_setattr(folderuri, 'UsageVersion', '1000000');
    &dbg put 'NOTE- metadata_setattr (UsageVersion): ' rc=;
    if ( rc ne 0 ) then do;
      put "%str(ERR)OR: failed to set UsageVersion attribute for new folder: " walkpath;
      stop;
    end;


    put 'NOTE- Sucessfully created new metadata folder: ' walkpath ;
    parentFolderObjId=folderuri;
    loop_next:
    pathIndex + 1;
  end;
  &dbg put (_all_)(=);
run;

%mend;