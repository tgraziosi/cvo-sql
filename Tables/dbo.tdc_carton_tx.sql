CREATE TABLE [dbo].[tdc_carton_tx]
(
[order_no] [int] NOT NULL,
[order_ext] [int] NOT NULL,
[carton_no] [int] NOT NULL,
[carton_type] [char] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[carton_class] [char] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cust_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[cust_po] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[carrier_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[shipper] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_to_no] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[address1] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[address2] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[address3] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[city] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[state] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[zip] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[country] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[attention] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[date_shipped] [datetime] NULL,
[weight] [decimal] (20, 8) NULL,
[weight_uom] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cs_tx_no] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cs_tracking_no] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cs_zone] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cs_oversize] [char] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cs_call_tag_no] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cs_airbill_no] [varchar] (18) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cs_other] [money] NULL,
[cs_pickup_no] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cs_dim_weight] [decimal] (20, 8) NULL,
[cs_published_freight] [decimal] (20, 8) NULL,
[cs_disc_freight] [decimal] (20, 8) NULL,
[cs_estimated_freight] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cust_freight] [decimal] (20, 8) NULL,
[freight_to] [char] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[adjust_rate] [int] NULL,
[template_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[operator] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[consolidated_pick_no] [int] NULL,
[void] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[status] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[station_id] [char] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[charge_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[bill_to_key] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[last_modified_date] [datetime] NOT NULL,
[modified_by] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[order_type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_tdc_carton_tx_order_type] DEFAULT ('S'),
[stlbin_no] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[stl_status] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_tdc_carton_tx_stl_status] DEFAULT ('N'),
[changed] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__tdc_carto__chang__74EDB251] DEFAULT ('N'),
[carton_content_value] [decimal] (20, 8) NULL,
[carton_tax_value] [decimal] (20, 2) NULL,
[carton_seq] [int] NULL CONSTRAINT [DF__tdc_carto__carto__75E1D68A] DEFAULT (NULL),
[tag_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[lic_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[carton_cnt] [int] NULL,
[SSCC] [varchar] (18) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tag_type] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[epc_tag] [varchar] (24) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SGTIN] [varchar] (24) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[CVO_Carton_Xfer_tr] ON [dbo].[tdc_carton_tx] FOR INSERT AS
BEGIN

DECLARE @carton_no int,
		@t_order int,
		@c_ord_type char(1),
		@to_loc varchar(10),
		@city varchar(40),
		@state varchar(40),
		@zip varchar(15)

-- START v1.1
DECLARE @addr3 VARCHAR(40),
		@char_pos INT,
		@space_pos INT
-- END v1.1

SELECT @carton_no = 0

WHILE( @carton_no >= 0)
BEGIN
		SELECT @carton_no = min(carton_no), @c_ord_type = min(order_type), @t_order = min(order_no)
		  FROM inserted WHERE carton_no > @carton_no

		IF @c_ord_type <> 'T'
		BEGIN
			RETURN
		END

		SELECT @to_loc = IsNull(to_loc,' ') FROM xfers WHERE xfer_no = @t_order

		-- START v1.1
		--SELECT @city = IsNull(city,''), @state = IsNull(state,''), @zip = IsNull(zip,'') FROM Locations where location = @to_loc

		-- Get addr3
		SELECT @addr3 = addr3 FROM dbo.arsalesp (NOLOCK) WHERE addr_sort1 = @to_loc

		SET @city = ''
		SET @state = ''
		SET @zip = ''

		-- City, it is followed by a comma
		SET @char_pos = 0
		SET @char_pos = CHARINDEX(',',@addr3,1)

		IF @char_pos > 1
		BEGIN
			SET @city = LEFT(@addr3, (@char_pos - 1))

			-- Remove city from address line and then strip leading/trailing spaces
			SET @addr3 = LTRIM(RTRIM(RIGHT(@addr3,(LEN(@addr3) - @char_pos))))

			-- ZIP is preceeded by a space, so get the position of the last space in the string
			SET @char_pos = 1
			SET @space_pos = 0
			WHILE 1=1
			BEGIN
				SET @char_pos = CHARINDEX(' ',@addr3,(@space_pos + 1))	
				IF @char_pos  = 0
				BEGIN
					BREAK
				END
				ELSE
				BEGIN
					SET @space_pos = @char_pos
				END
			END

			IF @space_pos <> 0
			BEGIN
				SET @zip = LTRIM(RTRIM(RIGHT(@addr3,(LEN(@addr3) - @space_pos))))

				-- For state, remove zip from address line and then strip leading/trailing spaces
				SET @state = LTRIM(RTRIM(LEFT(@addr3,@space_pos)))
			END
			ELSE
			BEGIN
				SET @state = @addr3
			END
		END
		ELSE
		BEGIN
			SET @city = @addr3
		END
		-- END v1.1

		UPDATE tdc_carton_tx SET city = @city, state = @state, zip = @zip WHERE carton_no = @carton_no

END
END

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER  [dbo].[tdc_archive_order_tg]  ON [dbo].[tdc_carton_tx]
FOR INSERT, UPDATE
AS

DECLARE 	@strADM_Ship_Flag	AS CHAR(1),
	    	@strTDC_Ship_Flag	AS CHAR(1),
	  	@intCarton_No		AS INTEGER,
		@intOrder_No		AS INTEGER ,
		@intOrder_Ext		AS INTEGER ,
		@intConsolidation_No	AS INTEGER ,
		@intNotShipped		AS INTEGER 

SELECT 	@intCarton_No = ISNULL(MIN(carton_no),-1)
FROM inserted
WHERE status = 'X'

--Since can INSERT multiple records lets loop thru the INSERTED table
WHILE @intCarton_No > 0
	BEGIN
		SELECT 	@strADM_Ship_Flag = adm_ship_flag , 
			@strTDC_Ship_Flag = tdc_ship_flag 
			FROM tdc_stage_carton (NOLOCK)
			WHERE carton_no = @intCarton_No

		IF @strADM_Ship_Flag = 'Y'  AND @strTDC_Ship_Flag = 'Y'
			BEGIN
				--Let's find the order_no for this carton; you can ONLY have
				-- one order per carton

				SELECT @intOrder_No = order_no, @intOrder_Ext = order_ext
					FROM tdc_carton_tx (NOLOCK)
					WHERE carton_no = @intCarton_No

				--Now that we have the order_no, order_ext 
				--lets do a count on all the cartons for this order_no, order_ext 
				--that have NOT been shipped
				SELECT @intNotShipped = COUNT(*) 
					FROM tdc_carton_tx (NOLOCK)
					WHERE order_no = @intOrder_No 
					AND order_ext  = @intOrder_Ext 
					AND status <> 'X'
			
				IF @intNotShipped  = 0 --All Cartons for this Order_No, Order_Ext
						       -- have been shipped
					BEGIN
						INSERT INTO tdc_cons_ords_arch (consolidation_no, order_no,	order_ext, location, status, seq_no, print_count,
														order_type) 
							SELECT consolidation_no, order_no,	order_ext, location, status, seq_no, print_count,
														order_type FROM tdc_cons_ords (NOLOCK)
							WHERE order_no  = @intOrder_No
							AND   order_ext = @intOrder_Ext
						--Lets get the consolidation_no and after delete
						-- this records from tdc_cons_ords, check if
						-- any other records for this consolidation_no
						SELECT @intConsolidation_No = consolidation_no
							FROM tdc_cons_ords (NOLOCK)
							WHERE order_no  = @intOrder_No
							AND   order_ext = @intOrder_Ext

						--Now that we've archived the info from 
						--tdc_cons_ords table for this Order_No, Order_Ext
						-- lets delete the info 	
						DELETE FROM tdc_cons_ords	
						WHERE order_no 	= @intOrder_No
						AND   order_ext	= @intOrder_Ext	
						
						IF (SELECT COUNT(*) FROM tdc_cons_ords (NOLOCK)
							WHERE consolidation_no = @intConsolidation_No) = 0
							BEGIN
							--INSERT into tdc_main for this consolidation_no
							--and then delete from tdc_main for this consolidation_no
								INSERT INTO tdc_main_arch (consolidation_no, consolidation_name, order_type, [description],  
												created_by,creation_date,filter_name_used,status,Virtual_Freight, pre_pack)
									SELECT consolidation_no, consolidation_name, order_type, [description],  
									       created_by,creation_date,filter_name_used,status,Virtual_Freight, pre_pack
									 FROM tdc_main (NOLOCK)
									 WHERE consolidation_no = @intConsolidation_No 

								DELETE FROM tdc_main 
									WHERE consolidation_no = @intConsolidation_No 


							END

					END


			END

		SELECT @intCarton_No = ISNULL(MIN(carton_no),-1)
		FROM INSERTED 
		WHERE carton_no > @intCarton_No 
		AND status = 'X'

	END



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[tdc_updcarton_hdr_trg] ON [dbo].[tdc_carton_tx]
FOR UPDATE AS

BEGIN

DECLARE @carton_no int



IF NOT UPDATE (carrier_code) AND NOT UPDATE (cs_tracking_no) AND NOT UPDATE (cs_published_freight) AND NOT UPDATE (cs_disc_freight)
	AND NOT UPDATE (cs_estimated_freight) AND NOT UPDATE (cust_freight) AND NOT UPDATE (adjust_rate)
BEGIN
	return
END

SELECT @carton_no = 0

WHILE( @carton_no >= 0)
BEGIN
		SELECT @carton_no = isnull((SELECT min(carton_no) from inserted WHERE carton_no > @carton_no), -1)
		UPDATE tdc_carton_tx SET changed = 'Y' WHERE carton_no = @carton_no

END

END

		
	

					



GO
ALTER TABLE [dbo].[tdc_carton_tx] ADD CONSTRAINT [PK_tdc_carton_tx] PRIMARY KEY NONCLUSTERED  ([carton_no], [order_no], [order_ext]) ON [PRIMARY]
GO
CREATE CLUSTERED INDEX [tdc_carton_tx_idx_1] ON [dbo].[tdc_carton_tx] ([carton_no]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_carton_tx_idx_2] ON [dbo].[tdc_carton_tx] ([order_no], [order_ext]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_carton_tx_idx_3] ON [dbo].[tdc_carton_tx] ([order_no], [order_ext], [carton_no]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_carton_tx] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_carton_tx] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_carton_tx] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_carton_tx] TO [public]
GO
