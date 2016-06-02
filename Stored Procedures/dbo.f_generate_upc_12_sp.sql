SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- v1.0 CB 11/02/2016 - Issue #1574 - Outsourcing
/*
DECLARE @next_num varchar(12)
EXEC dbo.f_generate_upc_12_sp @next_num OUTPUT
SELECT @next_num
*/

CREATE PROC [dbo].[f_generate_upc_12_sp] @next_upc varchar(12) OUTPUT
AS
BEGIN
	DECLARE @size_id	int,
			@next_no	int,
			@size_no	int,
			@mask		varchar(12),
			@size		int,
			@next_num	varchar(12),
			@factor		int,
			@weightedtotal int,
			@count		int,
			@currentnum int,
			@result		int,
			@checkdigit int

	SELECT 	@mask = value_str FROM config (NOLOCK) WHERE flag = 'ID_CVO_MASK'

	SET @size_id = LEN(@mask)

	UPDATE dbo.next_upc12 SET last_no =last_no + 1 
	SELECT @next_no = last_no FROM dbo.next_upc12 

	SET @size_no = LEN(CAST(@next_no as varchar(12)))

	SET @size = 11 - @size_id - @size_no

	SET @next_num = REPLICATE('0',@size) + CAST(@next_no as varchar(12))

	SET @next_num = @mask + @next_num

	SET @factor = 3
	SET @weightedtotal = 0
	SET @count = 11

	WHILE (@count > 0)
	BEGIN
		SET @currentnum = CAST(SUBSTRING(@next_num, @count,1) as int)
		SET @weightedtotal = @weightedtotal + (@currentnum * @factor)
		SET @factor = 4 - @factor
		SET @count = @count - 1
	END

	SET @result = @weightedtotal % 10 

	IF (@result <> 0)
		SET @checkdigit = 10 - @result
	ELSE
		SET @checkdigit = 0

	SET @next_num = @next_num + CAST(@checkdigit as char(1))

	SET @next_upc = ISNULL(@next_num,'')

END
GO
GRANT EXECUTE ON  [dbo].[f_generate_upc_12_sp] TO [public]
GO
