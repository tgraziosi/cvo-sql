SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
CREATE PROC [dbo].[mbbmspCachedComputePer] @BaseDate mbbmudtAppDate, @Year int, @PeriodType tinyint, @PeriodNo int, @NewPerBeginDate mbbmudtAppDate OUTPUT, @NewPerEndDate mbbmudtAppDate OUTPUT
WITH ENCRYPTION
AS
BEGIN
/************************************************************************************
* Copyright 2008 Sage Software, Inc. All rights reserved.                           *
* This procedure, trigger or view is the intellectual property of Sage Software,    *
* Inc.  You may not reverse engineer, alter, or redistribute this code without the  *
* express written permission of Sage Software, Inc.  This code, or any portions of  *
* it, may not be used for any other purpose except for the use of the application   *
* software that it was shipped with.  This code falls under the licensing agreement *
* shipped with the software.  See your license agreement for further information.   *
************************************************************************************/
	DECLARE @NewYear int, @NewPeriod int, @Ctr int

	SELECT @NewYear = YearNumber,
		@NewPeriod = PeriodNumber
		FROM #mbPeriodsCache
		WHERE PeriodStartDate <= @BaseDate AND
			PeriodEndDate >= @BaseDate

	SELECT @NewYear = @NewYear - @Year

	IF @PeriodType = 0 
		SELECT @NewPeriod = @PeriodNo
	ELSE BEGIN
		SELECT @NewPerEndDate = PeriodEndDate
			FROM #mbPeriodsCache
			WHERE YearNumber = @NewYear
				AND PeriodNumber = @NewPeriod
		SELECT @Ctr = @PeriodNo 
		WHILE @Ctr <> 0 AND @NewPerEndDate <> NULL
			IF @Ctr > 0 BEGIN
				SELECT @NewPerEndDate = MIN(PeriodEndDate)
					FROM #mbPeriodsCache
					WHERE PeriodEndDate > @NewPerEndDate
				SELECT @Ctr = @Ctr - 1
			END
			ELSE BEGIN
				SELECT @NewPerEndDate = MAX(PeriodEndDate)
					FROM #mbPeriodsCache
					WHERE PeriodEndDate < @NewPerEndDate
				SELECT @Ctr = @Ctr + 1
			END
		IF @NewPerEndDate = NULL
			SELECT @NewYear = NULL,
				@NewPeriod = NULL
		ELSE
			SELECT @NewYear = YearNumber,
				@NewPeriod = PeriodNumber
				FROM #mbPeriodsCache
				WHERE PeriodEndDate = @NewPerEndDate
	
	END
	IF @NewYear = NULL or @NewPeriod=NULL
		SELECT @NewPerBeginDate = NULL,
			@NewPerEndDate = NULL
	ELSE
		SELECT @NewPerBeginDate = PeriodStartDate, 
			@NewPerEndDate = PeriodEndDate
			FROM #mbPeriodsCache
			WHERE YearNumber = @NewYear
				AND PeriodNumber = @NewPeriod
END
GO
GRANT EXECUTE ON  [dbo].[mbbmspCachedComputePer] TO [Analytics]
GO
GRANT EXECUTE ON  [dbo].[mbbmspCachedComputePer] TO [public]
GO
