*** Variables ***
${RESOURCE_DIR}                  ${CURDIR}
${BASE_DIR}                      ${EXECDIR}${/}test
${BASE_DIR_FALLBACK}             ${RESOURCE_DIR}${/}..

${LINE_PATH}                     C:\\Users\\user\\AppData\\Local\\LINE\\bin\\LineLauncher.exe
${START_TIMEOUT}                 30
${GROUP_ITEM_PATH}               path:11|2|1|1|1|2

${ARTIFACT_DIR}                  ${BASE_DIR}${/}artifacts
${ARTIFACT_IMAGE_DIR}            ${ARTIFACT_DIR}${/}images
${ARTIFACT_TEXT_DIR}             ${ARTIFACT_DIR}${/}text
${ARTIFACT_LOG_DIR}              ${ARTIFACT_DIR}${/}logs
${FAILSHOT_DIR}                  ${ARTIFACT_IMAGE_DIR}${/}fail_screens

${OUT_FILE}                      ${ARTIFACT_TEXT_DIR}${/}line_messages.html
${TRACE_FILE}                    ${ARTIFACT_LOG_DIR}${/}debug_trace.log

${SCREEN_PROBE_FILE}             ${BASE_DIR}${/}screen_probe.py
${SCREEN_PROBE_FILE_FALLBACK}    ${BASE_DIR_FALLBACK}${/}screen_probe.py

${MENU_IMAGE_FILE}               ${ARTIFACT_IMAGE_DIR}${/}menu_capture.png
${MENU_TEXT_FILE}                ${ARTIFACT_TEXT_DIR}${/}menu_capture.txt
${PRECLICK_IMAGE_FILE}           ${ARTIFACT_IMAGE_DIR}${/}preclick_capture.png
${SCROLL_BEFORE_IMAGE_FILE}      ${ARTIFACT_IMAGE_DIR}${/}scroll_before.png
${SCROLL_AFTER_IMAGE_FILE}       ${ARTIFACT_IMAGE_DIR}${/}scroll_after.png

${FAILSHOT_FULL_PREFIX}          fail_full
${FAILSHOT_CROP_PREFIX}          fail_crop

${PYTHON_EXE}                    python
${TESSERACT_CMD}                 C:\\Program Files\\Tesseract-OCR\\tesseract.exe

${MESSAGE_X}                     620
@{MESSAGE_Y_LIST}
...    170
...    240
...    310
...    380
...    450
...    520

@{RIGHT_CLICK_OFFSETS}
...    20,15
...    60,25
...    100,35
...    140,40
...    180,45

@{COPY_CLICK_OFFSETS}
...    70,45
...    80,51
...    90,57

${SCROLLBAR_X}                   996
${SCROLLBAR_TOP_Y}               80
${SCROLLBAR_MID_Y}               320
${SCROLLBAR_BOTTOM_Y}            720
${SCROLL_UP_SECONDS}             10
${MAX_DOWN_LOOPS}                80
${SCROLL_DOWN_RETRY}             3
${SCROLLBAR_DOWN_STEP_TO_Y}      420

${MENU_SCAN_RETRY}               3
${MENU_SCAN_INTERVAL}            250ms
${MENU_FIND_TIMEOUT}             0.4
${RIGHT_CLICK_WAIT}              500ms
${MENU_ROOT_LOCATOR}             desktop:desktop > class:LcContextMenu and type:WindowControl

${OCR_MARGIN_LEFT}               10
${OCR_MARGIN_TOP}                5
${OCR_MARGIN_RIGHT}              10
${OCR_MARGIN_BOTTOM}             5

${PRECLICK_MARGIN_X}             80
${PRECLICK_MARGIN_Y}             50
${PRECLICK_W}                    220
${PRECLICK_H}                    120

${COPY_CLICK_MOVE_WAIT}          150ms
${COPY_CLICK_RESULT_WAIT}        700ms

${SCROLL_CHECK_LEFT}             620
${SCROLL_CHECK_TOP}              140
${SCROLL_CHECK_W}                300
${SCROLL_CHECK_H}                520

${STATUS_COPY_OK}                COPY_OK
${STATUS_NO_MENU}                NO_MENU
${STATUS_MENU_NO_COPY}           MENU_NO_COPY
${STATUS_MENU_HAS_DELETE_ONLY}   MENU_HAS_DELETE_ONLY
${STATUS_OCR_FAIL}               OCR_FAIL
${STATUS_CLIPBOARD_EMPTY}        CLIPBOARD_EMPTY
${STATUS_OTHER_UI_MENU}          OTHER_UI_MENU
${STATUS_IMAGE_MESSAGE_SKIP}     IMAGE_MESSAGE_SKIP

@{NON_MESSAGE_MENU_KEYWORDS}
...    今後は表示しない
...    アナウンス解除
...    すべて選択

@{COPY_MENU_KEYWORDS}
...    コピー
...    コビー
...    コヒー
...    コヒ
...    コピ
...    コッピー
...    コッヒー
...    Copy

@{LINE_WINDOW_CANDIDATES}
...    executable:LINE.exe
...    name:LINE
...    regex:.*LINE.*

${SAFE_FOCUS_X}                  1100
${SAFE_FOCUS_Y}                  300
${SAFE_FOCUS_WAIT_MS}            250ms
${SAFE_RETURN_WAIT_MS}           100ms
${SAFE_FOCUS_MOVE_WAIT_MS}       500ms
${SAFE_RETURN_MOVE_WAIT_MS}      300ms

${SCROLL_CLEAR_SELECTION_X}      960
${SCROLL_CLEAR_SELECTION_Y}      360
${SCROLL_CLEAR_SELECTION_WAIT}   400ms

${MENU_CAPTURE_ARCHIVE_DIR}      ${ARTIFACT_IMAGE_DIR}${/}menu_capture_archive