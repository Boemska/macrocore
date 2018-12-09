/**
  @file
  @brief Update the source code of a type 2 STP
  @details Uploads the contents of a text file or fileref to an existing type 2
    STP.  A type 2 STP has its source code saved in metadata.

  Usage:

    %mm_updatestpsourcecode(stp=/my/metadata/path/mystpname
      ,stpcode="/file/system/source.sas")


  @param stp= the BIP Tree folder path plus Stored Process Name
  @param stpcode= the source file (or fileref) containing the SAS code to load
    into the stp.  For multiple files, they should simply be concatenated first.
  @param minify= set to YES in order to strip comments, blank lines, and CRLFs.

  @param frefin= change default inref if it clashes with an existing one
  @param frefout= change default outref if it clashes with an existing one
  @param mDebug= set to 1 to show debug messages in the log

  @version 9.3
  @author Allan Bowe
  @copyright GNU GENERAL PUBLIC LICENSE v3

**/

%macro mm_updatestpsourcecode(stp=
  ,stpcode=
  ,minify=NO
  ,frefin=inmeta
  ,frefout=outmeta
  ,mdebug=0
);
/* first, check if STP exists */
%local tsuri;
%let tsuri=stopifempty ;

data _null_;
  format type uri tsuri value $200.;
  call missing (of _all_);
  path="&stp.(StoredProcess)";
  /* first, find the STP ID */
  if metadata_pathobj("",path,"StoredProcess",type,uri)>0 then do;
    /* get sourcecode */
    cnt=1;
    do while (metadata_getnasn(uri,"Notes",cnt,tsuri)>0);
      rc=metadata_getattr(tsuri,"Name",value);
      put tsuri= value=;
      if value="SourceCode" then do;
        /* found it! */
        rc=metadata_getattr(tsuri,"Id",value);
        call symputx('tsuri',value,'l');
        stop;
      end;
      cnt+1;
    end;
  end;
  else put (_all_)(=);
run;

%if &tsuri=stopifempty %then %do;
  %put WARNING:  &stp.(StoredProcess) not found!;
  %return;
%end;

%if %length(&stpcode)<2 %then %do;
  %put WARNING:  No SAS code supplied!!;
  %return;
%end;

filename &frefin temp lrecl=10000000;

%if &minify=YES %then %do;
  filename &frefin.2 temp;
  data _null_;
    file &frefin.2 lrecl=10000000;
    infile &stpcode lrecl=10000000;
    input;
    if _infile_ ne '';
    if not (_infile_=:'/*' and subpad(left(reverse(_infile_)),1,2)='/*');
    put _infile_;
  run;
  %let stpcode=&frefin.2;
%end;

/* escape code so it can be stored as XML */
/* input file may be over 32k wide, so deal with one char at a time */
data _null_;
  file &frefin recfm=n;
  infile &stpcode recfm=n;
  input instr $CHAR1. ;
  if _n_=1 then put "<UpdateMetadata><Reposid>$METAREPOSITORY</Reposid>
    <Metadata><TextStore id='&tsuri' StoredText='" @@;
  select (instr);
    when (';') put '&#x3b;';
    when ('&') put '&amp;';
    when ('<') put '&lt;';
    when ('>') put '&gt;';
    when ("'") put '&apos;';
    when ('"') put '&quot;';
    when ('0A'x) put '&#x0a;';
    when ('0D'x) put '&#x0d;';
    when ('$') put '&#36;';
    otherwise put instr $CHAR1.;
  end;
run;

data _null_;
  file &frefin mod;
  put "'></TextStore></Metadata><NS>SAS</NS><Flags>268435456</Flags>
    </UpdateMetadata>";
run;


filename &frefout temp;

proc metadata in= &frefin out=&frefout verbose;
run;

%if &mdebug=1 %then %do;
  /* write the response to the log for debugging */
  data _null_;
    infile &frefout lrecl=1048576;
    input;
    put _infile_;
  run;
%end;

%mend;