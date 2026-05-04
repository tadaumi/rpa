*** Settings ***
Library    RPA.Windows

*** Tasks ***
Open New Tab And Type
    Control Window    class:Notepad
    Send Keys         keys={Ctrl}t
    Send Keys         keys=hello from robot