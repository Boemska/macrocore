#!/usr/bin/env bash

# Concatenate all macros into a single file

OUTFILE='./macrocore.sas'

cat > $OUTFILE <<'EOL'
/**
  @file
  @brief Auto-generated file
  @details
    This file contains all the macros in a single file - which means it can be
    'included' in SAS with just 2 lines of code:

      filename mc url
        "https://raw.githubusercontent.com/Boemska/macrocore/master/macrocore.sas";
      %inc mc;

    The `build.sh` file in the https://github.com/Boemska/macrocore repo
    is used to create this file.

  @author Allan Bowe
**/
EOL

cat base/* >> $OUTFILE
cat meta/* >> $OUTFILE
cat xcmd/* >> $OUTFILE
cat viya/* >> $OUTFILE
