SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_cyc_setup_sp] AS 
BEGIN

SET NOCOUNT ON

 IF (SELECT OBJECT_ID('tempdb..#temp_who')) IS NOT NULL 
 BEGIN   
 DROP TABLE #temp_who  
 END
Create table #temp_who(who varchar(50), login_id varchar(50))
Insert #temp_who select 'tdcsql','tdcsql'
DECLARE @err_msg VARCHAR(255), @station_id VARCHAR(20)

SELECT @err_msg = '', @station_id = 'noprint'; -- set station to 'noprint' to skip the report part


DELETE 
-- SELECT *
FROM dbo.tdc_phy_cyc_count WHERE team_id = 'CC' AND cyc_code IN ('DAILY','ANNUAL','QTRLY','BI-ANNUAL') AND count_date IS null;

EXEC dbo.tdc_ins_count_sp @err_msg = @err_msg OUTPUT, -- varchar(255)
                          @team_id = 'CC',            -- varchar(30)
                          @cyc_code = 'DAILY',        -- varchar(10)
                          @location = '001'           -- varchar(10)

						  SELECT @err_msg

					  
EXEC dbo.tdc_ins_count_sp @err_msg = @err_msg OUTPUT, -- varchar(255)
                          @team_id = 'CC',              -- varchar(30)
                          @cyc_code = 'QTRLY',          -- varchar(10)
                          @location = '001'             -- varchar(10)

						  
						  SELECT @err_msg

EXEC dbo.tdc_ins_count_sp @err_msg = @err_msg OUTPUT, -- varchar(255)
                          @team_id = 'CC',              -- varchar(30)
                          @cyc_code = 'BI-ANNUAL',      -- varchar(10)
                          @location = '001'             -- varchar(10)

						  
						  SELECT @err_msg

EXEC dbo.tdc_ins_count_sp @err_msg = @err_msg OUTPUT, -- varchar(255)
                          @team_id = 'CC',              -- varchar(30)
                          @cyc_code = 'ANNUAL',        -- varchar(10)
                          @location = '001'             -- varchar(10)

						  SELECT @err_msg

IF @station_id <> 'noprint'
BEGIN

IF OBJECT_ID('tempdb..#tdc_print_ticket') 		IS NOT NULL DROP TABLE #tdc_print_ticket
IF OBJECT_ID('tempdb..#PrintData_Output') 		IS NOT NULL DROP TABLE #PrintData_Output
IF OBJECT_ID('tempdb..#PrintData')        		IS NOT NULL DROP TABLE #PrintData
IF OBJECT_ID('tempdb..#Select_Result')    		IS NOT NULL DROP TABLE #Select_Result

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

 IF (SELECT OBJECT_ID('tempdb..#tdc_cyc_master')) IS NOT NULL 
 BEGIN   
 DROP TABLE #tdc_cyc_master  
 END

SELECT 
       tpcc.location,
       tpcc.part_no,
       'Y' lb_tracking,
	   tpcc.lot_ser,
       tpcc.bin_no,
	   tpcc.adm_actual_qty erp_current_Qty,
       tpcc.adm_actual_qty erp_qty_at_count,
       tpcc.post_qty,
       tpcc.post_ver,
       0 changed_flag,
	   0 cost,
	   'USD' curr_key,
	   0 differenc
	   INTO #tdc_cyc_master
	   FROM dbo.tdc_phy_cyc_count AS tpcc  (NOLOCK) ORDER BY bin_no 


EXEC dbo.tdc_print_cyc_count_ticket_sp @user_id = 'manager',   -- varchar(50)
                                       @station_id = @station_id -- varchar(20)

-- send the file/data to Loftware

INSERT INTO tdc_bcp_print_values (row_id, print_value, time_spid)
SELECT row_id, print_value, @@spid
  FROM #tdc_print_ticket
ORDER BY row_id



DECLARE @xp_cmdshell VARCHAR(1000)
DECLARE @lwlPath	 VARCHAR (100)
SELECT @lwlPath = ISNULL(value_str,'C:\') FROM dbo.tdc_config WHERE [function] = 'WDDrop_Directory'

--Create the file
SET @xp_cmdshell = 'SQLCMD -S ' + @@servername + ' -E -Q "SET NOCOUNT ON SELECT print_value FROM ' + db_name() + '.dbo.tdc_bcp_print_values (NOLOCK) WHERE time_spid = ' + CAST(@@spid AS VARCHAR(6)) + ' order by row_id" -s"," -h -1 -W -b -o  "' + @lwlPath  + '\CYC' + CAST(newid()AS VARCHAR(60)) + '.pas"'  -- v10.1

-- SELECT @xp_cmdshell
				
EXEC master..xp_cmdshell  @xp_cmdshell , no_output


IF @@ERROR <> 0
	SELECT -1

DELETE FROM tdc_bcp_print_values 
WHERE time_spid = CAST(@@SPID AS VARCHAR(6))




IF OBJECT_ID('tempdb..#tdc_print_ticket') 		IS NOT NULL DROP TABLE #tdc_print_ticket
IF OBJECT_ID('tempdb..#PrintData_Output') 		IS NOT NULL DROP TABLE #PrintData_Output
IF OBJECT_ID('tempdb..#PrintData')        		IS NOT NULL DROP TABLE #PrintData
IF OBJECT_ID('tempdb..#Select_Result')    		IS NOT NULL DROP TABLE #Select_Result
 
END

--   select * From tdc_bcp_print_values

END


GO
GRANT EXECUTE ON  [dbo].[cvo_cyc_setup_sp] TO [public]
GO
