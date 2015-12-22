SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


/*
** Changes
** 06/07/2000	Added code to copy the version information from aeg_version into the log file when the log is 
**		initialized.  (RDS)
**
*/
       
    CREATE PROCEDURE [dbo].[icv_Log_sp] @SIL_Text varchar(255), @SIL_Log_Activity char(10)
    AS
    DECLARE @buf		varchar(255)
    DECLARE @agedate		varchar(255)
    -- Insert a record into the IC Verify log
    --
    -- RETURN values:
    --     -1001          Insertion failed
    --
    IF @SIL_Log_Activity = "INIT"
        BEGIN
        SELECT @buf = "DELETE icv_log WHERE entry_date <= DATEADD(" + RTRIM(LTRIM(CONVERT(varchar(255),configuration_text_value))) + "," + RTRIM(LTRIM(CONVERT(CHAR,0-configuration_int_value))) + ", GETDATE())"
          FROM icv_config
         WHERE configuration_item_name = "Delete log entries older than x days"
	EXEC (@buf)
        INSERT INTO icv_log VALUES (GETDATE(), @buf)

        DELETE icv_cchistory WHERE entry_date <= DATEADD(yy, -1, GETDATE())
        END

    IF @SIL_Log_Activity <> "YES"
        RETURN 0


    INSERT INTO icv_log VALUES (GETDATE(), ISNULL(@SIL_Text,''))
    IF @@ROWCOUNT = 1
        BEGIN
        RETURN 0
        END
    ELSE
        BEGIN
        RETURN -1001
        END

GO
GRANT EXECUTE ON  [dbo].[icv_Log_sp] TO [public]
GO
