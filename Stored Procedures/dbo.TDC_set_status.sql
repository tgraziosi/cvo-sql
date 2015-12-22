SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[TDC_set_status]  @no int, @ext int, @status char(2) AS

DECLARE @temp_stat int,
	@tdc_stat int,  
	@tdc_status char(2)

SELECT @temp_stat = 0
SELECT @tdc_stat  = 0

SELECT @temp_stat = CASE WHEN @status = 'Q1' THEN 100
			 WHEN @status = 'O1' THEN 200
			 WHEN @status = 'P1' THEN 300
			 WHEN @status = 'N1' THEN 400
			 WHEN @status = 'M1' THEN 500
			 WHEN @status = 'S1' THEN 600
			 WHEN @status = 'V1' THEN 700
			 WHEN @status = 'E1' THEN 800
			 WHEN @status = 'R1' THEN 900
			 WHEN @status = 'V2' THEN 1000
			 WHEN @status = 'V3' THEN 1100
		    END

SELECT @tdc_status = (SELECT TDC_status FROM TDC_order 
					WHERE Order_no = @no AND order_ext = @ext)

SELECT @tdc_stat  = CASE WHEN @tdc_status = 'Q1' THEN 100
			 WHEN @tdc_status = 'O1' THEN 200
			 WHEN @tdc_status = 'P1' THEN 300
			 WHEN @tdc_status = 'N1' THEN 400
			 WHEN @tdc_status = 'M1' THEN 500
			 WHEN @tdc_status = 'S1' THEN 600
			 WHEN @tdc_status = 'V1' THEN 700
			 WHEN @tdc_status = 'E1' THEN 800
			 WHEN @tdc_status = 'R1' THEN 900
			 WHEN @tdc_status = 'V2' THEN 1000
			 WHEN @tdc_status = 'V3' THEN 1100
		    END


IF (@temp_stat > @tdc_stat or @tdc_status = 'XX' or @tdc_status = NULL)
BEGIN
	UPDATE TDC_order
	SET tdc_status = @status
	WHERE order_no = @no and order_ext = @ext
END
GO
GRANT EXECUTE ON  [dbo].[TDC_set_status] TO [public]
GO
