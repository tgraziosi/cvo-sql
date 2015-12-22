SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_set_xfer_status]  @no int, @status char(2)  
AS

DECLARE @temp_stat int,
		@tdc_stat int,  
		@tdc_status char(2)

SELECT @temp_stat = 0
SELECT @tdc_stat  = 0

SELECT @temp_stat = CASE 
			WHEN @status = 'Q1' THEN 100
			WHEN @status = 'O1' THEN 200
--			WHEN @status = 'P1' THEN 300
--			WHEN @status = 'N1' THEN 400
--			WHEN @status = 'M1' THEN 500
--			WHEN @status = 'S1' THEN 600
			WHEN @status = 'V1' THEN 700
			WHEN @status = 'E1' THEN 800
			WHEN @status = 'R1' THEN 900
		END

SELECT @tdc_status = (SELECT TDC_status FROM TDC_xfers 
					WHERE xfer_no = @no)

SELECT @tdc_stat  = CASE 
			WHEN @tdc_status = 'Q1' THEN 100
			WHEN @tdc_status = 'O1' THEN 200
--			WHEN @tdc_status = 'P1' THEN 300
--			WHEN @tdc_status = 'N1' THEN 400
--			WHEN @tdc_status = 'M1' THEN 500
--			WHEN @tdc_status = 'S1' THEN 600
			WHEN @tdc_status = 'V1' THEN 700
			WHEN @tdc_status = 'E1' THEN 800
			WHEN @tdc_status = 'R1' THEN 900
		END

IF ((@status = 'P1') OR (@status = 'N1') OR (@status = 'M1') OR (@status = 'S1'))
BEGIN
	UPDATE TDC_order
	SET tdc_status = @status
	WHERE order_no = @no 
END
ELSE
IF ((@temp_stat > @tdc_stat) OR (@tdc_status = 'XX') OR (@tdc_status = NULL))
BEGIN
	UPDATE TDC_xfers
	SET tdc_status = @status
	WHERE xfer_no = @no 
END
GO
GRANT EXECUTE ON  [dbo].[tdc_set_xfer_status] TO [public]
GO
