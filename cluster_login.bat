set CLUSTER_CONFIG=%SCRIPT_DIR%config\cluster_config.bat
if not exist "%CLUSTER_CONFIG%" (
    echo Errore: config\cluster_config.bat non trovato.
    echo Copia config\cluster_config.bat.example in config\cluster_config.bat e imposta CLUSTER_USER.
    pause
    exit /b 1
)
call "%CLUSTER_CONFIG%"
if "%CLUSTER_USER%"=="" (
    echo Errore: CLUSTER_USER non impostato in config\cluster_config.bat
    pause
    exit /b 1
)
ssh %CLUSTER_USER%@%CLUSTER_HOST%