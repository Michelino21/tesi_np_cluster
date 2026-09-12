@echo off
REM Converte un notebook in .py e lo esegue in locale sul PC Windows,
REM salvando l'output in results\<nome>_<timestamp>\ (stessa convenzione
REM usata sul cluster - vedi docs\structure.md).
REM
REM Solo per test in locale: NON tocca results\last_results.txt (quel file
REM serve solo a fetch_results.bat per sapere cosa scaricare dal cluster -
REM qui i dati sono gia' su questo PC, non c'e' niente da recuperare).
REM
REM Uso: run_local.bat <nome_notebook>
REM Esempio: run_local.bat test_pipeline

setlocal

if "%~1"=="" (
    echo Uso: run_local.bat ^<nome_notebook^>
    echo Esempio: run_local.bat test_pipeline
    pause
    exit /b 1
)

set SCRIPT_DIR=%~dp0
set NAME=%~n1
set NOTEBOOK=%SCRIPT_DIR%notebooks\%NAME%.ipynb
set VENV_PY=%SCRIPT_DIR%.venv\Scripts\python.exe

if not exist "%NOTEBOOK%" (
    echo Errore: %NOTEBOOK% non trovato.
    pause
    exit /b 1
)

if not exist "%VENV_PY%" (
    echo Errore: %VENV_PY% non trovato.
    echo Crea prima l'ambiente Python locale ^(una tantum^):
    echo   python -m venv .venv
    echo   .venv\Scripts\pip install -r config\requirements.txt
    pause
    exit /b 1
)

echo Converto %NAME%.ipynb in .py ...
"%VENV_PY%" -m jupyter nbconvert --to script "%NOTEBOOK%" --output-dir "%SCRIPT_DIR%scripts"
if errorlevel 1 (
    echo Errore nella conversione.
    pause
    exit /b 1
)

for /f "usebackq delims=" %%T in (`powershell -NoProfile -Command "Get-Date -Format yy_MM_dd__HH_mm"`) do set TS=%%T
set RUNDIR=%SCRIPT_DIR%results\%NAME%_%TS%
if not exist "%RUNDIR%" mkdir "%RUNDIR%"

echo Eseguo %NAME%.py in results\%NAME%_%TS% ...
echo.
pushd "%RUNDIR%"
"%VENV_PY%" "%SCRIPT_DIR%scripts\%NAME%.py"
popd

echo.
echo Fatto. Output in %RUNDIR%
endlocal
pause
