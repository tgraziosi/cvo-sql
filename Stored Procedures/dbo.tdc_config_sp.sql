SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROC [dbo].[tdc_config_sp]
	@index int,
	@saving char(1) = 'N'
AS

DECLARE 
	@LBO_FIFO		varchar(15),
	@LBO_LIFO		varchar(15),
	@LBO_LOT_BIN_ASC	varchar(15),
	@LBO_LOT_BIN_DESC	varchar(15),
	@LBO_QTY_ASC		varchar(15),
	@LBO_QTY_DESC		varchar(15),
	@SO_PICK_TICKET_7	varchar(50),
	@SO_PICK_TICKET_8	varchar(50),
	@SO_PICK_TICKET_9	varchar(50) 

SELECT  @LBO_FIFO		= 'FIFO',
	@LBO_LIFO		= 'LIFO',
	@LBO_LOT_BIN_ASC	= 'LOT/BIN ASC',
	@LBO_LOT_BIN_DESC	= 'LOT/BIN DESC',
	@LBO_QTY_ASC		= 'QTY. ASC',
	@LBO_QTY_DESC		= 'QTY. DESC',
	@SO_PICK_TICKET_7	= 'Print PLW SO Pick Ticket Only',
	@SO_PICK_TICKET_8	= 'Print PLW SO Consolidated Pick Ticket Only',
	@SO_PICK_TICKET_9	= 'Print Both'

---------------------------------------------------------------------------------------------------------------
--  IF NOT SAVING (REFRESH)
---------------------------------------------------------------------------------------------------------------
IF @saving = 'N'
BEGIN
	---------------------------------------------------------------------------------------------------------------
	--  Clear the screens
	---------------------------------------------------------------------------------------------------------------
	TRUNCATE TABLE #temp_config
	TRUNCATE TABLE #temp_ip_screen

	---------------------------------------------------------------------------------------------------------------
	--  General Config
	---------------------------------------------------------------------------------------------------------------
	IF @index = 0 
	BEGIN
		INSERT INTO #temp_config (mod_owner, [function], [description], active, value_str)
		SELECT mod_owner, UPPER([function]), [description], active, 
		       value_str = CASE WHEN (mod_owner = 'LBO' AND value_str = '1')
						THEN @LBO_LIFO	
					WHEN (mod_owner = 'LBO' AND value_str = '2')
						THEN @LBO_FIFO							
					WHEN (mod_owner = 'LBO' AND value_str = '3')
						THEN @LBO_LOT_BIN_ASC
					WHEN (mod_owner = 'LBO' AND value_str = '4')
						THEN @LBO_LOT_BIN_DESC
					WHEN (mod_owner = 'LBO' AND value_str = '5')
						THEN @LBO_QTY_ASC
					WHEN (mod_owner = 'LBO' AND value_str = '6')
						THEN @LBO_QTY_DESC

					WHEN (mod_owner = 'PLW' AND [function] = 'so_pick_ticket' AND value_str = '7')
						THEN @SO_PICK_TICKET_7
					WHEN (mod_owner = 'PLW' AND [function] = 'so_pick_ticket' AND value_str = '8')
						THEN @SO_PICK_TICKET_8
					WHEN (mod_owner = 'PLW' AND [function] = 'so_pick_ticket' AND value_str = '9')
						THEN @SO_PICK_TICKET_9	
					ELSE
						value_str	
				  END		 
		  FROM tdc_config (NOLOCK)                                   
		 WHERE mod_owner NOT IN ('CON', 'QTX', 'PPS', 'PRT', 'PTS')                 
		   AND [function] NOT IN ('dist_item_desc')    
	END

	---------------------------------------------------------------------------------------------------------------
	--  Console Config
	---------------------------------------------------------------------------------------------------------------
	ELSE IF @index = 1
	BEGIN
		INSERT INTO #temp_config (mod_owner, [function], [description], active, value_str)
		SELECT mod_owner, UPPER([function]), [description], active, value_str            
	         FROM tdc_config (NOLOCK)                                   
	        WHERE mod_owner = 'CON'
	END
 
	---------------------------------------------------------------------------------------------------------------
	--  Queue Config
	---------------------------------------------------------------------------------------------------------------
	ELSE IF @index = 2
	BEGIN
		INSERT INTO #temp_config (mod_owner, [function], [description], active, value_str)
		SELECT mod_owner, UPPER([function]), [description], active, value_str          
	         FROM tdc_config (NOLOCK)                                   
	        WHERE mod_owner = 'QTX'  
	END
 
	---------------------------------------------------------------------------------------------------------------
	--  PPS Config
	---------------------------------------------------------------------------------------------------------------
	ELSE IF @index = 3
	BEGIN
		INSERT INTO #temp_config (mod_owner, [function], [description], active, value_str)
		SELECT mod_owner, UPPER([function]), [description], active, value_str   
	         FROM tdc_config (NOLOCK)                                   
	        WHERE mod_owner='PPS'     
	END
	
	---------------------------------------------------------------------------------------------------------------
	--  Print Config
	---------------------------------------------------------------------------------------------------------------
	ELSE IF @index = 4
	BEGIN
		INSERT INTO #temp_config (mod_owner, [function], [description], active, value_str)
		SELECT mod_owner, UPPER([function]), [description], active, value_str   
	         FROM tdc_config (NOLOCK)                                   
	        WHERE mod_owner IN ( 'PRT', 'PTS'   )
	END
	---------------------------------------------------------------------------------------------------------------
	--  IP Config
	---------------------------------------------------------------------------------------------------------------
	ELSE IF @index = 5
	BEGIN
		INSERT INTO #temp_ip_screen (ip, screen_size, [description])
		SELECT ip, screen_size, [description]
		  FROM tdc_ip_screen 
	END                
 
END
------------------------------------------------------------------------------------------------------------------------
-- Saving 
------------------------------------------------------------------------------------------------------------------------
ELSE
BEGIN
	---------------------------------------------------------------------------------------------------------------
	--  General Config
	---------------------------------------------------------------------------------------------------------------
	IF @index < 5
	BEGIN
		UPDATE tdc_config
		   SET active = #temp_config.active,
		       value_str = CASE WHEN (#temp_config.mod_owner = 'LBO' AND #temp_config.value_str = @LBO_LIFO)
						THEN '1'
					WHEN (#temp_config.mod_owner = 'LBO' AND #temp_config.value_str = @LBO_FIFO)
						THEN '2'								
					WHEN (#temp_config.mod_owner = 'LBO' AND #temp_config.value_str = @LBO_LOT_BIN_ASC)
						THEN '3'
					WHEN (#temp_config.mod_owner = 'LBO' AND #temp_config.value_str = @LBO_LOT_BIN_DESC)
						THEN '4'
					WHEN (#temp_config.mod_owner = 'LBO' AND #temp_config.value_str = @LBO_QTY_ASC)
						THEN '5'
					WHEN (#temp_config.mod_owner = 'LBO' AND #temp_config.value_str = @LBO_QTY_DESC)
						THEN '6'

					WHEN (#temp_config.[function] = 'so_pick_ticket' 
									     AND #temp_config.value_str = @SO_PICK_TICKET_7)
						THEN '7'
					WHEN (#temp_config.[function] = 'so_pick_ticket' 
									     AND #temp_config.value_str = @SO_PICK_TICKET_8)
						THEN '8'
					WHEN (#temp_config.[function] = 'so_pick_ticket' 
									     AND #temp_config.value_str = @SO_PICK_TICKET_9)
						THEN '9'
					ELSE
						#temp_config.value_str	
				  END
		  FROM tdc_config,
		       #temp_config
		 WHERE tdc_config.mod_owner = #temp_config.mod_owner
		   AND tdc_config.[function] = #temp_config.[function]
	
	END
	---------------------------------------------------------------------------------------------------------------
	--  I.P. Config
	---------------------------------------------------------------------------------------------------------------
	ELSE  
	BEGIN
		UPDATE tdc_ip_screen
		   SET screen_size   = #temp_ip_screen.screen_size,
		       [description] = #temp_ip_screen.[description]
		  FROM tdc_ip_screen,
		       #temp_ip_screen
		 WHERE tdc_ip_screen.ip = #temp_ip_screen.ip

	END
	 
END


GO
GRANT EXECUTE ON  [dbo].[tdc_config_sp] TO [public]
GO
