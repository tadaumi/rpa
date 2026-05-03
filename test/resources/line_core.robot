*** Settings ***
Resource    line_config.robot
Resource    line_scroll.robot
Resource    line_io.robot
Resource    line_utils.robot
Resource    keywords/line_window.robot
Resource    keywords/line_bubble.robot
Resource    keywords/line_menu_copy.robot

*** Variables ***
${SPLITTER_LOCATOR}               executable:LINE.exe > type:CustomControl and class:LcSplitter
${SPLITTER_CHILD_DEPTH}           20
