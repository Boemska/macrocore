/**
  @file
  @brief Create a metadata folder
  @details This macro was sourced from Paul Homes who wrote the original macro
    (mkdirmd.sas) in 2010.  Very little has changed except for the standards to
    align with the macro core standards.  Also, the version specific logic was
    updated to work on 9.3 and 9.4.  The original is described here:
    https://platformadmin.com/blogs/paul/2010/07/mkdirmd/

    This macro is idempotent - if you run it twice, it will only create a folder
    once.

  usage:

    %mm_createfolder(name=myNewFolder,parent=/ParentFolder)

  As per original documentation:

  Metadata server connection details should be set prior to the use of this
  macro using the various META options (METASERVER, METAPORT, METAUSER etc.).

  The parent path must be absolute, start with a forward slash (/) and end
  with a forward slash.

  It will fail with an error if any folder within the parent path does not
  exist or is not visible to the current metadata user.

  It prevents the creation of folders with duplicate names in the same
  parent folder.

  @param name= Name of the folder to create. Must be non blank.
  @param parent= Parent folder in which to create the folder.  Must start and
    finish with a /
  @param dbg= set DBG to * to disable DEBUG messages

  @version 9.1.3
  @author Allan Bowe (modified from Paul Homes original)
  @copyright GNU GENERAL PUBLIC LICENSE v3

**/

%macro mm_createfolder(name=, parent=,dbg=);

data _null_;
  length
    objId parentFolderObjId $17
    objType folderName parentPathComponent associationName $200
    parentPath folderPath queryUri parentFolderUri newFolderUri $1000;

  folderName = cats(symget('NAME'));
  parentPath = cats(symget('PARENT'));

  * name must not be blank;
  if ( folderName = '' ) then do;
    put "%str(ERR)OR: &sysmacroname NAME parameter value must be non-blank";
    stop;
  end;

  * parent must not be blank;
  if ( parentPath = '' ) then do;
    put "%str(ERR)OR: &sysmacroname PARENT parameter value must be non-blank";
    stop;
  end;

  * parent must start with a /;
  if ( substr(parentPath,1,1) ne '/' ) then do;
    put "%str(ERR)OR: &sysmacroname PARENT parameter value must start with a /";
    stop;
  end;

  * parent must end with a /;
  if ( substr(parentPath,length(parentPath),1) ne '/' ) then do;
    put "%str(ERR)OR: &sysmacroname PARENT parameter value must end with a /";
    stop;
  end;

  folderPath = cats(parentPath, folderName);
  put 'NOTE: Attempting to create metadata folder: ' folderPath;

  * walk the parent path looking for each folder in turn until we find the
    immediate parent to associate the new folder with ;
  pathIndex=1;
  do until (0);
    * get the next path component in the parent folder tree path
      (using forward slash delimiters);
    parentPathComponent = scan(parentPath, pathIndex, '/');

    * when the parent path component is blank we have reached the end of the
      path and found (barring any errors) our immediate parent so we can leave
      the loop
    ;
    if ( parentPathComponent eq '' ) then leave;

    put 'NOTE: Looking for parent path tree folder: ' parentPathComponent;

    * construct a metadata XMLSelect filter to find the current parent path component;
    * find a Tree object with the same name as the current parent path component;
    queryUri = cats("omsobj:Tree?*[@Name='", parentPathComponent, "']");
    * once we get past the top level we will have a parent folder object id to
      use as an association path filter to ensure uniqueness
    ;
    if ( parentFolderObjId ne '' ) then do;
      queryUri=cats(queryUri,"[ParentTree/Tree[@Id='",parentFolderObjId,"']]");
    end;
    else do;
      * otherwise we are dealing with a top level folder - which will have a
        BIP Service SoftwareComponent association
      ;
      queryUri = cats(queryUri, "[SoftwareComponents/SoftwareComponent[@Name='BIP Service']]");
    end;

    &DBG put 'DEBUG: ' queryUri=;
    objType='';
    objId='';
    rc = metadata_resolve(queryUri, objType, objId);
    &DBG put 'DEBUG: metadata_resolve: ' rc= objType= objId=;
    if ( rc < 0 ) then do;
      put "%str(ERR)OR: failed to connect to the metadata server";
      stop;
    end;
    else if ( rc = 0 ) then do;
      put "%str(ERR)OR: no matching metadata object found for tree folder: " parentPathComponent;
      put "%str(ERR)OR: cannot create folder - invalid parent path: " parentPath;
      stop;
    end;
    else if ( rc > 1 ) then do;
      put "%str(ERR)OR: multiple matching metadata objects found for tree folder: " parentPathComponent;
      stop;
    end;

    parentFolderObjId = objId;
    pathIndex + 1;
  end;

  * we now know the immediate parent (from parentFolderObjId) or if
    parentFolderObjId is blank  then it will be a root folder
  ;

  * the metadata API allows duplicate folders (with the same name) so first we
    check to make sure a folder with the same name in the same parent folder does
    not already exist
  ;
  queryUri = cats("omsobj:Tree?*[@Name='", folderName, "']");
  * add different filter for root and non-root folder;
  if ( parentFolderObjId ne '' ) then do;
    queryUri = cats(queryUri, "[ParentTree/Tree[@Id='", parentFolderObjId, "']]");
  end;
  else do;
    queryUri = cats(queryUri, "[SoftwareComponents/SoftwareComponent[@Name='BIP Service']]");
  end;

  &DBG put 'DEBUG: ' queryUri=;
  objType='';
  objId='';
  rc = metadata_resolve(queryUri, objType, objId);
  &DBG put 'DEBUG: metadata_resolve: ' rc= objType= objId=;
  if ( rc < 0 ) then do;
    put "%str(ERR)OR: unable to check uniqueness of new folder name";
    stop;
  end;
  else if ( rc > 0 ) then do;
    put "%str(ERR)OR: cannot create tree folder - it already exists: " folderPath;
    stop;
  end;

  * now we can do the easy bit - creating the tree folder iself;
  newFolderUri='';
  * root folder has BIP Service SoftwareComponent as a parent whereas
    non-root folder has the previously identitied Tree object as a parent
  ;
  if ( parentFolderObjId = '' ) then do;
    associationName = 'SoftwareTrees';
    parentFolderUri = "omsobj:SoftwareComponent?SoftwareComponent[@Name='BIP Service']";
  end;
  else do;
    associationName = 'SubTrees';
    parentFolderUri = cats("omsobj:Tree\", parentFolderObjId);
  end;

  rc = metadata_newobj("Tree", newFolderUri, folderName, '', parentFolderUri, associationName);
  &DBG put 'DEBUG: metadata_newobj: ' rc= newFolderUri= parentFolderUri= associationName=;
  if ( rc = -1 ) then do;
    put "%str(ERR)OR: failed to connect to the metadata server";
    stop;
  end;
  else if ( rc = -2 ) then do;
    put "%str(ERR)OR: failed to create new metadata Tree object for folder: " folderPath;
    stop;
  end;
  else if ( rc ne 0 ) then do;
    put "%str(ERR)OR: unknown error creating new metadata Tree object for folder: " folderPath;
    stop;
  end;

  * tag the new tree folder with the attribute TreeType=BIP Folder;
  rc = metadata_setattr(newFolderUri, 'TreeType', 'BIP Folder');
  &DBG put 'DEBUG: metadata_setattr (TreeType): ' rc=;
  if ( rc ne 0 ) then do;
    put "%str(ERR)OR: failed to set TreeType attribute for new folder: " folderPath;
    stop;
  end;

  * new attributes for SAS 9.2 only;
  %if ( &SYSVER ge 9.2 ) %then %do;
    * tag the new tree folder with the SAS 9.2 attribute PublicType=Folder;
    rc = metadata_setattr(newFolderUri, 'PublicType', 'Folder');
    &DBG put 'DEBUG: metadata_setattr (PublicType): ' rc=;
    if ( rc ne 0 ) then do;
      put "%str(ERR)OR: failed to set PublicType attribute for new folder: " folderPath;
      stop;
    end;

    * tag the new tree folder with the SAS 9.2 attribute UsageVersion=1000000;
    rc = metadata_setattr(newFolderUri, 'UsageVersion', '1000000');
    &DBG put 'DEBUG: metadata_setattr (UsageVersion): ' rc=;
    if ( rc ne 0 ) then do;
      put "%str(ERR)OR: failed to set UsageVersion attribute for new folder: " folderPath;
      stop;
    end;
  %end;

  put 'NOTE: Sucessfully created new metadata folder: ' folderPath;

run;

%mend;