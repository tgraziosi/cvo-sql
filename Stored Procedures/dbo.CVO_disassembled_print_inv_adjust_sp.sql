SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
***** Object:  StoredProcedure [dbo].[CVO_disassembled_print_inv_adjust_sp]    Script Date: 06/08/2010  *****
SED005 -- Custom Frame
Object:      Procedure  CVO_disassembled_print_inv_adjust_sp  
Source file: CVO_disassembled_print_inv_adjust_sp.sql
Author:		 Jesus Velazquez
Created:	 06/08/2010
Function:    Print lwl file with instructions to perform IN-OUT inventory adjustment
Modified:    
Calls:    
Called by:   
Copyright:   Epicor Software 2010.  All rights reserved.  

 v1.1 CB 29/06/2012 - add process_id to CVO_tdc_print_ticket so it can be used in other routines
*/
CREATE PROCEDURE [dbo].[CVO_disassembled_print_inv_adjust_sp]
	    @order_no	INT
       ,@order_ext	INT  
AS

BEGIN

	DECLARE  @no_rows		INT
			,@detail_lines	INT	
			,@i				INT
			,@totPage		INT
			,@sql			VARCHAR(200)

	DECLARE  @FORMAT		VARCHAR(60)
			,@LP_ORDER_NO		VARCHAR(40)
			,@LP_ORDER_EXT		VARCHAR(40)
			,@LP_ORDER_PLUS_EXT		VARCHAR(40)
			,@PRINTERNUMBER	VARCHAR(40)
			,@QUANTITY		VARCHAR(40)
			,@DUPLICATES	VARCHAR(40)
			,@PRINTLABEL	VARCHAR(40)

	DECLARE  @row_id		INT
			,@data_field	VARCHAR(300)
			,@data_value	VARCHAR(300)
		
	DELETE FROM CVO_tdc_print_ticket WHERE process_id = @@spid -- v1.1
						
	--get total lines to print
	SELECT	@no_rows = COUNT(*) FROM #PrintData

	IF @no_rows > 0 
	BEGIN 
		--get max detail_lines to print per page
		SELECT	@detail_lines = detail_lines 
		FROM 	tdc_tx_print_detail_config (NOLOCK)
		WHERE	trans_source	= 'BO'		AND 
				module			= 'SO'		AND 
				trans			= 'PNTFRAM'

		--SET	@detail_lines = 1

		IF (@no_rows % @detail_lines) > 0
			SET @totPage = (@no_rows / @detail_lines) + 1
		ELSE
			SET @totPage = @no_rows / @detail_lines    

		SELECT   @FORMAT		= '*FORMAT,' + format_id 
				,@PRINTERNUMBER	= '*PRINTERNUMBER,' + CAST(printer  AS CHAR(2))
				,@QUANTITY		= '*QUANTITY,1'
				,@DUPLICATES	= '*DUPLICATES,'	+ CAST(ABS(quantity) AS CHAR(2))
				,@PRINTLABEL	= '*PRINTLABEL'
		FROM	tdc_tx_print_routing (NOLOCK)
		WHERE	module			= 'SO'			AND 
				trans			= 'PNTFRAM'		AND 
				trans_source	= 'BO'

		SET @i = 1
		WHILE (@i <= @totPage) AND EXISTS(SELECT * FROM #PrintData )
		BEGIN
			SET @LP_ORDER_NO		= 'LP_ORDER_NO,'	+ CAST(@order_no AS VARCHAR(40)) 
			SET @LP_ORDER_EXT		= 'LP_ORDER_EXT,'	+ CAST(@order_ext AS VARCHAR(40))
			SET @LP_ORDER_PLUS_EXT	= 'LP_ORDER_PLUS_EXT,' + CAST(@order_no AS VARCHAR(40))  + '-' + CAST(@order_ext AS VARCHAR(40))


			/******************************************************************** HEADER ********************************************************************/
			INSERT INTO CVO_tdc_print_ticket (print_value, process_id) VALUES (@FORMAT, @@SPID) -- v1.1
			INSERT INTO CVO_tdc_print_ticket (print_value, process_id) VALUES (@LP_ORDER_NO, @@SPID) -- v1.1
			INSERT INTO CVO_tdc_print_ticket (print_value, process_id) VALUES (@LP_ORDER_EXT, @@SPID) -- v1.1
			INSERT INTO CVO_tdc_print_ticket (print_value, process_id) VALUES (@LP_ORDER_PLUS_EXT, @@SPID) -- v1.1		
			
			
			/********************************************************************  BODY ********************************************************************/
			SET @sql = 'INSERT INTO CVO_tdc_print_ticket (print_value, process_id) SELECT TOP ' + CAST(@detail_lines AS VARCHAR(2))  + ' ISNULL(data_field,''NULL'') + '','' + ISNULL(data_value,''NULL''), ' + CAST(@@SPID AS varchar(10)) + '  FROM #PrintData ' -- v1.1
			EXEC (@sql)	

			SET @sql = 'DELETE #PrintData FROM (SELECT TOP ' + CAST(@detail_lines AS VARCHAR(2))  + ' * FROM  #PrintData) AS t1  WHERE #PrintData.row_id = t1.row_id '
			EXEC (@sql)				
			
			/******************************************************************** FOOTER ********************************************************************/
			INSERT INTO CVO_tdc_print_ticket (print_value, process_id) VALUES ('LP_PAGE_NO, ' + CAST(@i AS VARCHAR(2))  + ' of ' + CAST(@totPage AS VARCHAR(2)), @@SPID) -- v1.1
			INSERT INTO CVO_tdc_print_ticket (print_value, process_id) VALUES (@PRINTERNUMBER, @@SPID) -- v1.1
			INSERT INTO CVO_tdc_print_ticket (print_value, process_id) VALUES (@QUANTITY, @@SPID) -- v1.1
			INSERT INTO CVO_tdc_print_ticket (print_value, process_id) VALUES (@DUPLICATES, @@SPID) -- v1.1
			INSERT INTO CVO_tdc_print_ticket (print_value, process_id) VALUES (@PRINTLABEL, @@SPID) -- v1.1
			    
			DECLARE @xp_cmdshell VARCHAR(1000)
			DECLARE @lwlPath	 VARCHAR (100)
			SELECT @lwlPath = ISNULL(value_str,'C:\') FROM dbo.tdc_config WHERE [function] = 'WDDrop_Directory'

			--Without column name
			SET @xp_cmdshell = 'SQLCMD -S ' + @@servername + ' -E -Q "SET NOCOUNT ON SELECT print_value FROM ' + db_name() + '.dbo.CVO_tdc_print_ticket (NOLOCK) WHERE process_id = ' + CAST(@@SPID AS varchar(10)) + ' ORDER BY row_id ASC" -s"," -h -1 -W -b -o  "' + @lwlPath  + '\SO-' + CAST(newid()AS VARCHAR(60)) + '.pas"'  -- v1.1 
				
			EXEC master..xp_cmdshell  @xp_cmdshell, no_output
			
			DELETE FROM CVO_tdc_print_ticket WHERE process_id = @@SPID

			SET @i = @i + 1
		END -- end while 
	END   	 					
END
GO
GRANT EXECUTE ON  [dbo].[CVO_disassembled_print_inv_adjust_sp] TO [public]
GO
