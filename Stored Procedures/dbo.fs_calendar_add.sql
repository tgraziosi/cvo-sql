SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


--  Copyright (c) 1997 Epicor Software, Inc. All Right Reserved.
CREATE PROCEDURE [dbo].[fs_calendar_add]
	(
	@calendar_id		INT,
	@delta_time		FLOAT,
	@beg_datetime		DATETIME,
	@end_datetime		DATETIME OUT
	)

AS
BEGIN
DECLARE	@beg_date	DATETIME,
	@end_date	DATETIME

CREATE TABLE #calendar
	(
	work_date	DATETIME,
	beg_datetime	DATETIME,
	end_datetime	DATETIME
	)


SELECT	@beg_date = datename(year,@beg_datetime)+'-'+datename(month,@beg_datetime)+'-'+datename(day,@beg_datetime)
SELECT	@end_date = dateadd(day,-1,@beg_date),
	@end_date = dateadd(year,1,@beg_date)
INSERT	#calendar(work_date,beg_datetime,end_datetime)
EXECUTE	fs_build_calendar @build_mode='A',@beg_date=@beg_date,@end_date=@end_date,@calendar_id=@calendar_id


IF NOT EXISTS(SELECT * FROM #calendar)
	SELECT  @end_datetime=NULL
ELSE
	BEGIN
	
	SELECT  @beg_datetime=MIN(C.beg_datetime),
		@delta_time = CASE WHEN @beg_datetime <= MIN(C.beg_datetime)
				THEN @delta_time
				ELSE @delta_time + datediff(minute,MIN(C.beg_datetime),@beg_datetime) / 60.0
				END
	FROM    #calendar C
	WHERE   C.end_datetime > @beg_datetime

	
	WHILE   @delta_time > 0.0
		BEGIN
		
		SELECT  @end_datetime = C.end_datetime
		FROM    #calendar C
		WHERE   C.beg_datetime = @beg_datetime
	
		
		SELECT  @delta_time = @delta_time - datediff(minute,@beg_datetime,@end_datetime) / 60.0

		
		SELECT  @beg_datetime=MIN(C.beg_datetime)
		FROM    #calendar C
		WHERE   C.beg_datetime > @end_datetime
		END

	
	IF @delta_time < 0.0
		SELECT  @end_datetime = dateadd(minute,@delta_time * 60,@end_datetime)
	END

DROP TABLE #calendar

RETURN
END
GO
GRANT EXECUTE ON  [dbo].[fs_calendar_add] TO [public]
GO
