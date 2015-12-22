SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[fs_atpweeks_sp] 
			@part_no   VARCHAR(30),
			@location  VARCHAR(10),
			@base_date datetime
			
AS
	DECLARE @week_counter 	int, 
		@begin_date	datetime, 
		@end_date 	datetime,
		@stock_in 	float, 
		@stock_out 	float,
		@balance 	float,
		@balanced_stock_in float,
		@first_run	smallint,
		@in_stock	float,
		@out_part       varchar(30),
		@out_location   varchar(10),
		@lead_time	int

	CREATE TABLE #proyection
	(
		week_no		int,
		end_date	datetime,
		in_stock	decimal(20,8),
		stock_in	decimal(20,8),
		stock_out	decimal(20,8),
		balance		decimal(20,8),
		type		char(1),
		tran_no		varchar(16),
		ext		int
	)

	create index #p1 on #proyection(end_date)

	SELECT  @week_counter = 1,
		@begin_date = @base_date,
		@end_date = @base_date + 182,
		@balanced_stock_in = 0,
		@first_run = 1

	select @out_part = part_no, @out_location = location,
         @lead_time = lead_time
        from inv_list (nolock) where part_no = @part_no and location = @location

	insert #proyection
	EXEC fs_weekly_activity_sp @location, @part_no, @begin_date, @end_date, @in_stock OUTPUT, 
	@stock_in OUTPUT, @stock_out OUTPUT, @balance OUTPUT, @balanced_stock_in, @first_run

	select @end_date = @base_date + 7
	WHILE @end_date <= @base_date + 182
	BEGIN
	  update #proyection
	  set week_no = @week_counter
	  where end_date <= @end_date and week_no = 0

	  select @stock_in = 0, @stock_out = 0
	  select @stock_in = sum(stock_in),
	  @stock_out = sum(stock_out)
	  from #proyection where week_no = @week_counter

	  select @balance = @in_stock + isnull(@stock_in,0) - isnull(@stock_out,0)

	  insert #proyection
	  select @week_counter, @end_date, @in_stock, isnull(@stock_in,0), 
	  isnull(@stock_out,0), @balance, 'B',0,0

	  SELECT @begin_date = @end_date,
		@end_date = @end_date + 7,
		@week_counter = @week_counter + 1,
		@balanced_stock_in = @balance,
		@first_run = 0,
		@in_stock = @balance
	END

	SELECT week_no, 
		end_date, 
		in_stock,
		stock_in, 
		stock_out, 
		balance,
		type, tran_no, ext, 	
		@out_part, @out_location, @base_date, @lead_time
	FROM #proyection
	order by week_no, type, tran_no, ext

	DROP TABLE #proyection
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[fs_atpweeks_sp] TO [public]
GO
