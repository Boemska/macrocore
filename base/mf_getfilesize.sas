/**
  @file
  @brief Returns the size of a file in bytes.
  @details Provide full path/filename.extension to the file, eg:

      %put %mf_getfilesize(C:\temp\myfile.txt);

  @param fpath full path and filename
  @returns bytes

  @version 9.2
  @author Allan Bowe
  @source https://github.com/macropeople/macrocore
  @copyright GNU GENERAL PUBLIC LICENSE v3
**/

%macro mf_getfilesize(fpath);
   %local rc fid fref bytes;
   %let rc=%sysfunc(filename(fref,&fpath));
   %let fid=%sysfunc(fopen(&fref));
   %let bytes=%sysfunc(finfo(&fid,File Size (bytes)));
   %let rc=%sysfunc(fclose(&fid));
   %let rc=%sysfunc(filename(fref));

     &bytes

%mend ;