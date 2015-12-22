SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO




CREATE PROC [dbo].[CVO_AC_Inv_CycleCount_Summary] @WhereClause varchar(1024)='' 

AS

/****************************************************************************************
**  				Clear Vision
**  DATE		:	Jan 2012
**  FILE    	:	CVO_AC_Inv_CycleCount_Summary.sql
**	CREATED BY	:   Alain Hurtubise - Antler Consulting
**
**  DESCRIPTION	:	Procedure for explorer view
**		
**	Version		:   1.0
** 
*****************************************************************************************/
BEGIN

SET NOCOUNT ON
DECLARE	
		@orderBy varchar(255),
	 	@db_name varchar(128),
		@company_name varchar(30),
		@comp smallint,
		@indx1 int,
		@indx2 int,
		@length int,
		@sub1 varchar(512),
		@sub2 varchar(512),
		@sub3 varchar(512),
		@AUX varchar (512)


DECLARE @total_counts INT
DECLARE @cycle_count INT
DECLARE	@month INT
DECLARE @year INT

create table #cvo_ac_inv_cyclecount
(
	[id]		int identity(1,1),
	[Year]		int,
	[Month]		int,
	[Month_Text] varchar(10),
	[count_total]	decimal(20,0),
	[count_0]		decimal(20,0),
	[count_0_percent]	decimal(20,2),
	[count_1_2]		decimal(20,0),
	[count_1_2_percent]	decimal(20,2),
	[count_3_5]		decimal(20,0),
	[count_3_5_percent]	decimal(20,2),
	[count_6_10]		decimal(20,0),
	[count_6_10_percent]	decimal(20,2),
	[count_11_20]		decimal(20,0),
	[count_11_20_percent]	decimal(20,2),
	[count_20]		decimal(20,0),
	[count_20_percent]	decimal(20,2),
	[count_accuracy] decimal(20,2)
)

create table #cvo_ac_periods
(
	[year_month] varchar(6)
)

INSERT INTO #cvo_ac_periods
SELECT DISTINCT(convert(varchar,year(issue_date)) + convert(varchar,month(issue_date))) from cvo_ac_inv_cyclecount(NOLOCK)


INSERT INTO #cvo_ac_inv_cyclecount ([Year],[month])
SELECT CONVERT(int, left([year_month],4)),
	   CONVERT(int, substring([year_month],5, 2))
FROM	#cvo_ac_periods   

--UPDATE MONTH TEXT
UPDATE #cvo_ac_inv_cyclecount
SET		[Month_Text] = CASE [Month]
						WHEN 1 THEN 'January'
						WHEN 2 THEN 'February'
						WHEN 3 THEN 'March'
						WHEN 4 THEN 'April'
						WHEN 5 THEN 'May'
						WHEN 6 THEN 'June'
						WHEN 7 THEN 'July'
						WHEN 8 THEN 'August'
						WHEN 9 THEN 'September'
						WHEN 10 THEN 'October'
						WHEN 11 THEN 'November'
						WHEN 12 THEN 'December'
						END
						

DECLARE @counter INT
DECLARE @counter_max INT

SELECT	@counter_max = MAX(id)
FROM	#cvo_ac_inv_cyclecount
						
SELECT @counter = 1

WHILE (@counter <= @counter_max)
BEGIN

	SELECT	@year = [year],
			@month = [month]
	FROM	#cvo_ac_inv_cyclecount
	WHERE	id = @counter
			

	SELECT	@total_counts = COUNT(part_no)
	FROM	cvo_ac_inv_cyclecount
	WHERE   year(issue_date) = @year
	AND		MONTH(issue_date) = @month 

	UPDATE	#cvo_ac_inv_cyclecount
	SET		[count_total] = @total_counts
	WHERE	id = @counter


--
-- 0 
	SELECT	@cycle_count = COUNT(part_no)
	FROM	cvo_ac_inv_cyclecount
	WHERE   (YEAR(issue_date) = @year AND MONTH(issue_date) = @month)
	AND		qty = 0

	UPDATE	#cvo_ac_inv_cyclecount
	SET		[count_0] = @cycle_count
	WHERE	id = @counter

	
	
	
	PRINT @counter
	PRINT @cycle_count


--
-- 1-2
	SELECT	@cycle_count = COUNT(part_no)
	FROM	cvo_ac_inv_cyclecount
	WHERE   (YEAR(issue_date) = @year AND MONTH(issue_date) = @month)
	AND		qty between 1 and 2
	
	UPDATE	#cvo_ac_inv_cyclecount
	SET		[count_1_2] = @cycle_count
	WHERE	id = @counter


--
-- 3-5
	SELECT	@cycle_count = COUNT(part_no)
	FROM	cvo_ac_inv_cyclecount
	WHERE   (YEAR(issue_date) = @year AND MONTH(issue_date) = @month)
	AND		qty between 3 and 5
	
	UPDATE	#cvo_ac_inv_cyclecount
	SET		[count_3_5] = @cycle_count
	WHERE	id = @counter


--
-- 6-10
	SELECT	@cycle_count = COUNT(part_no)
	FROM	cvo_ac_inv_cyclecount
	WHERE   (YEAR(issue_date) = @year AND MONTH(issue_date) = @month)
	AND		qty between 6 and 10
	
	UPDATE	#cvo_ac_inv_cyclecount
	SET		[count_6_10] = @cycle_count
	WHERE	id = @counter

--
-- 11-20
	SELECT	@cycle_count = COUNT(part_no)
	FROM	cvo_ac_inv_cyclecount
	WHERE   (YEAR(issue_date) = @year AND MONTH(issue_date) = @month)
	AND		qty between 11 and 20
	
	UPDATE	#cvo_ac_inv_cyclecount
	SET		[count_11_20] = @cycle_count
			
	WHERE	id = @counter

--
-- 11-20
	SELECT	@cycle_count = COUNT(part_no)
	FROM	cvo_ac_inv_cyclecount
	WHERE   (YEAR(issue_date) = @year AND MONTH(issue_date) = @month)
	AND		qty > 20
	
	UPDATE	#cvo_ac_inv_cyclecount
	SET		[count_20] = @cycle_count
	WHERE	id = @counter


	SELECT @counter = @counter + 1
	
END

	
	UPDATE	#cvo_ac_inv_cyclecount
	SET		[count_0_percent] = ([count_0] / [count_total] ) * 100,
			[count_1_2_percent] = ([count_1_2] / [count_total] ) * 100,
			[count_3_5_percent] = ([count_3_5] / [count_total] ) * 100,
			[count_6_10_percent] = ([count_6_10] / [count_total] ) * 100,
			[count_11_20_percent] = ([count_11_20] / [count_total] ) * 100,
			[count_20_percent] = ([count_20] / [count_total] ) * 100,
			[count_accuracy] = (([count_0] + [count_1_2] + [count_3_5])/[count_total]) *100



SELECT * FROM #cvo_ac_inv_cyclecount ORDER BY [year] DESC, [month] DESC


DROP TABLE #cvo_ac_inv_cyclecount
DROp TABLE #cvo_ac_periods 


END


GO
GRANT EXECUTE ON  [dbo].[CVO_AC_Inv_CycleCount_Summary] TO [public]
GO
