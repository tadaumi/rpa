*** Settings ***
Library    Process
Library    RPA.Windows              WITH NAME    Win
Library    RPA.Desktop              WITH NAME    Desk
Library    OperatingSystem
Library    String
Library    Collections
Library    DateTime

Resource   resources/line_config.robot
Resource   resources/line_core.robot
Resource   resources/line_scroll.robot
Resource   resources/line_io.robot
Resource   resources/line_utils.robot

Suite Setup       Open LINE

*** Test Cases ***
LINEのメッセージをスクロールバー操作でHTML保存
    Initialize Trace File
    Ensure Artifact Directories
    Activate LINE
    Open First Group
    Initialize Html File
    Capture Messages From Scrolled Start
    Finalize Html File
    Trace    保存完了: ${OUT_FILE}