/**********************
         /\
        /  \
       /    \
      /_    _\
        |  |
Hazel IT Solutions LTD
       © 2024
    Christian Haslam

    HZFormatting
        v0.1
************************
* A Package to hold all formatting related functionality
***********************/
CREATE OR REPLACE PACKAGE HZFormatting
IS
    /*******************
    * FormatRDTMessage *
    ********************
    * Given a message and an RDT (or screen width), give back a string that
    * will be formatted nicely on the given details
    *******************/
    FUNCTION FormatRDTMessage
    (
        i_input_message IN VARCHAR2,
        i_station_id IN dcsdba.workstation.station_id%TYPE DEFAULT NULL,
        i_screen_width IN NUMBER DEFAULT NULL
    ) RETURN VARCHAR2;

END HZFormatting;
/
CREATE OR REPLACE PACKAGE BODY HZFormatting
IS
    /**************************
    * Private Functions/Procs *
    ***************************
    * FormatRDTMessage        *
    ***************************
    * Private overloaded version of the public facing one to recursively work out the prettified message within screen limits
    **************************/
    FUNCTION FormatRDTMessage
    (
        i_input_message IN VARCHAR2,
        i_screen_width IN NUMBER DEFAULT NULL
    ) RETURN VARCHAR2
    IS
         l_last_whitespace_position NUMBER(2);
    BEGIN
        IF LENGTH(i_input_message) <= i_screen_width OR i_input_message IS NULL THEN
            RETURN i_input_message;
        END IF;

        l_last_whitespace_position:= INSTR(SUBSTR(i_input_message, 1, i_screen_width  + 1), ' ', -1);

        IF l_last_whitespace_position = 0 THEN
            l_last_whitespace_position:= i_screen_width;
        END IF;

        RETURN RPAD(SUBSTR(i_input_message, 1, l_last_whitespace_position), i_screen_width)||FormatRDTMessage(SUBSTR(i_input_message, l_last_whitespace_position + 1), i_screen_width);
    END FormatRDTMessage;

    /*************************
    * Public Functions/Procs *
    **************************
    * FormatRDTMessage       *
    *************************/
    FUNCTION FormatRDTMessage
    (
        i_input_message IN VARCHAR2,
        i_station_id IN dcsdba.workstation.station_id%TYPE DEFAULT NULL,
        i_screen_width IN NUMBER DEFAULT NULL
    ) RETURN VARCHAR2
    IS
        lc_SMALLEST_SCREEN_WIDTH_ALLOWANCE CONSTANT NUMBER:= 10;
        l_screen_width dcsdba.workstation.screen_columns%TYPE:= i_screen_width;
    BEGIN
        IF (i_station_id IS NULL AND i_screen_width IS NULL) OR i_screen_width < lc_SMALLEST_SCREEN_WIDTH_ALLOWANCE THEN
            /* Do not try and process with badly passed data */
            RETURN i_input_message;
        END IF;

        IF i_screen_width IS NULL THEN
            SELECT w.screen_columns
                INTO l_screen_width
            FROM dcsdba.workstation w
            WHERE w.station_id = i_station_id;
        END IF;

        RETURN FormatRDTMessage(i_input_message, l_screen_width);
    END FormatRDTMessage;

END HZFormatting;
/
