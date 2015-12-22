SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE FUNCTION [dbo].[CalcChkDigitGTIN12](@input CHAR(11))
RETURNS INT
AS
BEGIN
DECLARE @evenDigitSum INT 
,@oddDigitSum INT 
,@i TINYINT 
,@result INT;
 
 select @i = 0, @odddigitsum = 0, @evendigitsum = 0

-- check if given Barcode is Numeric , if not return error status -1
IF(ISNUMERIC(@input) = 0
OR LEN(RTRIM(LTRIM(@input))) != 11)
RETURN -1
 
-- start the compute BarCode checksum algorithm
SET @i = 1
WHILE (@i <= 11)
BEGIN
--Add odd and even digits separately;
IF((@i % 2) = 0)
SET @evenDigitSum = @evendigitsum + CONVERT(TINYINT, SUBSTRING(@input,@i,1))
ELSE
SET @oddDigitSum = @odddigitsum + CONVERT(TINYINT, SUBSTRING(@input,@i,1))
SET @i = @i+1
END
 
--As per: http://en.wikipedia.org/wiki/Universal_Product_Code
--Multiply odd sum by 3, add to even sum, and mod 10.
SET @result = ((@oddDigitSum * 3) + @evenDigitSum) % 10;
IF(@result = 0)
RETURN 0
ELSE
RETURN 10 - @result;
 
RETURN -1
END
GO
