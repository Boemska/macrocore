/**
  @file
  @brief Returns all files and subdirectories within a specified parent
  @details Not OS specific (uses dopen / dread).  It does not appear to be
    possible to reliably identify unix directories, and so a recursive
    option is not available.
  usage:

      %mp_dirlist(path=/some/location,outds=myTable);

  @param path= for which to return contents
  @param outds= the output dataset to create

  @returns outds contains the following variables:
   - file_or_folder (file / folder)
   - filepath (path/to/file.name)
   - filename (just the file name)
   - ext (.extension)
   - msg (system message if any issues)

  @version 9.2
  @author Allan Bowe
  @copyright GNU GENERAL PUBLIC LICENSE v3

**/

%macro mp_dirlist(path=%sysfunc(pathname(work))
    , outds=work.mp_dirlist
)/*/STORE SOURCE*/;

data &outds (compress=no keep=file_or_folder filepath filename ext msg);
  length filepath $500 fref $8 file_or_folder $6 filename $80 ext $20 msg $200;
  rc = filename(fref, "&path");
  if rc = 0 then do;
     did = dopen(fref);
     if did=0 then do;
        putlog "NOTE: This directory is empty - &path";
        msg=sysmsg();
        put _all_;
        stop;
     end;
     rc = filename(fref);
  end;
  else do;
    msg=sysmsg();
    put _all_;
    stop;
  end;
  dnum = dnum(did);
  do i = 1 to dnum;
    filename = dread(did, i);
    fid = mopen(did, filename);
    if fid > 0 then do;
      file_or_folder='file  ';
      ext = prxchange('s/.*\.{1,1}(.*)/$1/', 1, filename);
      if filename = ext then ext = ' ';
    end;
    else do;
      ext='';
      file_or_folder='folder';
    end;
    filepath="&path/"!!filename;
    output;
  end;
  rc = dclose(did);
  stop;
run;

%mend;