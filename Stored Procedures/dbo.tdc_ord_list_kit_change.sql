SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[tdc_ord_list_kit_change] 
	@order_no integer,
	@ext integer,
	@line_no integer,
	@part varchar(30),
	@qty decimal(20,8),
	@stat varchar(35) AS

DECLARE @ordered decimal(20,8), 
	@qty_per decimal(20,8), 
	@tdc_ordered decimal(20,8), 
	@tdc_qty_per decimal(20,8), 
	@part_no varchar(30), 
	@sub_part_no varchar(30), 
	@language varchar(20), 
	@errmsg varchar(255),
	@kit_part_no varchar(30),
	@type char(1)


IF (@ext = 0)
BEGIN
	-- blanket order for extension zero
	-- multiple ship to order for extension zero
	IF EXISTS (SELECT * FROM orders (nolock) WHERE order_no = @order_no AND ext = 0 AND (blanket = 'Y' OR multiple_flag = 'Y'))
		RETURN 0
END

SELECT @language = (SELECT @@language) -- Get system language

SELECT 	@language = 
	CASE 
		WHEN @language = 'Español' THEN 'Spanish'
		ELSE 'us_english'
	END

SELECT @type = type FROM orders (nolock) WHERE order_no = @order_no AND ext = @ext 

-- insert condition
IF( @stat = 'ORDKIT_INS' )
BEGIN	
	IF NOT EXISTS (SELECT * FROM tdc_ord_list_kit (nolock) WHERE order_no = @order_no AND order_ext = @ext AND line_no = @line_no AND kit_part_no = @part)
	BEGIN
		IF (@type = 'C')
		BEGIN
			INSERT INTO tdc_ord_list_kit(order_no,order_ext,part_no,line_no,ordered,picked,location,kit_part_no,sub_kit_part_no,qty_per_kit,kit_picked) 
				SELECT 	@order_no, @ext, l.part_no, @line_no, k.cr_ordered * k.conv_factor, k.cr_shipped * k.conv_factor, l.location, @part, NULL, k.qty_per, 0.0
				  FROM ord_list l (nolock), ord_list_kit k (nolock)
				 WHERE k.order_no = @order_no 
				   AND k.order_ext = @ext 
				   AND k.part_no = @part 
				   AND l.order_no = k.order_no 
				   AND l.order_ext = k.order_ext 
				   AND l.line_no = @line_no 
				   AND k.line_no = @line_no	
		END
		ELSE
		BEGIN
			INSERT INTO tdc_ord_list_kit(order_no,order_ext,part_no,line_no,ordered,picked,location,kit_part_no,sub_kit_part_no,qty_per_kit,kit_picked) 
				SELECT 	@order_no, @ext, l.part_no, @line_no, k.ordered * k.conv_factor, k.shipped * k.conv_factor, l.location, @part, NULL, k.qty_per, 0.0
				  FROM ord_list l (nolock), ord_list_kit k (nolock)
				 WHERE k.order_no = @order_no 
				   AND k.order_ext = @ext 
				   AND k.part_no = @part 
				   AND l.order_no = k.order_no 
				   AND l.order_ext = k.order_ext 
				   AND l.line_no = @line_no 
				   AND k.line_no = @line_no
		END
	END

	RETURN 0
END

-- update condition
IF( @stat = 'ORDKIT_UPD' )
BEGIN
	-- if user change more than one subcomponent I use delete and insert statements to recover it.  Jim X 4-28-00
	DELETE FROM tdc_ord_list_kit
		WHERE order_no = @order_no AND order_ext = @ext AND line_no = @line_no AND kit_picked = 0
		AND ( kit_part_no NOT IN (SELECT part_no FROM ord_list_kit (nolock) WHERE order_no = @order_no AND order_ext = @ext AND line_no = @line_no ) 
		AND sub_kit_part_no NOT IN (SELECT part_no FROM ord_list_kit (nolock) WHERE order_no = @order_no AND order_ext = @ext AND line_no = @line_no ))
		
	SELECT 	@part_no = part_no
		FROM ord_list (nolock)
			WHERE order_no = @order_no AND order_ext = @ext AND line_no = @line_no

	INSERT INTO tdc_ord_list_kit(order_no,order_ext,part_no,line_no,ordered,picked,location,kit_part_no,sub_kit_part_no,qty_per_kit,kit_picked) 
		SELECT 	@order_no, @ext, @part_no, @line_no, ordered * conv_factor, shipped * conv_factor, location, part_no, NULL, qty_per, 0.0
			FROM ord_list_kit (nolock)
				WHERE order_no = @order_no AND order_ext = @ext AND line_no = @line_no	
				AND (part_no NOT IN (SELECT kit_part_no FROM tdc_ord_list_kit (nolock) WHERE order_no = @order_no AND order_ext = @ext AND line_no = @line_no AND sub_kit_part_no IS NULL ) 
				AND part_no NOT IN (SELECT sub_kit_part_no FROM tdc_ord_list_kit (nolock) WHERE order_no = @order_no AND order_ext = @ext AND line_no = @line_no AND sub_kit_part_no IS NOT NULL ) )

	SELECT @kit_part_no = sub_kit_part_no
			FROM tdc_ord_list_kit (nolock)
				WHERE order_no = @order_no AND order_ext = @ext AND line_no = @line_no AND kit_picked > 0 AND sub_kit_part_no IS NULL
				AND kit_part_no NOT IN ( SELECT part_no FROM ord_list_kit (nolock) WHERE order_no = @order_no AND order_ext = @ext AND line_no = @line_no )

	IF (@@ROWCOUNT = 0)
		SELECT @kit_part_no = sub_kit_part_no
			FROM tdc_ord_list_kit (nolock)
				WHERE order_no = @order_no AND order_ext = @ext AND line_no = @line_no AND kit_picked > 0 AND sub_kit_part_no IS NOT NULL
				AND sub_kit_part_no NOT IN ( SELECT part_no FROM ord_list_kit WHERE order_no = @order_no AND order_ext = @ext AND line_no = @line_no )

	IF (@@ROWCOUNT != 0)
	BEGIN 
		IF (@@TRANCOUNT > 0) ROLLBACK TRAN

		-- Error message: Sub component %s had been picked but cannot be found in ADM system!
		SELECT @errmsg = err_msg FROM tdc_lookup_error (nolock) WHERE language = @language AND module = 'SPR' AND trans = 'ORDLISTKIT' AND err_no = -101
		RAISERROR (@errmsg, 16, -1, @kit_part_no)
		RETURN 0
	END	
	

	IF (@type = 'C')
	BEGIN
		SELECT @ordered = cr_ordered * conv_factor, @qty_per = qty_per 
			FROM ord_list_kit (nolock)
				WHERE order_no = @order_no AND order_ext = @ext AND part_no = @part AND line_no = @line_no
	END
	ELSE
	BEGIN 
		SELECT @ordered = ordered * conv_factor, @qty_per = qty_per 
			FROM ord_list_kit (nolock)
				WHERE order_no = @order_no AND order_ext = @ext AND part_no = @part AND line_no = @line_no
	END

	SELECT @tdc_ordered = ordered, @tdc_qty_per = qty_per_kit 
		FROM tdc_ord_list_kit (nolock)
			WHERE order_no = @order_no AND order_ext = @ext AND kit_part_no = @part AND line_no = @line_no AND sub_kit_part_no IS NULL

	IF (@@ROWCOUNT = 0)
		SELECT @tdc_ordered = ordered, @tdc_qty_per = qty_per_kit 
			FROM tdc_ord_list_kit (nolock)
				WHERE order_no = @order_no AND order_ext = @ext AND sub_kit_part_no = @part AND line_no = @line_no

	IF (@tdc_ordered <> @ordered) OR (@tdc_qty_per <> @qty_per)
	BEGIN
		-- all sub components will be commited at once. even though only one sub component got change 
		IF EXISTS (SELECT * FROM tdc_ord_list_kit (nolock) WHERE order_no = @order_no AND order_ext = @ext AND line_no = @line_no AND kit_part_no = @part AND kit_picked > 0 AND sub_kit_part_no IS NULL ) 
		OR EXISTS (SELECT * FROM tdc_ord_list_kit (nolock) WHERE order_no = @order_no AND order_ext = @ext AND line_no = @line_no AND sub_kit_part_no = @part AND kit_picked > 0 )
		BEGIN 
			IF (@@TRANCOUNT > 0) ROLLBACK TRAN

			-- Error message: Cannot update a Sub component %s which has been picked
			SELECT @errmsg = err_msg FROM tdc_lookup_error (nolock) WHERE language = @language AND module = 'SPR' AND trans = 'ORDLISTKIT' AND err_no = -102
			RAISERROR (@errmsg, 16, -1, @part)
			RETURN 0
		END

		IF (@ordered < @tdc_ordered) OR (@tdc_qty_per <> @qty_per)
		BEGIN
			IF EXISTS (SELECT * FROM tdc_soft_alloc_tbl (NOLOCK) WHERE order_no = @order_no AND order_ext = @ext AND line_no = @line_no AND part_no = @part AND order_type = 'S')
		        AND       (SELECT active FROM tdc_config (NOLOCK) WHERE [function] = 'so_auto_allocate') != 'Y' 
			BEGIN
				IF (@@TRANCOUNT > 0) ROLLBACK TRAN

				-- 'Must unallocate inventory  before changing order quantity'
				SELECT @errmsg = err_msg FROM tdc_lookup_error (nolock) WHERE language = @language AND module = 'SPR' AND trans = 'ORDLISTKIT' AND err_no = -103
				RAISERROR (@errmsg, 16, -1)
				RETURN 0
			END
		END
	END

	IF EXISTS ( SELECT * FROM tdc_ord_list_kit (nolock) WHERE order_no = @order_no AND order_ext = @ext AND line_no = @line_no AND kit_part_no = @part AND sub_kit_part_no IS NULL)
		UPDATE tdc_ord_list_kit 
			SET ordered = @ordered, qty_per_kit = @qty_per
				WHERE order_no = @order_no AND order_ext = @ext AND line_no = @line_no AND kit_part_no = @part
	RETURN 0
END

-- delete condition
IF( @stat = 'ORDKIT_DEL' )
BEGIN
	IF EXISTS (SELECT * FROM tdc_ord_list_kit (nolock) WHERE order_no = @order_no AND order_ext = @ext AND line_no = @line_no AND kit_part_no = @part AND kit_picked > 0 AND sub_kit_part_no IS NULL ) 
	OR EXISTS (SELECT * FROM tdc_ord_list_kit (nolock) WHERE order_no = @order_no AND order_ext = @ext AND line_no = @line_no AND sub_kit_part_no = @part AND kit_picked > 0 )
	BEGIN 
		IF (@@TRANCOUNT > 0) ROLLBACK TRAN

		-- Error message: Cannot delete a Sub component %s which has been picked
		SELECT @errmsg = err_msg FROM tdc_lookup_error (nolock) WHERE language = @language AND module = 'SPR' AND trans = 'ORDLISTKIT' AND err_no = -104
		RAISERROR (@errmsg, 16, -1, @part)
		RETURN 0
	END

	IF EXISTS (SELECT * FROM tdc_soft_alloc_tbl (NOLOCK) WHERE order_no = @order_no AND order_ext = @ext AND line_no = @line_no AND part_no = @part AND order_type = 'S')
        AND       (SELECT active FROM tdc_config (NOLOCK) WHERE [function] = 'so_auto_allocate') != 'Y' 
	BEGIN
		IF (@@TRANCOUNT > 0) ROLLBACK TRAN

		-- Error message: Must unallocate inventory before delete item %s.		
		SELECT @errmsg = err_msg FROM tdc_lookup_error (nolock) WHERE language = @language AND module = 'SPR' AND trans = 'ORDLISTKIT' AND err_no = -105
		RAISERROR(@errmsg, 16, -1, @part)
		RETURN 0
	END

	-- if sub_kit_part_no is not null we delete this record from our console app every time its quantity become zero
	DELETE FROM tdc_ord_list_kit WHERE order_no = @order_no AND order_ext = @ext AND line_no = @line_no AND kit_part_no = @part AND sub_kit_part_no IS NULL
END

RETURN 0

GO
GRANT EXECUTE ON  [dbo].[tdc_ord_list_kit_change] TO [public]
GO
