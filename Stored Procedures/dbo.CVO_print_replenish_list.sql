SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


-- execute cvo_print_replenish_list 'HIGHBAY'
CREATE PROCEDURE [dbo].[CVO_print_replenish_list] @group_code  varchar(10)

as

-- sp_help tdc_bin_master



CREATE TABLE #PrintData_Output
(
	format_id        varchar(40)  NOT NULL,
	printer_id       varchar(30)  NOT NULL,
	number_of_copies int          NOT NULL
)

CREATE TABLE #Select_Result
(
	data_field varchar(300) NOT NULL,
	data_value varchar(300)     NULL
)

CREATE TABLE #tdc_print_ticket 
(
	 row_id      int identity (1,1)  NOT NULL, 
	 print_value varchar(300)        NOT NULL
)


CREATE TABLE #PrintData 
(
	data_field varchar(300) NOT NULL,
 	data_value varchar(300)     NULL
)


insert into #PrintData_Output (format_id,printer_id, number_of_copies)
Values ( 'Bin_Group_Repl_List.lwl','21',1)


-- declare @bin_group varchar(12)
-- select * from #PrintData_Output
-- sp_help tdc_bin_group

-- select * from  tdc_bin_group


 execute cvo_replenish_list @group_code
--  execute cvo_replenish_list 'HIGHBAY'


-- select * from #PrintData_Output
-- select * from #Select_Result
-- select * from #PrintData
-- select * from #tdc_print_ticket

DECLARE @wd_drop_path 		varchar(1000),
	@bcpCommand   		varchar(1200),
	@global_temp_table_name	varchar(25),
	@temp			varchar(300),
	@location   		varchar(10),
	@time_spid 		varchar(50),
	@database		varchar(128)

--------------------------------------------------------------------------
-- Get the WDDrop path
--------------------------------------------------------------------------
SELECT @wd_drop_path = value_str FROM tdc_config(NOLOCK) WHERE [function] = 'wddrop_directory'

--IF ISNULL(@wd_drop_path, '') = ''
--BEGIN
--	RAISERROR ('Loftware WatchDog directory not set up', 16, 1)
--	RETURN -1
--END

IF RIGHT(@wd_drop_path, 1) != '\' SET @wd_drop_path = @wd_drop_path + '\'

--------------------------------------------------------------------------
-- Generate the output file name
--------------------------------------------------------------------------
SET @wd_drop_path = @wd_drop_path + 'TDC' + 
	RIGHT(CONVERT(varchar(8),  GETDATE(), 112), 4) + REPLACE(CONVERT(varchar(12), GETDATE(), 114), ':', '') +
	'.pas'
  
---------------------------------------------------------------------------
-- Create a global temp table and fill it with the data to be printed. 
-- The global temp table is used for bcp output
---------------------------------------------------------------------------

SELECT @time_spid = convert(varchar(40), getdate(), 109) + CAST(@@SPID AS varchar(10))

--SET @temp = 'CREATE TABLE ' + @global_temp_table_name + '(row_id int, print_value varchar(300))'
--EXEC (@temp)

--SET @temp = 'INSERT INTO  ' + @global_temp_table_name + ' SELECT * FROM #tdc_print_ticket'
--EXEC (@temp)

INSERT INTO tdc_bcp_print_values (row_id, print_value, time_spid)
SELECT row_id, print_value, @time_spid
  FROM #tdc_print_ticket
ORDER BY row_id



SELECT @database = db_name(dbid) FROM master.dbo.sysprocesses (nolock) WHERE SPID = @@SPID

--------------------------------------------------------------------------
-- Import data into the .pas file
--------------------------------------------------------------------------
--SET @bcpCommand = 'bcp "SELECT print_value FROM tempdb..' + @global_temp_table_name + ' ORDER BY row_id" queryout "' + @wd_drop_path + '" -t -c'
 
/* -- comment out original code
SET @bcpCommand = 'bcp "SELECT print_value FROM ' + @database + '..tdc_bcp_print_values (nolock) WHERE time_spid = ''' + @time_spid + ''' ORDER BY row_id" queryout "' + @wd_drop_path + '" -t -c'
print @bcpcommand
EXEC master..xp_cmdshell @bcpCommand, no_output
*/


/* -- testing
declare @bcpCommand varchar (1000)
declare @wd_drop_path varchar (1000)
SET @wd_drop_path = @wd_drop_path + 'TDC' + 
	RIGHT(CONVERT(varchar(8),  GETDATE(), 112), 4) + REPLACE(CONVERT(varchar(12), GETDATE(), 114), ':', '') +
	'.pas'
-- select * from tdc_bcp_print_values
SET @bcpCommand = 'bcp "SELECT print_value FROM ' + 'CVO'+ '..tdc_bcp_print_values (nolock)  ORDER BY row_id" queryout "' + @wd_drop_path + '" -t -c, -r\n  -Usa -Psa12345'
EXEC master..xp_cmdshell @bcpCommand--, no_output
print @bcpcommand

declare @bcpCommand varchar (1000)
SET @bcpCommand = 'bcp "SELECT print_value FROM CVO..tdc_bcp_print_values (nolock) WHERE time_spid = ''''Sep 27 2010 11:15:50:857PM70'''' ORDER BY row_id" queryout "\\DEV-ERP-01\Loftware$\WDDrop\TDC0927231550857.pas" -t -c, -usa -Psa12345'
EXEC master..xp_cmdshell @bcpCommand--, no_output

*/


			DECLARE @xp_cmdshell VARCHAR(1000)
			DECLARE @lwlPath	 VARCHAR (100)
			SELECT @lwlPath = ISNULL(value_str,'C:\') FROM dbo.tdc_config WHERE [function] = 'WDDrop_Directory'

			--Without column name
			SET @xp_cmdshell = 'SQLCMD -S ' + @@servername + ' -E -Q "SET NOCOUNT ON SELECT print_value FROM ' + db_name() + '.dbo.tdc_bcp_print_values (NOLOCK) ORDER BY row_id" -s"," -h -1 -W -b -o  ' + @lwlPath  + '\SO-' + CAST(newid()AS VARCHAR(60)) + '.pas'   
			Print 	@xp_cmdshell
			EXEC master..xp_cmdshell  @xp_cmdshell--, no_output

 			--EXEC master..xp_cmdshell '  SQLCMD -S DEV-DB-01 -E -Q "SET NOCOUNT ON SELECT print_value FROM CVO.dbo.tdc_bcp_print_values (NOLOCK)" -s"," -h -1 -W -b -o  \\DEV-ERP-01\Loftware$\WDDrop\SO-248A9E1B-9BCD-418F-B07B-B54FF4B013FE.pas'


---------------------------------------------------------------------------
-- Drop the global temp table 
---------------------------------------------------------------------------
--SET @temp = 'DROP TABLE ' + @global_temp_table_name 
--EXEC (@temp)

DELETE FROM tdc_bcp_print_values WHERE time_spid = @time_spid


IF OBJECT_ID('tempdb..#tdc_print_ticket') 		IS NOT NULL DROP TABLE #tdc_print_ticket
IF OBJECT_ID('tempdb..#PrintData_Output') 		IS NOT NULL DROP TABLE #PrintData_Output
IF OBJECT_ID('tempdb..#PrintData')        		IS NOT NULL DROP TABLE #PrintData
IF OBJECT_ID('tempdb..#Select_Result')    		IS NOT NULL DROP TABLE #Select_Result


return




GO
GRANT EXECUTE ON  [dbo].[CVO_print_replenish_list] TO [public]
GO
