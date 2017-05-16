/**
  @file
  @brief Returns a dataset with the meta directory object for a physical path
  @details Provide a file path to get matching directory objects, or leave
    blank to return all directories.

  @param path= the physical path for which to return a meta Directory object
  @param outds= the dataset to create that contains the list of directories
  @param mDebug= set to 1 to show debug messages in the log

  @returns outds  dataset containing the following columns:
   - directoryuri
   - groupname
   - groupdesc

  @version 9.2
  @author Macro People Ltd
  @copyright GNU GENERAL PUBLIC LICENSE v3

**/

%macro mm_getdirectories(
     path=
    ,outds=work.mm_getDirectories
    ,mDebug=0
  );

%if &mDebug=1 %then %let mDebug=;
%else %let mDebug=%str(*);

%&mDebug.put _all_;

data &outds (keep=directoryuri name directoryname desc metacreated metaupdated);
  length directoryuri name directoryname metacreated metaupdated desc $256;
  call missing(of _all_);
  i+1;
%if %length(&path)=0 %then %do;
  do while
  (metadata_getnobj("omsobj:Directory?@Id contains '.'",i,directoryuri)>0);
%end; %else %do;
  do while
  (metadata_getnobj("omsobj:Directory?@DirectoryName='&path'",i,directoryuri)>0);
%end;
    rc1=metadata_getattr(directoryuri, "Name", name);
    rc2=metadata_getattr(directoryuri, "DirectoryName", directoryname);
    rc3=metadata_getattr(directoryuri, "Desc", desc);
    rc4=metadata_getattr(directoryuri,"MetadataCreated",metacreated);
    rc5=metadata_getattr(directoryuri,"MetadataUpdated",metaupdated);
    &mdebug.putlog (_all_) (=);
    i+1;
    output;
  end;
run;

%mend;
