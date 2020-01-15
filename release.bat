@echo off

set oldver=1.0.29
set newver=1.0.30
set comment=Add snapshot generation and validation tests for Bundle.entry slicing on resource by profile and add R4 tests

echo ..
echo ================================================================================
echo upgrade and release fhir-tests-cases from %oldver%-SNAPSHOT to %newver%-SNAPSHOT
echo ================================================================================
echo ..

call mvn versions:set -DnewVersion=%newver%-SNAPSHOT
call git commit -a -m "Release new version"
call git push origin master
call "C:\tools\fnr.exe" -dir "C:\work\org.hl7.fhir\org.hl7.fhir.core" -fileMask "*.xml" -find "%oldver%-SNAPSHOT" -replace "%newver%-SNAPSHOT" -count 1
call "C:\tools\fnr.exe" -dir "C:\work\org.hl7.fhir\latest-ig-publisher" -fileMask "*.html" -find "%oldver%" -replace "%newver%" -count 1
call "C:\tools\fnr.exe" -dir "C:\work\org.hl7.fhir\latest-ig-publisher" -fileMask "*.json" -find "%oldver%" -replace "%newver%" -count 1
call mvn clean deploy -Dmaven.test.redirectTestOutputToFile=false -DdeployAtEnd=true 
IF %ERRORLEVEL% NEQ 0 ( 
  GOTO DONE
)

call "c:\program files\7-zip\7z" a ..\latest-ig-publisher\test-cases.zip cda npm r4 r5 ucum validator

cd ..\latest-ig-publisher
call git commit -a -m "Release new version %newver%-SNAPSHOT. Changes: %comment%"
call git push origin master
cd ..\fhir-test-cases


call python c:\tools\zulip-api\zulip\zulip\send.py --stream committers/notification --subject "FHIR Test Cases" -m "New Test cases v%newver% released via Maven, also deployed at https://fhir.github.io/latest-ig-publisher/test-cases.zip. Changes: %comment%" --config-file zuliprc
call python c:\tools\zulip-api\zulip\zulip\send.py --stream tooling/releases --subject "FHIR Test Cases" -m "New Test cases @ https://fhir.github.io/latest-ig-publisher/test-cases.zip (v%newver%). Changes: %comment%" --config-file zuliprc

:DONE
echo ===============================================================
echo all done
echo ===============================================================
pause
 