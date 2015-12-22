SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_get_order_hdr_status]
	@order_no integer,
	@ext integer,
	@msg varchar(100) OUTPUT 
AS

SELECT @msg = ''

--Call 799080BRK
DECLARE @status CHAR(1)
SELECT @status = status FROM orders (nolock) WHERE order_no = @order_no AND ext = @ext

DECLARE @language VARCHAR(20)

SELECT @language = @@language -- Get system language

SELECT 	@language = 
	CASE 
		WHEN @language = 'Español' THEN 'Spanish'
		ELSE 'us_english'
	END

/*****************************************************************************************/

IF (@status <> 'M')
BEGIN
	/* TDC does not have control to this order	*/
	IF ((SELECT SUM(shipped) FROM ord_list (nolock) WHERE order_no = @order_no AND order_ext = @ext) > 0)
		IF NOT EXISTS (SELECT * FROM tdc_dist_item_pick (nolock) WHERE order_no = @order_no AND order_ext = @ext AND [function] = 'S')
			--IF NOT EXISTS (SELECT * FROM tdc_bkp_dist_item_pick (nolock) WHERE order_no = @order_no AND order_ext = @ext AND [function] = 'S')
			BEGIN
				SELECT @msg = 'Order not found in Supply Chain Execution system'
				RETURN 0
			END

	IF NOT EXISTS (SELECT * FROM tdc_order (nolock) WHERE order_no = @order_no AND order_ext = @ext)
	BEGIN
		SELECT @msg = 'Order not found in Supply Chain Execution system'
		RETURN 0
	END

	IF NOT EXISTS (SELECT * FROM tdc_dist_item_list (nolock) WHERE order_no = @order_no AND order_ext = @ext AND [function] = 'S')
	BEGIN
		--IF NOT EXISTS (SELECT * FROM tdc_bkp_dist_item_list (nolock) WHERE order_no = @order_no AND order_ext = @ext AND [function] = 'S')
		--BEGIN
			SELECT @msg = 'Order not found in Supply Chain Execution system'
			RETURN 0
		--END
	END
END

/*****************************************************************************************/

DECLARE @ordered decimal(20,8), @shipped decimal(20,8), @b_ordered decimal(20,8), @b_shipped decimal(20,8)
DECLARE @ordered_tot decimal(20,8), @shipped_tot decimal(20,8)
DECLARE @percent int, @consolidation_no varchar(10)

SELECT @ordered_tot = 0.0, @shipped_tot = 0.0
SELECT @b_ordered = 0.0, @b_shipped = 0.0

IF (@status = 'M')
BEGIN
	IF NOT EXISTS (SELECT * FROM tdc_order (nolock) WHERE order_no = @order_no AND order_ext <> 0) 
	BEGIN
		SELECT @msg = 'Order not found in Supply Chain Execution system'
		RETURN 0
	END

	SELECT @ordered_tot = SUM(ordered) FROM ord_list (nolock) WHERE order_no = @order_no AND order_ext <> 0

	DECLARE get_blanket CURSOR FOR 
		SELECT ordered, shipped 
		  FROM ord_list (nolock)
		 WHERE order_no = @order_no AND order_ext <> 0 AND shipped > 0
		FOR READ ONLY

	OPEN get_blanket
	FETCH get_blanket INTO @b_ordered, @b_shipped

	WHILE @@FETCH_STATUS = 0
	BEGIN
		IF (@b_shipped > @b_ordered)
			SELECT @b_shipped = @b_ordered

		SELECT @shipped_tot = @shipped_tot + @b_shipped

		FETCH get_blanket INTO @b_ordered, @b_shipped
	END

	CLOSE get_blanket
	DEALLOCATE get_blanket

	IF (ROUND(@ordered_tot,0) <> 0) 
		SELECT @percent = (ROUND(@shipped_tot,0) / ROUND(@ordered_tot,0)) * 100
	ELSE
		SELECT @percent = 0

	/* order has not been picked */
	IF (SELECT SUM(shipped) FROM ord_list (nolock) WHERE order_no = @order_no AND order_ext <> 0) = 0
	BEGIN
		SELECT @consolidation_no = ISNULL((SELECT LTRIM(RTRIM(CONVERT(varchar(10), MAX(consolidation_no)))) 
						     FROM tdc_cons_ords (nolock) 
						    WHERE order_no = @order_no AND order_ext = @ext AND order_type = 'S'), 'NA')

		SELECT @msg = 'Completed: 0%. Consolidation number: ' + @consolidation_no + '.'
		RETURN 0
	END

	SELECT @consolidation_no = ISNULL((SELECT LTRIM(RTRIM(CONVERT(varchar(10), MAX(consolidation_no)))) 
					     FROM tdc_cons_ords (nolock) 
					    WHERE order_no = @order_no AND order_ext = @ext AND order_type = 'S'), 'NA')

	SELECT @msg = 'Completed: ' + LTRIM(RTRIM(CONVERT(varchar(5), @percent))) + '%.' + ' Consolidation number: ' + @consolidation_no + '.'
END
ELSE
BEGIN
-- 	DECLARE get_qty CURSOR FOR 
-- 		SELECT ordered, shipped 
-- 		  FROM ord_list 
-- 		 WHERE order_no = @order_no AND order_ext = @ext
-- 		FOR READ ONLY
-- 
-- 	OPEN get_qty
-- 	FETCH get_qty INTO @ordered, @shipped
-- 
-- 	WHILE @@FETCH_STATUS = 0
-- 	BEGIN
-- 		IF (@shipped > @ordered)
-- 			SELECT @shipped = @ordered
-- 
-- 		SELECT @ordered_tot = @ordered_tot + @ordered 
-- 		SELECT @shipped_tot = @shipped_tot + @shipped
-- 
-- 		FETCH get_qty INTO @ordered, @shipped
-- 	END
-- 
-- 	CLOSE get_qty
-- 	DEALLOCATE get_qty

	SELECT @ordered_tot = sum(ordered), @shipped_tot = sum(shipped)
	  FROM ord_list (nolock)
	 WHERE order_no = @order_no AND order_ext = @ext AND shipped > 0 AND ordered >= shipped

--	Call 1515891ESC  04/02/08	
	IF EXISTS (SELECT *
	  			 FROM ord_list (nolock)
	 			WHERE order_no = @order_no AND order_ext = @ext AND ordered < shipped )--overpick
	BEGIN
		SELECT @ordered_tot = @ordered_tot + sum(shipped), @shipped_tot = @shipped_tot + sum(shipped)
	  	  FROM ord_list (nolock)
		 WHERE order_no = @order_no AND order_ext = @ext AND ordered < shipped --overpick
	END
--	Call 1515891ESC  04/02/08

	IF (ROUND(@ordered_tot,0) <> 0)
		SELECT @percent = (ROUND(@shipped_tot,0) / ROUND(@ordered_tot,0)) * 100
	ELSE
		SELECT @percent = 0

	/* order has been shipped */
	IF EXISTS (SELECT * FROM orders (nolock) WHERE order_no = @order_no AND ext = @ext 
									AND status IN ('R', 'S', 'T'))
	BEGIN
		SELECT @consolidation_no = ISNULL((SELECT LTRIM(RTRIM(CONVERT(varchar(10), MAX(consolidation_no))))
						     FROM tdc_cons_ords_arch (nolock) 
						    WHERE order_no = @order_no AND order_ext = @ext AND order_type = 'S'), 'NA')

		SELECT @msg = 'Order has been shipped. Completed: ' + LTRIM(RTRIM(CONVERT(varchar(5), @percent))) + '%.' + ' Consolidation number: ' + @consolidation_no + '.'
		RETURN 0
	END

	/* order has not been picked */
	IF (SELECT SUM(shipped) FROM ord_list (nolock) WHERE order_no = @order_no AND order_ext = @ext) <= 0
	BEGIN
		SELECT @consolidation_no = ISNULL((SELECT LTRIM(RTRIM(CONVERT(varchar(10), MAX(consolidation_no)))) 
						     FROM tdc_cons_ords (nolock) 
						    WHERE order_no = @order_no AND order_ext = @ext AND order_type = 'S'), 'NA')

		SELECT @msg = 'Completed: 0%. Consolidation number: ' + @consolidation_no + '.'
		RETURN 0
	END

		SELECT @consolidation_no = ISNULL((SELECT LTRIM(RTRIM(CONVERT(varchar(10), MAX(consolidation_no)))) 
						     FROM tdc_cons_ords (nolock) 
						    WHERE order_no = @order_no AND order_ext = @ext AND order_type = 'S'), 'NA')

		SELECT @msg = 'Order Currently being Processed. Completed: ' + LTRIM(RTRIM(CONVERT(varchar(5), @percent))) + '%.' + ' Consolidation number: ' + @consolidation_no + '.'
END

/*****************************************************************************************/

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[tdc_get_order_hdr_status] TO [public]
GO
