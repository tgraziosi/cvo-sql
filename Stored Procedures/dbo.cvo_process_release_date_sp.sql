SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- EXEC dbo.cvo_process_release_date_sp 2336289, 0
CREATE PROC [dbo].[cvo_process_release_date_sp] @order_no	int,
											@order_ext int
AS
BEGIN
	-- DIRECTIVES
	SET NOCOUNT ON

	-- DECLARATIONS
	DECLARE	@status			varchar(8),
			@hold_reason	varchar(30)
	-- Working Tables
	CREATE TABLE #release_date (
		row_id			int IDENTITY(1,1),
		order_no		int,
		order_ext		int,
		part_no			varchar(30),
		release_date	varchar(10) NULL,
		released_flag	int)

	-- Insert working data
	INSERT	#release_date (order_no, order_ext, part_no, released_flag)
	SELECT	order_no, order_ext, part_no, 1
	FROM	dbo.ord_list (NOLOCK)
	WHERE	order_no = @order_no
	AND		order_ext = @order_ext

	INSERT	#release_date (order_no, order_ext, part_no, released_flag)
	SELECT	order_no, order_ext, part_no, 1
	FROM	dbo.ord_list_kit (NOLOCK)
	WHERE	order_no = @order_no
	AND		order_ext = @order_ext

	-- Update the working table with the recorded release dates from inventory
	UPDATE	a
	SET		release_date = CONVERT(varchar(10),ISNULL(b.field_26,'1900-01-01'),121)
	FROM	#release_date a
	JOIN	inv_master_add b (NOLOCK)
	ON		a.part_no = b.part_no
	
	-- Mark any records that have not been released
	UPDATE	#release_date
	SET		released_flag = 0
	WHERE	release_date > CONVERT(varchar(10),GETDATE(),121)

	-- select * from #release_date

	-- Check for any unreleased records
	IF EXISTS (SELECT 1 FROM #release_date WHERE released_flag = 0)
	BEGIN

		SELECT	@status = status,
				@hold_reason = hold_reason
		FROM	orders_all (NOLOCK)
		WHERE	order_no = @order_no
		AND		ext = @order_ext

		IF (@status = 'A') 
		BEGIN
			IF (@hold_reason <> 'RD' )
			BEGIN
				UPDATE	cvo_orders_all WITH (ROWLOCK)
				SET		prior_hold = 'RD'
				WHERE	order_no = @order_no
				AND		ext = @order_ext
			END
			SELECT 0
			RETURN -1
		END

			IF (@status IN ('C','H','B'))
			BEGIN
				UPDATE	cvo_orders_all WITH (ROWLOCK)
				SET		prior_hold = 'RD'
				WHERE	order_no = @order_no
				AND		ext = @order_ext

				SELECT 0
				RETURN -1
			END

			IF (@status = 'N')					
			BEGIN
				UPDATE	orders_all WITH (ROWLOCK)
				SET		status = 'A',
						hold_reason = 'RD'
				WHERE	order_no = @order_no
				AND		ext = @order_ext

				SELECT -1
				RETURN -1
			END
	END
	ELSE
	BEGIN

		UPDATE	orders_all WITH (ROWLOCK)
		SET		status = 'N',
				hold_reason = ''
		WHERE	order_no = @order_no
		AND		ext = @order_ext
		AND		hold_reason = 'RD'

		UPDATE	cvo_orders_all WITH (ROWLOCK)
		SET		prior_hold = ''
		WHERE	order_no = @order_no
		AND		ext = @order_ext
		AND		prior_hold = 'RD'

		SELECT 0
		RETURN 0
	END
END
GO
GRANT EXECUTE ON  [dbo].[cvo_process_release_date_sp] TO [public]
GO
