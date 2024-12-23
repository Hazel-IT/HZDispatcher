/**********************
         /\
        /  \
       /    \
      /_    _\
        |  |
Hazel IT Solutions LTD
       © 2024
    Christian Haslam

      HZLogging
        v0.1
************************
* A Package to make the `dcsdba.LibMQSDebug` package a little nicer to work with and having custom package
* logging be a little less invasive without losing full logging capabilities
************************/
CREATE OR REPLACE PACKAGE HZLogging
IS
    PRAGMA SERIALLY_REUSABLE;
    /***************************
    * Public Package constants *
    ***************************/
    gc_LOG_LEVEL_INFO CONSTANT NUMBER:= 5;
    gc_LOG_LEVEL_DEBUG CONSTANT NUMBER:= 4;
    gc_LOG_LEVEL_CUSTOM_QUIET CONSTANT NUMBER:= 3;
    gc_LOG_LEVEL_ERROR CONSTANT NUMBER:= 2;
    gc_LOG_LEVEL_CRITICAL CONSTANT NUMBER:= 1;
    /* Customised levels for logging */
    gc_LOG_LEVEL_CUSTOM_QUIET CONSTANT NUMBER:= 3.5; -- This will only log custom code + >= warning severity messages
    gc_LOG_LEVEL_CUSTOM_NOISY CONSTANT NUMBER:= 6; -- This will log all levels but be stored with it's own number within package logging

    /***********************
    * PrintOutputToConsole *
    ************************
    * Procedure to switch on printing to console during logging
    ***********************/
    PROCEDURE PrintOutputToConsole(i_switch IN BOOLEAN DEFAULT TRUE);

    /********************
    * InitialiseLogging *
    *********************
    * Procedure to set up the required session variables for package logging. The name passed
    * to the procedure is the one seen within package logging
    ***********************/
    PROCEDURE InitialiseLogging(i_logging_name IN VARCHAR2, i_logging_level IN NUMBER DEFAULT HZLogging.gc_LOG_LEVEL_CUSTOM_QUIET);

    /********************
    * Log               *
    *********************
    * Logs the given message to the package data (and console if specified first)
    ********************/
    PROCEDURE Log(i_message IN VARCHAR2, i_logging_level IN NUMBER DEFAULT HZLogging.gc_LOG_LEVEL_CUSTOM_NOISY);

END HZLogging;
/
CREATE OR REPLACE PACKAGE BODY HZLogging
IS
    /****************************
    * Private Package variables *
    ****************************/
    PRAGMA SERIALLY_REUSABLE;
    pv_write_to_console BOOLEAN:= FALSE;

    /****************************
    * Private Package constants *
    ****************************/
    pc_PACKAGE_NAME CONSTANT VARCHAR2(10):= 'HZLOGGING';

    /**************************
    * Private Functions/Procs *
    ***************************
    ***************************
    * GetCallingCode          *
    ***************************
    * Formats call stack to pull out the inner most nested package declaration before the calls to logging
    **************************/
    PROCEDURE GetCallingCode(o_caller OUT VARCHAR2, o_line OUT NUMBER)
    IS
        l_call_stack CLOB:= DBMS_UTILITY.format_call_stack;
        l_nest_count PLS_INTEGER;
    BEGIN
        l_nest_count:= REGEXP_COUNT(l_call_stack, pc_PACKAGE_NAME);
        o_caller:= REGEXP_SUBSTR(l_call_stack, '^0x[^A-Z]+([^.]+\.[^\.]+\.[^.]+$)', 1, l_nest_count + 1, 'm', 1);

        IF o_caller IS NULL THEN
            RETURN;
        END IF;

        o_line:= TO_NUMBER(REGEXP_SUBSTR(l_call_stack, '^0x[^ ]+[ ]+([0-9]+)[^A-Z]+'||o_caller||'$', 1, 1, 'm', 1) DEFAULT NULL ON CONVERSION ERROR);
    END GetCallingCode;

    /*************************
    * Public Functions/Procs *
    **************************
    * PrintOutputToConsole   *
    *************************/
    PROCEDURE PrintOutputToConsole(i_switch IN BOOLEAN DEFAULT TRUE)
    IS
    BEGIN
        pv_write_to_console:= i_switch;
    END PrintOutputToConsole;

    /********************
    * InitialiseLogging *
    ********************/
    PROCEDURE InitialiseLogging(i_logging_name IN VARCHAR2, i_logging_level IN NUMBER DEFAULT HZLogging.gc_LOG_LEVEL_CUSTOM_QUIET)
    IS
    BEGIN
        dcsdba.LibMQSDebug.SetSessionId(SYS_CONTEXT('userenv', 'sessionid'), 'web', i_logging_name);
        dcsdba.LibMQSDebug.SetDebugLevel(i_logging_level);
    END InitialiseLogging;

    /********************
    * Log               *
    ********************/
    PROCEDURE Log(i_message IN VARCHAR2, i_logging_level IN NUMBER DEFAULT HZLogging.gc_LOG_LEVEL_CUSTOM_NOISY)
    IS
        l_caller VARCHAR2(384);
        l_line_number PLS_INTEGER;
        l_message CLOB:= i_message;
    BEGIN
        HZLogging.GetCallingCode(l_caller, l_line_number);

        IF l_caller IS NOT NULL THEN
            l_message:= l_caller||' ['||l_line_number||'] - '||l_message;
        END IF;

        IF pv_write_to_console THEN
            DBMS_OUTPUT.PUT_LINE(l_message);
        END IF;

        dcsdba.LibMQSDebug.Print(l_message, i_logging_level);
    END Log;
END HZLogging;
/
