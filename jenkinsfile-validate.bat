@echo off

:main
    setlocal enabledelayedexpansion
    call :get-ini %USERPROFILE%\.jenkins\config default JENKINS_URL JENKINS_URL
    call :get-ini %USERPROFILE%\.jenkins\config default JENKINS_USER JENKINS_USER
    call :get-ini %USERPROFILE%\.jenkins\config default JENKINS_API_TOKEN JENKINS_API_TOKEN
    echo Using %JENKINS_URL% with user %JENKINS_USER%...
    set FILE=%1
    echo Validating %FILE% ...
    for /f %%i in ('curl -sS -u%JENKINS_USER%:%JENKINS_API_TOKEN% "%JENKINS_URL%/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,\":\",//crumb)"') do set JENKINS_CRUMB=%%i
    echo %JENKINS_CRUMB%

    curl -X POST -u%JENKINS_USER%:%JENKINS_API_TOKEN% -H %JENKINS_CRUMB% -F "jenkinsfile=<%FILE%" %JENKINS_URL%/pipeline-model-converter/validate

    goto :eof

:get-ini <filename> <section> <key> <result>
    set %~4=
    setlocal
    set insection=
    for /f "usebackq eol=; tokens=*" %%a in ("%~1") do (
        set line=%%a
        if defined insection (
        for /f "tokens=1,* delims==" %%b in ("!line!") do (
            if /i "%%b"=="%3" (
            endlocal
            set %~4=%%c
            goto :eof
            )
        )
        )
        if "!line:~0,1!"=="[" (
        for /f "delims=[]" %%b in ("!line!") do (
            if /i "%%b"=="%2" (
            set insection=1
            ) else (
            endlocal
            if defined insection goto :eof
            )
        )
        )
    )
    endlocal
