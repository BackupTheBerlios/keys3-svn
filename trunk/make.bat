@echo off

setlocal

set AUXFILES=aux cmds glo gls hd idx ilg ind ist log out toc
set CLEAN=gz ins pdf sty txt zip
set SOURCE=keys3 keys3opts2

:loop

  if /i "%1" == "clean"        goto :clean
  if /i "%1" == "ctan"         goto :ctan
  if /i "%1" == "doc"          goto :doc
  if /i "%1" == "localinstall" goto :localinstall
  if /i "%1" == "tds"          goto :tds
  if /i "%1" == "test"         goto :test
  if /i "%1" == "unpack"       goto :unpack

  goto :help

:clean

  for %%I in (%CLEAN%) do if exist *.%%I del /q *.%%I

:clean-int

  for %%I in (%AUXFILES%) do if exist *.%%I del /q *.%%I
    
  goto :end
  
:ctan

  set NEXT=ctan
  if not defined ZIP goto :zip
  
  call make tds
  
  echo.
  echo Making CTAN archive
  
  if exist temp\*.* del /q /s temp\*.* > temp.log
  
  xcopy /y *.dtx temp\keys3\ > temp.log
  for %%I in (%SOURCE%) do (
    copy /y %%I.pdf temp\keys3\ > temp.log
  )
  copy /y *.txt temp\keys3\ > temp.log
  pushd temp\keys3
  ren README.txt README
  popd
  copy /y *.ins temp\keys3\ > temp.log
  copy /y keys3.tds.zip temp\ > temp.log
  
  cd temp
  "%ZIP%" %ZIPFLAG% keys3.zip > temp.log
  cd ..
  copy temp\keys3.zip > temp.log
  rmdir /q /s temp
  
  goto :clean-int
  
:doc

  echo.
  echo Typesetting
  
  for %%I in (%SOURCE%) do (
    echo   %%I
    pdflatex -interaction=nonstopmode -draftmode -quiet "\PassOptionsToClass{nocheck}{l3doc} \input %%I.dtx"
    makeindex -q -s l3doc.ist -o %%I.ind %%I.idx > temp.log
    pdflatex -interaction=nonstopmode -quiet "\PassOptionsToClass{nocheck}{l3doc} \input %%I.dtx"
    pdflatex -interaction=nonstopmode -quiet "\PassOptionsToClass{nocheck}{l3doc} \input %%I.dtx"
  )
  
  goto :clean-int
   
:help

  echo.
  echo  make clean        - delete all generated files
  echo  make ctan         - create an archive ready for CTAN
  echo  make localinstall - extract packages
  echo  make tds          - create a TDS-ready archive
  echo  make unpack       - extract packages
  echo.
  
  goto :end
  
:localinstall

  if not defined TEXMFHOME (
    set TEXMFHOME=%USERPROFILE%\texmf
    echo.
    echo TEXMFHOME variable was not set:
    echo using default value %USERPROFILE%\texmf
  )
  
  SET LTEXMF=%TEXMFHOME%\tex\latex\keys3
  
  call make unpack
  
  echo.
  echo Installing files
  
  if exist "%LTEXMF%\*.*" del /q "%LTEXMF%\*.*"
  xcopy /y *.sty "%LTEXMF%\*.*" > temp.log
  
  goto :clean-int
  
:tds

  set NEXT=tds
  if not defined ZIP goto :zip

  if exist tds\*.* del /q /s tds\*.* > temp.log
  
  call make unpack
  call make doc
  
  echo.
  echo Making TDS structure 
  
  xcopy /y *.sty tds\tex\latex\keys3\ > temp.log
  
  xcopy /y *.dtx tds\source\latex\keys3\ > temp.log
  copy /y *.ins tds\source\latex\keys3\ > temp.log
  
  xcopy /y *.txt tds\doc\latex\keys3\ > temp.log
  pushd tds\doc\latex\keys3
  ren README.txt README
  popd
  for %%I in (%SOURCE%) do (
    copy /y %%I.pdf tds\doc\latex\keys3\ > temp.log
  )
  copy /y *.tex tds\doc\latex\keys3\ > temp.log
 
  cd tds
  "%ZIP%" %ZIPFLAG% keys3.tds.zip > temp.log
  cd ..
  copy /y tds\keys3.tds.zip > temp.log
  
  rmdir /q /s tds
  
  goto :clean-int
  
:unpack
  
  echo.
  echo Unpacking files
  
  for %%I in (%SOURCE%) do (
    tex -quiet %%I.dtx
  )
  del /q *.log
  
  goto :end
  
 
:zip  

  set PATHCOPY=%PATH%
  
:zip-loop
  
  for /f "delims=; tokens=1,2*" %%I in ("%PATHCOPY%") do (
    if exist %%I\7z.exe (
      set ZIP=7z
      set ZIPFLAG=a
    )
    set PATHCOPY=%%J;%%K
  )
  
  if defined ZIP goto :%NEXT%

  if not "%PATHCOPY%"==";" goto :zip-loop
  
  if exist %ProgramFiles%\7-zip\7z.exe (
    set ZIP=%ProgramFiles%\7-zip\7z.exe
    set ZIPFLAG=a
  )
  
  if defined ZIP (
    goto :%NEXT%
  ) else (
    echo.
    echo This procedure requires a zip program,
    echo but one could not be found.
    echo
    echo If you do have a command-line zip program installed,
    echo set ZIP to the full executable path and ZIPFLAG to the
    echo appropriate flag to create an archive.
    echo.
    goto :end
  )
  
:end

  shift
  if not "%1" == "" goto :loop
  
  endlocal
