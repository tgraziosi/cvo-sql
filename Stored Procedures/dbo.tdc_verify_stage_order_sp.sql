SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_verify_stage_order_sp] (@order_no int, @order_ext int)
AS

	DECLARE @tord		int
	DECLARE @text		int
	DECLARE @tpart 		varchar(30)
	DECLARE @tline		int
	DECLARE @tpicked	decimal(20, 8)
	DECLARE @tpacked	decimal(20, 8)
	DECLARE @err 		int

	SELECT @err = 1

	DECLARE pass1_cursor INSENSITIVE CURSOR FOR 
	 SELECT ol.order_no, ol.order_ext, ol.line_no, ol.part_no, ol.shipped
           FROM ord_list ol
          WHERE ol.order_no = @order_no
            AND ol.order_ext = @order_ext
          ORDER BY ol.line_no

	-- Get picked/shipped quantities from ord_list table.
	OPEN pass1_cursor
	FETCH NEXT FROM pass1_cursor INTO @tord, @text, @tline, @tpart, @tpicked


	WHILE (@@FETCH_STATUS = 0)
	BEGIN

		-- Now compare against what has been packed (and staged).
		SELECT @tpacked = isnull(sum(pack_qty), 0)
		  FROM tdc_carton_detail_tx
		 WHERE order_no = @tord
		   AND order_ext = @text
		   AND line_no = @tline
		   AND status = 'S'

		IF (@tpacked < @tpicked)
		  BEGIN
		    SELECT @err = 0	-- Not all picked items have been packed 
					-- for this part.
		  END

		FETCH NEXT FROM pass1_cursor INTO @tord, @text, @tline, @tpart, @tpicked
	END

	CLOSE pass1_cursor
	DEALLOCATE pass1_cursor


RETURN @err
GO
GRANT EXECUTE ON  [dbo].[tdc_verify_stage_order_sp] TO [public]
GO
