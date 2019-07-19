# Copyright (C) 2019, Nokia

*** Settings ***

Library    Process
Library    crl.interactivesessions.remoterunner.RemoteRunner
...        WITH NAME    RemoteRunner

Library    filehelper.py
Library    SessionBroker.py

Suite Setup    Create Random File
Test Setup    Set RemoteRunner Targets
Suite Teardown    RemoteRunner.Close
Force Tags     remoterunner

*** Variables ***

&{HOST1}=    host=example1.com
...          user=username1
...          password=password1

&{HOST2}=    host=example2.com
...          user=username2
...          password=password2

@{SHELLDICTS1}=    ${HOST1}
@{SHELLDICTS2}=    ${HOST1}    ${HOST2}

${REPEAT}    20

${COMMAND}    echo out;>&2 echo err

*** Keywords ***

Remove Files In Target
    [Arguments]  ${target}  ${file}  ${dir}
    RemoteRunner.Execute Command In Target    rm ${file} ${dir}  target=${target}

Remove Files Locally And In Target
    Run Process  rm  targetlocal  remotescriptfile
    Remove Files In Target  target1  targetlocal  .
    Remove Files In Target  target2  targetlocal  .

Remove Directory In Target
    [Arguments]     ${target}   ${dir}
    RemoteRunner.Execute Command In Target  rm -rf ${dir}   target=${target}

Set RemoteRunner Targets
    RemoteRunner.Set Target    shelldicts=${SHELLDICTS1}
    ...                        name=target1

    RemoteRunner.Set Target    shelldicts=${SHELLDICTS2}
    ...                        name=target2

Create Random File
    filehelper.Create Random File    targetlocal    100000


Verify Run
    [Arguments]   ${ret}    ${expected_status}
    Should Be Equal As Integers    ${ret.status}    ${expected_status}
    Should Be Equal   ${ret.stdout}    out
    Should Be Equal   ${ret.stderr}    err

Test Execute Nohup Background In Target
    [Arguments]  ${target}
    ${pid}=         Execute Nohup Background In Target
    ...             command=echo foo;echo bar >&2;sleep 4
    ...             target=${target}
    ${ret}=         Execute Command In Target
    ...             command=kill ${pid}
    ...             target=${target}
    Should Be Equal As Integers     ${ret.status}   0   ${ret}

Test Execute Command In Target
    [Arguments]  ${target}
    ${ret}=    RemoteRunner.Execute Command In Target
    ...    ${COMMAND}    target=${target}
    Verify Run    ${ret}    0


Test Execute Background Commands
    [Arguments]  ${target}
    RemoteRunner.Execute Background Command In Target
    ...   ${COMMAND}; sleep 10    target=${target}    exec_id=${target}
    ${ret}=    RemoteRunner.Kill Background Execution   ${target}
    Verify Run   ${ret}    -15
    ${ret_from_wait}=    Remoterunner.Wait Background Execution
    ...    ${target}   t=1
    Should Be Equal    ${ret_from_wait}    ${ret}

Test File Copying
    Create Random File
    [Arguments]  ${target1}  ${target2}
    FOR    ${INDEX}   IN RANGE   ${REPEAT}
        RemoteRunner.Copy File To Target    targetlocal    target=${target1}
        RemoteRunner.Copy File Between Targets
         ...     from_target=${target1}
         ...     source_file=targetlocal
         ...     to_target=${target2}
        RemoteRunner.Copy File From Target
         ...    targetlocal
         ...    remotefile
         ...    target=${target2}
        filehelper.diff files    targetlocal    remotefile
   END
   [Teardown]  Remove Files Locally And In Target

Test Break Sessions Before Execute Command In Target
    [Arguments]  ${target}
    RemoteRunner.Set Target Property    ${target}    prompt_timeout    1
     FOR    ${INDEX}    IN RANGE    2
        SessionBroker.Break Sessions
        ${ret}=    RemoteRunner.Execute Command In Target    ${COMMAND}
        ...    target=${target}
        Verify Run    ${ret}    0
     END

Test Hang Sessions Before Execute Command In Target
    [Arguments]  ${target}
    RemoteRunner.Set Target Property    ${target}    prompt_timeout    1
     FOR    ${INDEX}    IN RANGE    2
        SessionBroker.Hang Sessions
        ${ret}=    RemoteRunner.Execute Command In Target    ${COMMAND}
        ...    target=${target}
        Verify Run    ${ret}    0
     END

Test Get Proxy From Call
    [Arguments]  ${target}
    ${term}=    RemoteRunner.Get Terminal    ${target}
    RemoteRunner.Import Local Path Module In Terminal
    ...    ${term}   ${CURDIR}/proxytest.py
    ${testproxy}=    RemoteRunner.Get Proxy From Call In Terminal  ${term}
    ...    proxytest.ProxyTest   1
    ${ret}=    Call Method    ${testproxy}   test   0
    Should Be Equal   ${ret.testid}    1
    Should Be Equal   ${ret.status}    0

Test Get Proxy Object
    [Arguments]  ${target}  ${username}
    ${term}=    RemoteRunner.Get Terminal    ${target}
    ${osproxy}=    RemoteRunner.Get Proxy Object In Terminal    ${term}   os
    Log  ${osproxy}
    #Log  ${osproxy.uname()}
    ${os}=   Get Variable Value   ${osproxy.getlogin()}
    Log  ${os}
    Should Be Equal   ${os}    ${username}

Test Copy Directory To Target
    [Arguments] ${target}


*** Test Cases ***


Template Test Execute Command In Target
    [Template]  Test Execute Command In Target
    target1
    target2


Template Test Execute Background Commands
    [Template]  Test Execute Background Commands
    target1
    target2


Template Test File Copying
    [Template]  Test File Copying
    target1  target2
    target2  target1


Template Test Break Sessions Before Execute Command In Target
    [Template]  Test Break Sessions Before Execute Command In Target
    target1
    target2


Template Test Hang Sessions Before Execute Command In Target
    [Template]  Test Hang Sessions Before Execute Command In Target
    target1
    target2

Template Test Get Proxy From Call
    [Template]  Test Get Proxy From Call
    target1
    target2


Template Test Get Proxy Object
    [Template]  Test Get Proxy Object
    target1  ${HOST1.user}
    target2  ${HOST2.user}
   [Teardown]  RemoteRunner.Close


Template Test Execute Nohup Background In Target
    [Template]  Test Execute Nohup Background In Target
    target1
    target2
