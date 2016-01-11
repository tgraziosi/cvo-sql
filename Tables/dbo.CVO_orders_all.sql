CREATE TABLE [dbo].[CVO_orders_all]
(
[order_no] [int] NOT NULL,
[ext] [int] NOT NULL,
[add_case] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__CVO_order__add_c__5678DC33] DEFAULT ('N'),
[add_pattern] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__CVO_order__add_p__576D006C] DEFAULT ('N'),
[promo_id] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[promo_level] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[free_shipping] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__CVO_order__free___586124A5] DEFAULT ('N'),
[split_order] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__CVO_order__split__595548DE] DEFAULT ('N'),
[flag_print] [smallint] NULL CONSTRAINT [DF__CVO_order__flag___5A496D17] DEFAULT ((1)),
[buying_group] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[allocation_date] [datetime] NULL,
[commission_pct] [decimal] (5, 2) NULL,
[stage_hold] [smallint] NULL,
[prior_hold] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[credit_approved] [int] NULL,
[replen_inv] [smallint] NULL,
[xfer_no] [int] NULL,
[stock_move] [smallint] NULL,
[stock_move_cust_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[stock_move_ship_to] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[stock_move_replace_inv] [smallint] NULL,
[stock_move_order_no] [int] NULL,
[stock_move_ext] [int] NULL,
[stock_move_ri_order_no] [int] NULL,
[stock_move_ri_ext] [int] NULL,
[ra1] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ra2] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ra3] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ra4] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ra5] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ra6] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ra7] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ra8] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[return_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[fee] [decimal] (20, 8) NULL,
[fee_type] [smallint] NULL,
[fee_line] [int] NULL,
[auto_receive] [smallint] NULL,
[invoice_note] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[commission_override] [int] NULL,
[rx_consolidate] [smallint] NULL,
[st_consolidate] [smallint] NULL CONSTRAINT [DF_CVO_orders_all_st_consolidate] DEFAULT ((0)),
[email_address] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[GSH_released] [smallint] NULL CONSTRAINT [DF__CVO_order__GSH_r__11C5B975] DEFAULT ((0)),
[upsell_flag] [int] NULL
) ON [PRIMARY]
GO

SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*
Name:		cvo_orders_all_ins_trg		
Type:		Trigger
Description:	Sets commission level for the inserted order
Version:	1.0
Developer:	Chris Tyler

History
-------
v1.0	CT	13/04/2011	Original Version
v1.1	CT	12/05/2011	Don't update commission if it has already been set (Credit Returns copied from a Sales Order)
v1.2	CT	24/05/2011	Fixed bug in calculating commission 
v1.3	CT	16/09/2014	Issue #1483 - Promo hold reason
*/

CREATE TRIGGER [dbo].[cvo_orders_all_ins_trg] ON [dbo].[CVO_orders_all]
    FOR INSERT
AS
    BEGIN
        DECLARE @order_no INT ,
            @ext INT ,
            @commission DECIMAL(5, 2) ,
			-- START v1.3
            @hold_reason VARCHAR(10) ,
            @location VARCHAR(10) ,
            @data VARCHAR(7500) ,
            @hold_desc VARCHAR(40) ,
            @order_type VARCHAR(10) ,
            @promo_id VARCHAR(20) ,
            @promo_level VARCHAR(30);
			-- END v1.3

        SET @order_no = 0;
		
	-- Get the order to action
        WHILE 1 = 1
            BEGIN
	
                SELECT TOP 1
                        @order_no = order_no
                FROM    inserted
                WHERE   order_no > @order_no
                ORDER BY order_no;

                IF @@RowCount = 0
                    BREAK;

		-- Loop through order extensions
                SET @ext = -1;
                WHILE 1 = 1
                    BEGIN
		
                        SELECT TOP 1
                                @ext = ext
                        FROM    inserted
                        WHERE   order_no = @order_no
                                AND ext > @ext
                        ORDER BY ext;

                        IF @@RowCount = 0
                            BREAK;
		
			-- START v1.1
                        IF NOT EXISTS ( SELECT  1
                                        FROM    dbo.orders_all (NOLOCK)
                                        WHERE   order_no = @order_no
                                                AND ext = @ext
                                                AND type = 'C'
                                                AND orig_no <> 0 ) -- v1.2
                            BEGIN
                                SELECT  @commission = dbo.f_get_order_commission(@order_no,
                                                              @ext); 

                                UPDATE  CVO_orders_all
                                SET     commission_pct = ISNULL(@commission, 0)
                                WHERE   order_no = @order_no
                                        AND ext = @ext;
                            END;
			-- END v1.1

			
			-- tag -- 1/5/16 - check if we need CH WTY note
                        UPDATE  co
                        SET     co.invoice_note = CASE WHEN ISNULL(co.invoice_note,
                                                              '') = ''
                                                       THEN 'Cole Haan frames are for replacement purposes.'
                                                       ELSE ISNULL(co.invoice_note,
                                                              '') + CHAR(13)
                                                            + CHAR(10)
                                                            + 'Cole Haan frames are for replacement purposes.'
                                                  END
                        FROM    dbo.CVO_orders_all AS co
                                JOIN dbo.orders AS o ( NOLOCK ) ON o.order_no = co.order_no
                                                              AND o.ext = co.ext
                        WHERE   co.order_no = @order_no
                                AND co.ext = @ext
                                AND o.type = 'I'
                                AND o.user_category LIKE 'RX%'
                                AND EXISTS ( SELECT 1
                                             FROM   ord_list OL ( NOLOCK )
                                                    JOIN inv_master i ( NOLOCK ) ON i.part_no = OL.part_no
                                             WHERE  OL.order_no = @order_no
                                                    AND OL.order_ext = @ext
                                                    AND i.category = 'CH'
                                                    AND i.type_code IN (
                                                    'frame', 'sun' ) )
                                AND CHARINDEX('Cole Haan frames are for replacement purposes',
                                              ISNULL(co.invoice_note, '')) = 0;
		
                    END;

            END;		
	
	-- START v1.3
	-- Promo hold reason
        SET @order_no = 0;
		
	-- Get the order to action
        WHILE 1 = 1
            BEGIN
	
                SELECT TOP 1
                        @order_no = i.order_no
                FROM    inserted i
                        INNER JOIN dbo.orders_all o ( NOLOCK ) ON i.order_no = o.order_no
                                                              AND i.ext = o.ext
                        INNER JOIN dbo.CVO_promotions p ( NOLOCK ) ON i.promo_id = p.promo_id
                                                              AND i.promo_level = p.promo_level
                WHERE   i.order_no > @order_no
                        AND o.type = 'I'
                        AND o.status = 'N'
                        AND ISNULL(o.hold_reason, '') = ''
                        AND ISNULL(i.prior_hold, '') = ''
                        AND ISNULL(p.hold_reason, '') <> ''
                ORDER BY i.order_no;

                IF @@RowCount = 0
                    BREAK;

		-- Loop through order extensions
                SET @ext = -1;
                WHILE 1 = 1
                    BEGIN
		
                        SELECT TOP 1
                                @ext = i.ext ,
                                @hold_reason = p.hold_reason ,
                                @location = o.location ,
                                @order_type = o.user_category ,
                                @promo_id = i.promo_id ,
                                @promo_level = i.promo_level
                        FROM    inserted i
                                INNER JOIN dbo.orders_all o ( NOLOCK ) ON i.order_no = o.order_no
                                                              AND i.ext = o.ext
                                INNER JOIN dbo.CVO_promotions p ( NOLOCK ) ON i.promo_id = p.promo_id
                                                              AND i.promo_level = p.promo_level
                        WHERE   i.order_no = @order_no
                                AND i.ext > @ext
                                AND o.type = 'I'
                                AND o.status = 'N'
                                AND ISNULL(o.hold_reason, '') = ''
                                AND ISNULL(i.prior_hold, '') = ''
                                AND ISNULL(p.hold_reason, '') <> ''
                        ORDER BY i.ext;

                        IF @@RowCount = 0
                            BREAK;
		
			-- Put order on hold
                        UPDATE  dbo.orders_all
                        SET     status = 'A' ,
                                hold_reason = @hold_reason
                        WHERE   order_no = @order_no
                                AND ext = @ext;

			-- Write tdc_log record
                        SELECT  @hold_desc = hold_reason
                        FROM    dbo.adm_oehold (NOLOCK)
                        WHERE   hold_code = @hold_reason;
			
                        SET @data = 'STATUS:A/USER HOLD; HOLD REASON:'
                            + @hold_reason + ' - ' + @hold_desc
                            + '; ORDER TYPE: ' + @order_type + '; PROMO ID: '
                            + @promo_id + ' ; PROMO LEVEL: ' + @promo_level;

                        INSERT  INTO tdc_log
                                ( tran_date ,
                                  UserID ,
                                  trans_source ,
                                  module ,
                                  trans ,
                                  tran_no ,
                                  tran_ext ,
                                  part_no ,
                                  lot_ser ,
                                  bin_no ,
                                  location ,
                                  quantity ,
                                  data
                                )
                                SELECT  GETDATE() ,
                                        SUSER_SNAME() ,
                                        'BO' ,
                                        'ADM' ,
                                        'ORDER UPDATE' ,
                                        CAST(@order_no AS VARCHAR) ,
                                        CAST(@ext AS VARCHAR) ,
                                        '' ,
                                        '' ,
                                        '' ,
                                        @location ,
                                        '' ,
                                        @data;
                    END;

            END;			
	-- END v1.3	
    END;


GO
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*
Name:		cvo_orders_all_insupd_trg		
Type:		Trigger
Description:	TBB processing for credit returns
Version:	1.0
Developer:	Chris Tyler

History
-------
v1.0	CT	13/07/2012	Original Version
v1.1	CT	18/09/2012	Note is now written here
v1.2	CB	03/10/2012	Moved to client as causing issues when multiple lines included
v1.3	CT	17/10/2012	Ignore credit returns on user hold
v1.4	CT	17/10/2012	Auto-receive functionality
v1.5	CT	07/05/2013	Issue 1261 - TBB credit returns failing due to trigger recursion - moving commission recalc here
*/

CREATE TRIGGER [dbo].[cvo_orders_all_insupd_trg] ON [dbo].[CVO_orders_all]
FOR UPDATE
--FOR INSERT, UPDATE -- v1.2
AS
BEGIN
	DECLARE	@order_no		int,
			@ext			int,
			@stock_move		smallint,
			@replace_inv	smallint,
			@s_cust_code	VARCHAR(10),
			@s_ship_to		VARCHAR(10),
			@s_order_no		INT,
			@ri_order_no	INT,
			@updated		SMALLINT,
			-- START v1.1
			@note			varchar(100),
			@so_created		SMALLINT,
			@ri_created		SMALLINT,
			-- END v1.1
			-- START v1.4
			@status			CHAR(1),
			@auto_receive	SMALLINT,
			-- END v1.4
			@commission		DECIMAL(5,2) -- v1.5

	SET @order_no = 0
		
	-- Get the order to action
	WHILE 1=1
	BEGIN
	
		SELECT TOP 1 
			@order_no = a.order_no,
			@status = b.[status]	-- v1.4
		FROM 
			inserted a
		INNER JOIN
			dbo.orders_all b (NOLOCK)
		ON
			a.order_no = b.order_no
			AND a.ext = b.ext
		WHERE
			a.order_no > @order_no
			AND b.[type] = 'C'
			AND b.[status] NOT IN ('A','V')	-- v1.3
		ORDER BY 
			a.order_no

		IF @@RowCount = 0
			Break

		-- Loop through order extensions
		SET @ext = -1
		WHILE 1=1
		BEGIN
		
			SELECT TOP 1 
				@ext = ext,
				@stock_move = stock_move,
				@replace_inv = stock_move_replace_inv,
				@s_cust_code = stock_move_cust_code,
				@s_ship_to = stock_move_ship_to,
				@s_order_no = stock_move_order_no,
				@ri_order_no = stock_move_ri_order_no,
				@auto_receive = auto_receive -- v1.4
			FROM 
				inserted 
			WHERE
				order_no = @order_no
				AND ext > @ext
				AND (ISNULL(stock_move,0) = 1 OR ISNULL(auto_receive,0) = 1) -- v1.4
			ORDER BY 
				ext

			IF @@RowCount = 0
				Break
		
			
			-- Stock move
			-- START v1.4
			IF ISNULL(@stock_move,0) = 1
			BEGIN
			-- END v1.4
				SET @updated = 0
				SET @so_created = 0	-- v1.1
				SET @ri_created = 0	-- v1.1

				-- If no stock move order has been created then create one
				IF @s_order_no IS NULL AND ISNULL(@s_cust_code,'') <> ''
				BEGIN

					EXEC @s_order_no = dbo.CVO_create_stock_move_salesorder_sp @order_no, @ext, @s_cust_code, @s_ship_to
					SET @updated = 1
					SET @so_created = 1 -- v1.1
				END

				-- If no replace inv order has been created then create one
				IF @ri_order_no IS NULL AND ISNULL(@s_cust_code,'') <> '' AND ISNULL(@replace_inv,0) = 1
				BEGIN
					EXEC @ri_order_no = dbo.CVO_create_replace_inv_salesorder_sp @order_no, @ext
					SET @updated = @updated + 2
					SET @ri_created = 1	-- v1.1
				END

				-- Update with order details
				IF @updated > 0
				BEGIN
					UPDATE
						dbo.cvo_orders_all
					SET
						stock_move_order_no = CASE @updated WHEN 1 THEN @s_order_no WHEN 3 THEN @s_order_no ELSE stock_move_order_no END,
						stock_move_ext = CASE @updated WHEN 1 THEN 0 WHEN 3 THEN 0 ELSE stock_move_ext END,
						stock_move_ri_order_no = CASE @updated WHEN 2 THEN @ri_order_no WHEN 3 THEN @ri_order_no ELSE stock_move_ri_order_no END,
						stock_move_ri_ext = CASE @updated WHEN 2 THEN 0 WHEN 3 THEN 0 ELSE stock_move_ri_ext END
					WHERE
						order_no = @order_no
						AND ext = @ext

	-- v1.2 Start				
					-- START v1.1 - write note to credit return
	--				SET @note = ''
	--				IF @so_created = 1
	--				BEGIN
	--					SET @note = @note + 'Stock Move Sales Order: ' + CAST (@s_order_no AS VARCHAR(10)) + '-0'
	--				END
	--
	--				IF @ri_created = 1
	--				BEGIN
	--					IF LEN(@note) > 0
	--					BEGIN
	--						SET @note = @note + CHAR(13) + CHAR(10)
	--					END
	--
	--					SET @note = @note + 'Inventory Replacement Sales Order: ' + CAST (@ri_order_no AS VARCHAR(10)) + '-0'
	--				END
	--
	--				IF (@so_created = 1) OR (@ri_created = 1)
	--				BEGIN
	--					UPDATE
	--						dbo.orders_all
	--					SET
	--						note = (CASE ISNULL(note,'') WHEN '' THEN '' ELSE note + CHAR(13) + CHAR(10) END) + @note
	--					WHERE
	--						order_no = @order_no
	--						AND ext = @ext
	--				END
					-- END v1.1
	-- v1.2 End
				END
			END -- v1.4

			-- START v1.4
			IF ISNULL(@auto_receive,0) = 1 AND @status = 'N'
			BEGIN
				-- If there isn't already a record in the auto receive processing table, insert one
				IF NOT EXISTS (SELECT 1 FROM dbo.cvo_auto_receive_credit_return (NOLOCK) WHERE order_no = @order_no AND ext = @ext AND processed IN (0,1))
				BEGIN
					INSERT cvo_auto_receive_credit_return(
						order_no,
						ext,
						processed)
					SELECT
						@order_no,
						@ext,
						0
				END
			END	
			-- END v1.4			
		END
		
		-- START v1.4 
		-- Loop through order extensions looking for credits where auto_receive has been switched off
		SET @ext = -1
		WHILE 1=1
		BEGIN
		
			SELECT TOP 1 
				@ext = i.ext
			FROM 
				inserted i
			INNER JOIN	
				deleted d
			ON
				i.order_no = d.order_no
				AND i.ext = d.ext
			WHERE
				i.order_no = @order_no
				AND i.ext > @ext
				AND ISNULL(i.auto_receive,0) = 0 
				AND ISNULL(d.auto_receive,0) = 1
			ORDER BY 
				i.ext

			IF @@ROWCOUNT = 0
				BREAK

			-- Check if there is a record in the auto receive processing table
			IF EXISTS (SELECT 1 FROM dbo.cvo_auto_receive_credit_return (NOLOCK) WHERE order_no = @order_no AND ext = @ext AND processed IN (0,1))
			BEGIN
				DELETE FROM 
					dbo.cvo_auto_receive_credit_return  
				WHERE 
					order_no = @order_no 
					AND ext = @ext 
					AND processed = 0
			END
		END
		-- END v1.4

		-- START v1.4 
		-- Loop through order extensions looking for credits where auto_receive has been switched off
		SET @ext = -1
		WHILE 1=1
		BEGIN
		
			SELECT TOP 1 
				@ext = i.ext
			FROM 
				inserted i
			INNER JOIN	
				deleted d
			ON
				i.order_no = d.order_no
				AND i.ext = d.ext
			WHERE
				i.order_no = @order_no
				AND i.ext > @ext
				AND ISNULL(i.auto_receive,0) = 0 
				AND ISNULL(d.auto_receive,0) = 1
			ORDER BY 
				i.ext

			IF @@ROWCOUNT = 0
				BREAK

			-- Check if there is a record in the auto receive processing table
			IF EXISTS (SELECT 1 FROM dbo.cvo_auto_receive_credit_return (NOLOCK) WHERE order_no = @order_no AND ext = @ext AND processed IN (0,1))
			BEGIN
				DELETE FROM 
					dbo.cvo_auto_receive_credit_return  
				WHERE 
					order_no = @order_no 
					AND ext = @ext 
					AND processed = 0
			END
		END
		-- END v1.4
	END	

	-- START v1.5 - calculate commission
	SET @order_no = 0
		
	-- Get the order to action
	WHILE 1=1
	BEGIN
	
		SELECT TOP 1 
			@order_no = a.order_no,
			@ext = a.ext  -- Credits only have ext=0 so no need to loop through extensions
		FROM 
			inserted a
		INNER JOIN
			dbo.orders_all b (NOLOCK)
		ON
			a.order_no = b.order_no
			AND a.ext = b.ext
		WHERE
			a.order_no > @order_no
			AND b.[type] = 'C'
			AND b.[status] <> 'V'	
			and ISNULL(b.orig_no,0) = 0 -- Don't do this for credits linked to Sales Orders
		ORDER BY 
			a.order_no

		IF @@RowCount = 0
			Break

		-- Recalculate commission
		SELECT @commission = dbo.f_get_order_commission(@order_no,@ext)   					

		UPDATE  
			dbo.cvo_orders_all  
		SET   
			commission_pct = ISNULL(@commission,0)  
		WHERE  
			order_no = @order_no  
			AND ext = @ext  
	END
	-- END v1.5		
END


GO

SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*  
Name:  cvo_orders_all_upd_trg    
Type:  Trigger  
Description: For an order which is switching between subscription promotions, recalculate commission  
Version: 1.0  
Developer: Chris Tyler  
  
History  
-------  
v1.0 CT 23/11/2012 Original Version  
v1.1 CT 22/04/2013 Issue 1230 - change in commission logic - always recalc for SO's and manual Credits
v1.2 CT 07/05/2013 Issue 1261 - TBB credit returns failing due to trigger recursion - moving commission recalc to cvo_orders_all_insupd_trg
*/  
  
CREATE TRIGGER [dbo].[cvo_orders_all_upd_trg] ON [dbo].[CVO_orders_all]
    FOR UPDATE
AS
    BEGIN  
        DECLARE @order_no INT ,
            @ext INT ,
            @commission DECIMAL(5, 2) ,
            @i_promo_id VARCHAR(20) ,
            @i_promo_level VARCHAR(30) ,
            @d_promo_id VARCHAR(20) ,
            @d_promo_level VARCHAR(30);  

        SET @order_no = 0;  

	-- Get the order to action  
        WHILE 1 = 1
            BEGIN  

                SELECT TOP 1
                        @order_no = order_no
                FROM    inserted
                WHERE   order_no > @order_no
                ORDER BY order_no;  

                IF @@RowCount = 0
                    BREAK;  

		-- START v1.2 - only do this for orders
		/*
		-- START v1.1 - Don't do this for credits linked to Sales Orders
		IF NOT EXISTS (SELECT 1 FROM dbo.orders_all (NOLOCK) WHERE order_no = @order_no AND ext = 0 AND type = 'C' and orig_no <> 0)
		*/
		-- Only do this for orders
                IF EXISTS ( SELECT  1
                            FROM    dbo.orders_all (NOLOCK)
                            WHERE   order_no = @order_no
                                    AND ext = 0
                                    AND type = 'I' )
		-- END v1.2
		-- END v1.1
                    BEGIN

			-- START v1.1
			-- Now do this for all extensions 
                        SET @ext = -1;  
                        WHILE 1 = 1
                            BEGIN  

                                SELECT TOP 1
                                        @ext = ext
                                FROM    inserted
                                WHERE   order_no = @order_no
                                        AND ext > @ext
                                ORDER BY ext;  

                                IF @@RowCount = 0
                                    BREAK;  


				-- Recalculate commission
                                SELECT  @commission = dbo.f_get_order_commission(@order_no,
                                                              @ext);   					

                                UPDATE  dbo.CVO_orders_all
                                SET     commission_pct = ISNULL(@commission, 0)
                                WHERE   order_no = @order_no
                                        AND ext = @ext;  

							-- tag -- 1/5/16 - check if we need CH WTY note
                                UPDATE  co
                                SET     co.invoice_note = CASE
                                                              WHEN ISNULL(co.invoice_note,
                                                              '') = ''
                                                              THEN 'Cole Haan frames are for replacement purposes.'
                                                              ELSE ISNULL(co.invoice_note,
                                                              '') + CHAR(13)
                                                              + CHAR(10)
                                                              + 'Cole Haan frames are for replacement purposes.'
                                                          END
                                FROM    dbo.CVO_orders_all AS co
                                        JOIN dbo.orders AS o ( NOLOCK ) ON o.order_no = co.order_no
                                                              AND o.ext = co.ext
                                WHERE   co.order_no = @order_no
                                        AND co.ext = @ext
                                        AND o.type = 'I'
                                        AND o.user_category LIKE 'RX%'
                                        AND EXISTS ( SELECT 1
                                                     FROM   ord_list OL ( NOLOCK )
                                                            JOIN inv_master i ( NOLOCK ) ON i.part_no = OL.part_no
                                                     WHERE  OL.order_no = @order_no
                                                            AND OL.order_ext = @ext
                                                            AND i.category = 'CH'
                                                            AND i.type_code IN (
                                                            'frame', 'sun' ) )
                                        AND CHARINDEX('Cole Haan frames are for replacement purposes',
                                                      ISNULL(co.invoice_note,
                                                             '')) = 0;


                            END;
			
			/*
			-- Loop through order extensions where promo has changed 
			SET @ext = -1  
			WHILE 1=1  
			BEGIN  

				SELECT TOP 1   
					@ext = i.ext,
					@i_promo_id = i.promo_id,
					@i_promo_level = i.promo_level,  
					@d_promo_id = d.promo_id,
					@d_promo_level = d.promo_level
				FROM   
					inserted i
				INNER JOIN
					deleted d
				ON
					i.order_no = d.order_no
					AND i.ext = d.ext  
				WHERE  
					i.order_no = @order_no  
					AND i.ext > @ext  
					AND NOT (i.promo_id = d.promo_id AND i.promo_level = d.promo_level)
					AND ISNULL(i.promo_id, '') <> ''
					AND ISNULL(d.promo_id, '') <> ''
				ORDER BY   
					i.ext  

				IF @@RowCount = 0  
					Break  


				-- Check if promos are subscription promos
				IF EXISTS (SELECT 1 FROM dbo.cvo_promotions (NOLOCK) WHERE promo_id = @i_promo_id AND promo_level = @i_promo_level AND ISNULL(subscription,0) = 1)
				BEGIN
					IF EXISTS (SELECT 1 FROM dbo.cvo_promotions (NOLOCK) WHERE promo_id = @d_promo_id AND promo_level = @d_promo_level AND ISNULL(subscription,0) = 1)
					BEGIN
						-- Recalculate commission
						SELECT @commission = dbo.f_get_order_commission(@order_no,@ext)   					

						UPDATE  
							dbo.cvo_orders_all  
						SET   
							commission_pct = ISNULL(@commission,0)  
						WHERE  
							order_no = @order_no  
							AND ext = @ext  

					END
				END
			END 
			*/
                    END;     
            END;
    END;  
  
  
GO

CREATE NONCLUSTERED INDEX [CVO_orders_all_bg_032814] ON [dbo].[CVO_orders_all] ([buying_group]) INCLUDE ([order_no], [ext]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [ord1] ON [dbo].[CVO_orders_all] ([order_no], [ext]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [coa_ra1_idx] ON [dbo].[CVO_orders_all] ([ra1]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [coa_ra2_idx] ON [dbo].[CVO_orders_all] ([ra2]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [coa_ra3_idx] ON [dbo].[CVO_orders_all] ([ra3]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [coa_ra4_idx] ON [dbo].[CVO_orders_all] ([ra4]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [coa_ra5_idx] ON [dbo].[CVO_orders_all] ([ra5]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [coa_ra6_idx] ON [dbo].[CVO_orders_all] ([ra6]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [coa_ra7_idx] ON [dbo].[CVO_orders_all] ([ra7]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [coa_ra8_idx] ON [dbo].[CVO_orders_all] ([ra8]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[CVO_orders_all] TO [public]
GO
GRANT SELECT ON  [dbo].[CVO_orders_all] TO [public]
GO
GRANT INSERT ON  [dbo].[CVO_orders_all] TO [public]
GO
GRANT DELETE ON  [dbo].[CVO_orders_all] TO [public]
GO
GRANT UPDATE ON  [dbo].[CVO_orders_all] TO [public]
GO
