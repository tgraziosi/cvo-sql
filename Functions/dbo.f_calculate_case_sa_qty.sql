SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- v1.0 CT 09/01/2013 - Calculates the qty of a case after a linked frame has changed
-- v1.1 CB 23/01/2013 - Re-Written 
-- v1.2 CB 19/03/2013 - Fix issue when case is deleted but still exists on order
-- v1.3 CB 21/03/2013 - Now include case adjust column - for manual case line adjustments
-- v1.4 CB 23/04/2013 - Deal with possible nulls
-- v1.5 CB 18/06/2013 - Issue when duplicating a partially allocated order
-- v1.6 CB 04/07/2013 - Issue #1325 - Keep soft alloc number
-- v1.7 CB 21/03/2014 - Fix issue when deleting a frame line that is allocated
-- v1.8 CB 20/01/2015 - Fix issue when change order with partial allocated frame

-- SELECT dbo.f_calculate_case_sa_qty (1419312,0,654,'CHZCASS')
CREATE FUNCTION [dbo].[f_calculate_case_sa_qty] (	@order_no INT,
												@order_ext INT,
												@soft_alloc_no INT,
												@case_part VARCHAR(30),
												@part_no VARCHAR (30),
												@line_no INT,
												@orig_part_qty DECIMAL(20,8),									
												@quantity DECIMAL(20,8))
RETURNS DECIMAL(20,8)
AS
BEGIN

	DECLARE @original_part_qty		DECIMAL(20,8),
			@original_part_sa_qty	DECIMAL(20,8),
			@original_case_qty		DECIMAL(20,8),
			@original_case_sa_qty	DECIMAL(20,8),
			@original_case_sa_del_qty DECIMAL(20,8), -- v1.2
			@qty					DECIMAL(20,8),
			@alloc_case_qty			DECIMAL(20,8),
			@change_case_sa_qty		DECIMAL(20,8),
			@case_adjust			DECIMAL(20,8) -- v1.3

	-- Create working table
	DECLARE @temp TABLE (
			line_no		int,
			part_no		varchar(30),
			sa_qty		decimal(20,8),
			alloc_qty	decimal(20,8),
			changed		int)

	IF (@order_no = 0) -- Not Saved
	BEGIN
		SELECT	@alloc_case_qty = SUM(a.quantity) 
		FROM	cvo_soft_alloc_det a (NOLOCK)
		JOIN	inv_master_add b (NOLOCK)
		ON		a.part_no = b.part_no
		WHERE	a.soft_alloc_no = @soft_alloc_no
		AND		b.field_1 = @case_part
		AND		ISNULL(a.add_case_flag,'N') = 'Y'

		-- v1.3 Start
		SELECT	@case_adjust = SUM(case_adjust)
		FROM	cvo_soft_alloc_det (NOLOCK)
		WHERE	soft_alloc_no = @soft_alloc_no
		AND		part_no = @case_part

		IF (@line_no = -99)
			SET @case_adjust = 0

		SET @qty = @alloc_case_qty + ISNULL(@case_adjust,0)
		-- v1.3 End

	END
	ELSE
	BEGIN
		IF NOT EXISTS ( SELECT 1 FROM tdc_soft_alloc_tbl (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext AND part_no = @case_part) OR (@line_no = -99) -- Save but not allocated v1.5 OR -99
		BEGIN

			SELECT	@alloc_case_qty = SUM(a.quantity) 
			FROM	cvo_soft_alloc_det a (NOLOCK)
			JOIN	inv_master_add b (NOLOCK)
			ON		a.part_no = b.part_no
			WHERE	a.soft_alloc_no = @soft_alloc_no
			AND		b.field_1 = @case_part
			AND		ISNULL(a.add_case_flag,'N') = 'Y'

			-- v1.3 Start
			SELECT	@case_adjust = SUM(case_adjust)
			FROM	cvo_soft_alloc_det (NOLOCK)
			WHERE	soft_alloc_no = @soft_alloc_no
			AND		part_no = @case_part


			IF (@line_no = -99)
				SET @case_adjust = 0

			SET @qty = @alloc_case_qty -- v1.8+ ISNULL(@case_adjust,0)
			-- v1.3 End
		END
		ELSE
		BEGIN -- Has been allocated

			-- Get allocated quantities
			INSERT	@temp
			SELECT	a.line_no, a.part_no, 0, a.qty, 0
			FROM	tdc_soft_alloc_tbl a (NOLOCK)
			JOIN	inv_master_add b (NOLOCK)
			ON		a.part_no = b.part_no
			WHERE	a.order_no = @order_no
			AND		a.order_ext = @order_ext
			AND		b.field_1 = @case_part

			-- v1.7 Start
			UPDATE	a
			SET		changed = 1
			FROM	@temp a 
			JOIN	cvo_soft_alloc_det b (NOLOCK)
			ON		a.line_no = b.line_no
			WHERE	b.soft_alloc_no = @soft_alloc_no
			AND		b.order_no = @order_no
			AND		b.order_ext = @order_ext
			-- v1.7 End

			-- Get soft allocation quantities
			INSERT	@temp
			SELECT	a.line_no, a.part_no, CASE WHEN a.deleted = 1 THEN a.quantity * -1 ELSE a.quantity END, 0, change
			FROM	cvo_soft_alloc_det a (NOLOCK)
			JOIN	inv_master_add b (NOLOCK)
			ON		a.part_no = b.part_no
			WHERE	a.soft_alloc_no = @soft_alloc_no
			AND		b.field_1 = @case_part
			AND		ISNULL(a.add_case_flag,'N') = 'Y'

			-- If the allocated line has been changed then use the soft alloc quantity
			UPDATE	@temp
			SET		alloc_qty = 0
			WHERE	line_no IN (SELECT line_no FROM @temp WHERE changed <> 0)

			UPDATE	@temp
			SET		sa_qty = 0
			WHERE	line_no IN (SELECT line_no FROM @temp WHERE sa_qty < 0)

			-- v1.3 Start
			SELECT	@case_adjust = SUM(case_adjust)
			FROM	cvo_soft_alloc_det (NOLOCK)
			WHERE	soft_alloc_no = @soft_alloc_no
			AND		part_no = @case_part
		
			SELECT @alloc_case_qty = SUM(sa_qty + alloc_qty) FROM @temp

			IF (@line_no = -99)
				SET @case_adjust = 0

			SET @qty = @alloc_case_qty -- v1.6 + ISNULL(@case_adjust,0)
			-- v1.3 End


		END

	END


RETURN @qty


END

GO
GRANT REFERENCES ON  [dbo].[f_calculate_case_sa_qty] TO [public]
GO
GRANT EXECUTE ON  [dbo].[f_calculate_case_sa_qty] TO [public]
GO
