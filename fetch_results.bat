@echo off
REM Scarica i risultati dal cluster al PC (doppio click per eseguire).
REM Richiede: VPN Polimi attiva, e config\cluster_config.bat presente (vedi
REM config\cluster_config.bat.example) con il tuo username impostato.
REM
REM Fa git pull per leggere results\last_results.txt (aggiornato e pushato
REM da submit_chain.sh a fine catena) e scarica via scp SOLO le cartelle
REM elencate li' dentro - non tutto results/, non nomi indovinati a mano.

setlocal

set SCRIPT_DIR=%~dp0
set RESULTS_DIR=%SCRIPT_DIR%results
set MANIFEST=%RESULTS_DIR%\last_results.txt
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

echo Aggiorno il repo (git pull) per leggere l'elenco dell'ultimo run...
cd /d "%SCRIPT_DIR%"
git pull
if errorlevel 1 (
    echo Errore: git pull fallito. Controlla la connessione/credenziali git.
    pause
    exit /b 1
)

if not exist "%MANIFEST%" (
    echo Errore: %MANIFEST% non trovato.
    echo Hai gia' lanciato "make chain" sul cluster fino in fondo almeno una volta?
    pause
    exit /b 1
)

echo.
echo Scarico le cartelle elencate in results\last_results.txt ...
echo (assicurati che la VPN sia attiva)
echo.

for /f "usebackq delims=" %%L in ("%MANIFEST%") do (
    echo [%%L]
    scp -r %CLUSTER_USER%@%CLUSTER_HOST%:%REMOTE_DIR%/%%L "%RESULTS_DIR%"
)

echo.
echo Fatto. Risultati in %RESULTS_DIR%
endlocal
pause
