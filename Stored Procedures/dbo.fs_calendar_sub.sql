SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


--  Copyright (c) 1997 Epicor Software, Inc. All Right Reserved.
CREATE PROCEDURE [dbo].[fs_calendar_sub]
	(
	@calendar_id		INT,
	@delta_time		FLOAT,
	@beg_datetime		DATETIME OUT,
	@end_datetime		DATETIME
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


SELECT	@end_date = datename(year,@end_datetime)+'-'+datename(month,@end_datetime)+'-'+datename(day,@end_datetime)
SELECT	@beg_date = dateadd(year,-1,@end_date),
	@end_date = dateadd(day,1,@end_date)
INSERT	#calendar(work_date,beg_datetime,end_datetime)
EXECUTE	fs_build_calendar @build_mode='A',@beg_date=@beg_date,@end_date=@end_date,@calendar_id=@calendar_id


IF NOT EXISTS(SELECT * FROM #calendar)
	SELECT  @beg_datetime=NULL
ELSE
	BEGIN
	
	SELECT  @end_datetime=MAX(C.end_datetime),
		@delta_time = CASE WHEN @end_datetime >= MAX(C.end_datetime)
				THEN @delta_time
				ELSE @delta_time + datediff(minute,@end_datetime,MAX(C.end_datetime)) / 60.0
				END
	FROM    #calendar C
	WHERE   C.beg_datetime < @end_datetime

	
	WHILE   @delta_time > 0.0
		BEGIN
		
		SELECT  @beg_datetime = C.beg_datetime
		FROM    #calendar C
		WHERE   C.end_datetime = @end_datetime
	
		
		SELECT  @delta_time = @delta_time - datediff(minute,@beg_datetime,@end_datetime) / 60.0

		
		SELECT  @end_datetime=MAX(C.end_datetime)
		FROM    #calendar C
		WHERE   C.end_datetime < @beg_datetime
		END

	
	IF @delta_time < 0.0
		SELECT  @beg_datetime = dateadd(minute,-@delta_time * 60,@beg_datetime)
	END

DROP TABLE #calendar

RETURN
END
GO
GRANT EXECUTE ON  [dbo].[fs_calendar_sub] TO [public]
GO
