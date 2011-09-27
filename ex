#!/bin/bash

e=""

function printhelp {
  echo "Usage: x [files] [option]"
  echo " extracts an archive file. options not shown below are passed to the extracting app."
  echo " use {} anywhere in those passed options and the file name (without the extension) of"
  echo " the archive will be placed there."
  echo ""
  echo "Options:"
  echo "        -xp  --xpretend    print what WOULD be executed, but don't actually execute."
  echo "        -xf  --xfork       execute all commands in parellel instead of one-by-one"
  echo "        -xh  --xhelp       print help"
  echo "        -xv  --xversion    print version"
}

function printversion {
  echo "x - extract various types of archives files."
}

if [ -z "$1" ]; then
  printversion;
  printhelp;
  exit 0
fi

PARALLEL=""

for opt in $@; do
  if [ "$opt" = "{}" ] ; then
    OPTIONS[${#OPTIONS[*]}]="{}"
    continue;
  fi

  if [[ "${opt:0:1}" != "-" ]] ; then
    FILES[${#FILES[*]}]="$opt"
    continue
  fi
  let START=$START+${#opt}

  if [ "$opt" = "-xp" ] || [ "$opt" = "--xpretend" ]; then
    e="echo"
    continue;
  fi

  if [ "$opt" = "-xh" ] || [ "$opt" = "--xhelp" ]; then
    printversion;
    printhelp;
    exit 0
  elif [ "$opt" = "-xv" ] || [ "$opt" = "--xversion" ]; then
    printversion;
    exit 0
  fi

  if [ "$opt" = "-xf" ] || [ "$opt" = "--xfork" ]; then
    PARALLEL="1";
    continue;
  fi

  OPTIONS[${#OPTIONS[*]}]="$opt"
done

for ((i=0; $i<${#FILES[@]}; i++ )); do
  if [ -f "${FILES[$i]}" ] ; then

    # replace {} with input
    filest=`echo ${FILES[$i]} | sed 's/\(.*\)\..*/\1/g'` #file name with no extnesion

    unset OPTIONS_TMP
    for (( l=0; $l<${#OPTIONS[@]}; l++ )) ; do
      for (( m=0; $m<${#OPTIONS[$l]}; m++ )) ; do

        if [[ "${OPTIONS[$l]:$m:2}" == "{}" ]] ; then
          str_head=${OPTIONS[$l]:0:$m}
          OPTIONS_TMP[$l]="$str_head""$filest"

          let m=$m+1+${#filest}
        else
          OPTIONS_TMP[$l]="${OPTIONS_TMP[$l]}""${OPTIONS[$l]:$m:1}"
        fi
      done
    done

    COMMAND=""

    case "${FILES[$i]}" in
      *.tar.bz2)   COMMAND=(tar xjf) ;;
      *.tar.gz)    COMMAND=(tar xzf) ;;
      *.bz2)       COMMAND=(bunzip2) ;;
      *.rar)       COMMAND=(rar x) ;;
      *.gz)        COMMAND=(gunzip) ;;
      *.tar)       COMMAND=(tar xf) ;;
      *.tbz2)      COMMAND=(tar xjf) ;;
      *.tgz)       COMMAND=(tar xzf) ;;
      *.zip)       COMMAND=(unzip) ;;
      *.Z)         COMMAND=(uncompress) ;;
      *.7z)        COMMAND=(7z x) ;;
      *)           echo "${FILES[$i]}: unknown file type for x" "${OPTIONS_TMP[@]}" ;;
    esac

    if [[ "$PARALLEL" == "1" ]] ; then
      if [[ "$e" == "echo" ]] ; then
        echo $COMMAND "${FILES[$i]}" ${OPTIONS_TMP[@]} \&  &
      else
        $e $COMMAND "${FILES[$i]}" ${OPTIONS_TMP[@]} &
      fi
    else
      $e $COMMAND "${FILES[$i]}" ${OPTIONS_TMP[@]}
    fi
  else
    echo "file doesnt exist: ${FILES[$i]}"
  fi
done