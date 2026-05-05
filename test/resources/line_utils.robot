*** Settings ***
Library    Process
Library    OperatingSystem
Library    String
Library    Collections
Library    DateTime

*** Keywords ***
Initialize Trace File
    ${ts}=    Get Current Date    result_format=%Y-%m-%d %H:%M:%S
    Create Directory    ${ARTIFACT_LOG_DIR}
    Create Directory    ${TRACE_SPLIT_DIR}
    Create File    ${TRACE_FILE}    [TRACE START] ${ts}\n

Ensure Artifact Directories
    Create Directory    ${ARTIFACT_DIR}
    Create Directory    ${ARTIFACT_IMAGE_DIR}
    Create Directory    ${ARTIFACT_TEXT_DIR}
    Create Directory    ${ARTIFACT_LOG_DIR}
    Create Directory    ${TRACE_SPLIT_DIR}
    Create Directory    ${FAILSHOT_DIR}
    ${archive_exists}=    Run Keyword And Return Status    Variable Should Exist    ${MENU_CAPTURE_ARCHIVE_DIR}
    IF    ${archive_exists}
        Create Directory    ${MENU_CAPTURE_ARCHIVE_DIR}
    END
    Trace    [FAILSHOT] directory=${FAILSHOT_DIR}

Prepare Artifact Directories
    Ensure Artifact Directories

Should Emit Trace Message
    [Arguments]    ${msg}
    ${focus_enabled}=    Evaluate    str(r'''${TRACE_FOCUS_COPY_FLOW_ONLY}''').strip().lower() in ['true','1','yes','on']
    IF    not ${focus_enabled}
        RETURN    ${True}
    END

    ${tag}=    Evaluate    __import__('re').search(r'\\[([^\\]]+)\\]', str(r'''${msg}''')).group(1) if __import__('re').search(r'\\[([^\\]]+)\\]', str(r'''${msg}''')) else ''
    ${tag}=    Convert To String    ${tag}
    ${tag}=    Strip String    ${tag}
    ${tag_upper}=    Convert To Upper Case    ${tag}
    FOR    ${prefix}    IN    @{TRACE_FOCUS_TAG_PREFIXES}
        ${prefix_upper}=    Convert To Upper Case    ${prefix}
        ${matched}=    Evaluate    str(r'''${tag_upper}''').startswith(str(r'''${prefix_upper}'''))
        IF    ${matched}
            RETURN    ${True}
        END
    END
    RETURN    ${False}

Split Debug Trace Log
    ${exists}=    Run Keyword And Return Status    File Should Exist    ${TRACE_FILE}
    IF    not ${exists}
        RETURN
    END
    Create Directory    ${TRACE_SPLIT_DIR}
    ${all}=    Get File    ${TRACE_FILE}
    ${lines}=    Split To Lines    ${all}
    FOR    ${line}    IN    @{lines}
        ${trimmed}=    Strip String    ${line}
        IF    '${trimmed}' == ''
            CONTINUE
        END
        ${msg}=    Evaluate    str(r'''${line}''')
        ${tag}=    Evaluate    __import__('re').search(r'\\[([^\\]]+)\\]', ${msg}).group(1) if __import__('re').search(r'\\[([^\\]]+)\\]', ${msg}) else 'MISC'
        ${safe_tag}=    Evaluate    __import__('re').sub(r'[^0-9A-Za-z_\\-]+', '_', str(${tag}))
        ${split_file}=    Set Variable    ${TRACE_SPLIT_DIR}${/}${safe_tag}.log
        Append To File    ${split_file}    ${line}\n
    END

Trace
    [Arguments]    ${msg}
    ${emit}=    Should Emit Trace Message    ${msg}
    IF    not ${emit}
        RETURN
    END
    ${ts}=    Get Current Date    result_format=%H:%M:%S.%f
    ${line}=    Catenate    SEPARATOR=    [${ts}]    ${msg}
    Log To Console    ${line}
    Append To File    ${TRACE_FILE}    ${line}\n
    ${tag}=    Evaluate    __import__('re').search(r'\\[([^\\]]+)\\]', str(r'''${msg}''')).group(1) if __import__('re').search(r'\\[([^\\]]+)\\]', str(r'''${msg}''')) else 'MISC'
    ${safe_tag}=    Evaluate    __import__('re').sub(r'[^0-9A-Za-z_\\-]+', '_', str(${tag}))
    ${split_file}=    Set Variable    ${TRACE_SPLIT_DIR}${/}${safe_tag}.log
    Append To File    ${split_file}    ${line}\n

Normalize Element String
    [Arguments]    ${elem}
    ${status}    ${raw}=    Run Keyword And Ignore Error    Convert To String    ${elem}
    IF    '${status}' != 'PASS'
        RETURN    ${EMPTY}
    END
    ${s}=    Strip String    ${raw}
    IF    $s == 'None' or $s == ''
        RETURN    ${EMPTY}
    END
    RETURN    ${s}

Trim Text
    [Arguments]    ${text}
    ${s}=    Convert To String    ${text}
    ${s}=    Strip String    ${s}
    RETURN    ${s}

Safe Get Element Attribute
    [Arguments]    ${elem}    ${attr}
    ${value}=    Set Variable    ${EMPTY}

    IF    '${attr}' == 'name'
        ${ok}=    Run Keyword And Return Status    Set Variable    ${elem.name}
        IF    ${ok}
            ${value}=    Set Variable    ${elem.name}
            RETURN    ${value}
        END
    END

    IF    '${attr}' == 'control_type'
        ${ok}=    Run Keyword And Return Status    Set Variable    ${elem.control_type}
        IF    ${ok}
            ${value}=    Set Variable    ${elem.control_type}
            RETURN    ${value}
        END
    END

    IF    '${attr}' == 'class_name'
        ${ok}=    Run Keyword And Return Status    Set Variable    ${elem.class_name}
        IF    ${ok}
            ${value}=    Set Variable    ${elem.class_name}
            RETURN    ${value}
        END
    END

    IF    '${attr}' == 'left'
        ${ok}=    Run Keyword And Return Status    Set Variable    ${elem.left}
        IF    ${ok}
            ${value}=    Set Variable    ${elem.left}
            RETURN    ${value}
        END
    END

    IF    '${attr}' == 'top'
        ${ok}=    Run Keyword And Return Status    Set Variable    ${elem.top}
        IF    ${ok}
            ${value}=    Set Variable    ${elem.top}
            RETURN    ${value}
        END
    END

    IF    '${attr}' == 'right'
        ${ok}=    Run Keyword And Return Status    Set Variable    ${elem.right}
        IF    ${ok}
            ${value}=    Set Variable    ${elem.right}
            RETURN    ${value}
        END
    END

    IF    '${attr}' == 'bottom'
        ${ok}=    Run Keyword And Return Status    Set Variable    ${elem.bottom}
        IF    ${ok}
            ${value}=    Set Variable    ${elem.bottom}
            RETURN    ${value}
        END
    END

    ${status}    ${v}=    Run Keyword And Ignore Error    Get Attribute    ${elem}    ${attr}
    IF    '${status}' == 'PASS'
        RETURN    ${v}
    END

    ${status2}    ${v2}=    Run Keyword And Ignore Error    Get Property    ${elem}    ${attr}
    IF    '${status2}' == 'PASS'
        RETURN    ${v2}
    END

    RETURN    ${value}

Parse Cursor Position Json
    [Arguments]    ${cursor_json}
    ${status}    ${result}=    Run Keyword And Ignore Error
    ...    Evaluate    __import__('json').loads(r'''${cursor_json}''')
    IF    '${status}' == 'PASS'
        ${x}=    Evaluate    int(${result}.get('x', -99999))
        ${y}=    Evaluate    int(${result}.get('y', -99999))
        RETURN    ${x}    ${y}
    END
    Trace    [COPY-PROBE] cursor json parse failed raw=[${cursor_json}]
    RETURN    -99999    -99999

Clear Images Directory On Startup
    ${exists}=    Run Keyword And Return Status    Directory Should Exist    ${ARTIFACT_IMAGE_DIR}
    IF    not ${exists}
        Create Directory    ${ARTIFACT_IMAGE_DIR}
        RETURN
    END

    ${files}=    List Files In Directory    ${ARTIFACT_IMAGE_DIR}    absolute=True
    FOR    ${path}    IN    @{files}
        ${is_dir}=    Run Keyword And Return Status    Directory Should Exist    ${path}
        IF    ${is_dir}
            ${name}=    Evaluate    __import__('os').path.basename(r'''${path}''')
            Remove Directory    ${path}    recursive=True
            Trace    [STARTUP-CLEAN] removed dir=${name}
        ELSE
            ${name}=    Evaluate    __import__('os').path.basename(r'''${path}''')
            Remove File    ${path}
            Trace    [STARTUP-CLEAN] removed file=${name}
        END
    END
