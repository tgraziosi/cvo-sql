SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_search_order_no]
AS
	SET NOCOUNT ON
	
	/* Variables declaration */
	DECLARE @err			int,
	 	@parent				int,
		@temporary_parent 	int,
		@order_no			int,
		@order_ext			int,
		@status				char(1)



	/* Create temporary tables */
	CREATE TABLE #parent_temp (parent_serial_no INT NOT NULL)
	CREATE TABLE #child_temp (child_serial_no INT NOT NULL)
	CREATE TABLE #root_children (child_serial_no INT NOT NULL)



	/* Start with clean tables */
	TRUNCATE TABLE #parent_temp
	TRUNCATE TABLE #child_temp
	TRUNCATE TABLE #root_children



	/* Initialize variables */
	SELECT 	@err = 0
	SELECT 	@parent = (SELECT parent_serial_no FROM #dist_un_verify)

	INSERT INTO #parent_temp(parent_serial_no) VALUES(@parent)

	BEGIN TRAN
	
	WHILE EXISTS (SELECT * FROM #parent_temp)
	BEGIN
		DECLARE parent_cursor CURSOR FOR
			SELECT parent_serial_no FROM #parent_temp

		OPEN parent_cursor
		
		FETCH NEXT FROM parent_cursor INTO @temporary_parent

		WHILE (@@FETCH_STATUS <> -1)
		BEGIN
			IF (@@FETCH_STATUS <> -2)
			BEGIN
				IF EXISTS (SELECT * FROM tdc_dist_item_pick WHERE child_serial_no = @temporary_parent
															AND [function] = 'S')
				BEGIN
					INSERT INTO #root_children (child_serial_no) VALUES(@temporary_parent)

					SELECT @order_no = (SELECT DISTINCT order_no FROM tdc_dist_item_pick p, #root_children r 
																	WHERE p.child_serial_no = r.child_serial_no	
																	AND p.[function] = 'S')	
			
					SELECT @order_ext = (SELECT MAX(order_ext) FROM tdc_dist_item_pick p, #root_children r 
																WHERE p.child_serial_no = r.child_serial_no	
																AND p.[function] = 'S')	

					SELECT @status = (SELECT DISTINCT status FROM orders WHERE order_no = @order_no AND ext = @order_ext)
					IF @status = 'R'
					BEGIN
						ROLLBACK TRAN
						DEALLOCATE parent_cursor
						SELECT @err = -101
						RETURN @err
					END

--					IF EXISTS (SELECT * FROM tdc_order WHERE order_no = @order_no AND order_ext = @order_ext AND tdc_status = 'R1')
--					BEGIN
--						ROLLBACK TRAN
--						DEALLOCATE parent_cursor
--						SELECT @err = -101
--						RETURN @err
--					END
				END

				INSERT INTO #child_temp (child_serial_no)
					SELECT child_serial_no 
					FROM tdc_dist_group 
					WHERE parent_serial_no = @temporary_parent AND [function] = 'S'
			END

			FETCH NEXT FROM parent_cursor INTO @temporary_parent
		END

		TRUNCATE TABLE #parent_temp
		
		INSERT INTO #parent_temp (parent_serial_no)
			SELECT child_serial_no 
			FROM #child_temp

		TRUNCATE TABLE #child_temp

		TRUNCATE TABLE #root_children

		DEALLOCATE parent_cursor
	END
	
	COMMIT TRAN

RETURN @err
GO
GRANT EXECUTE ON  [dbo].[tdc_search_order_no] TO [public]
GO
