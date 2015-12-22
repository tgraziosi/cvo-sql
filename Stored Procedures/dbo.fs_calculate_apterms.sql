SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[fs_calculate_apterms] 
		@date_doc		datetime,
		@terms_code		varchar(8) AS


BEGIN
  set nocount on

  CREATE TABLE #apterm
   (
	date_doc		int,
	terms_code		varchar(8),
	date_due		int,
	date_discount           int
   )


DECLARE @idate_due int    ,@idate_discount int, @idate_doc int
DECLARE @date_due datetime,@date_discount datetime, @result_str varchar(12),
  @disc_days int



select @idate_doc = datediff(day,'01/01/1900',@date_doc) + 693596


insert into #apterm 
   (date_doc,terms_code,date_due,date_discount)

 SELECT @idate_doc,@terms_code,0,0
                            

----------------------------------------------------------
select @disc_days = isnull((select d.discount_days from aptermsd d
where d.terms_code = @terms_code and d.sequence_id =
isnull((select min(sequence_id) from aptermsd dd where dd.terms_code = @terms_code and discount_prc != 0),-1)),0)	-- mls 5/20/04 SCR 32756


UPDATE	#apterm
SET	date_due = #apterm.date_doc + t.days_due,
	date_discount = case when @disc_days = 0 then
		#apterm.date_doc + t.days_due else #apterm.date_doc + @disc_days end
FROM	apterms t
WHERE	#apterm.terms_code = t.terms_code
AND	t.terms_type = 1

UPDATE	#apterm
SET	date_due = datediff(day,'01/01/1900',dateadd(dd,t.min_days_due - datepart(dd,@date_doc),dateadd(mm,t.days_due,@date_doc))) + 693596,
	date_discount = case when @disc_days = 0 then
	  datediff(day,'01/01/1900',dateadd(dd,t.min_days_due - datepart(dd,@date_doc),dateadd(mm,t.days_due,@date_doc))) + 693596
          else #apterm.date_doc + @disc_days end
FROM	apterms t
WHERE	#apterm.terms_code = t.terms_code
AND	t.terms_type = 4
	
	
	SELECT	a.date_doc doc_date,
		b.terms_code term,
		datepart(mm,dateadd(dd,a.date_doc + min_days_due - 657072,'1/1/1800')) month,
		datepart(dd,dateadd(dd,a.date_doc + min_days_due - 657072,'1/1/1800')) days,
		datepart(yy,dateadd(dd,a.date_doc + min_days_due - 657072,'1/1/1800')) years,
		datediff(dd,dateadd(yy,datepart(yy,dateadd(dd,a.date_doc + min_days_due - 657072,'1/1/1800'))-1800,
			dateadd(mm,datepart(mm,dateadd(dd,a.date_doc + min_days_due - 657072,'1/1/1800')) - 1,'1/1/1800')),
				dateadd(yy,datepart(yy,dateadd(dd,a.date_doc + min_days_due - 657072,'1/1/1800'))-1800,
					dateadd(mm,datepart(mm,dateadd(dd,a.date_doc + min_days_due - 657072,'1/1/1800')),'1/1/1800'))) month1,
		datediff(dd,dateadd(yy,datepart(yy,dateadd(dd,a.date_doc + min_days_due - 657072,'1/1/1800'))-1800,
			dateadd(mm,datepart(mm,dateadd(dd,a.date_doc + min_days_due - 657072,'1/1/1800')),'1/1/1800')),
				dateadd(yy,datepart(yy,dateadd(dd,a.date_doc + min_days_due - 657072,'1/1/1800'))-1800,
					dateadd(mm,datepart(mm,dateadd(dd,a.date_doc + min_days_due - 657072,'1/1/1800'))+1,'1/1/1800'))) month2,
		b.days_due,
		(1-ABS(SIGN(b.min_days_due-31)))*(1-ABS(SIGN(b.days_due-31)))*
			datepart(mm,dateadd(dd,a.date_doc - 657072,'1/1/1800'))*5 mark_flag
	INTO	#days_temp
	FROM	#apterm a, apterms b
	WHERE	a.terms_code = b.terms_code
	AND	b.terms_type = 2

	SELECT	a.date_doc doc_date,
		b.terms_code term,
		datepart(mm,dateadd(dd,a.date_doc + min_days_due - 657072,'1/1/1800')) month,
		datepart(dd,dateadd(dd,a.date_doc + min_days_due - 657072,'1/1/1800')) days,
		datepart(yy,dateadd(dd,a.date_doc + min_days_due - 657072,'1/1/1800')) years,
		datediff(dd,dateadd(yy,datepart(yy,dateadd(dd,a.date_doc + min_days_due - 657072,'1/1/1800'))-1800,
			dateadd(mm,datepart(mm,dateadd(dd,a.date_doc + min_days_due - 657072,'1/1/1800')) - 1,'1/1/1800')),
				dateadd(yy,datepart(yy,dateadd(dd,a.date_doc + min_days_due - 657072,'1/1/1800'))-1800,
					dateadd(mm,datepart(mm,dateadd(dd,a.date_doc + min_days_due - 657072,'1/1/1800')),'1/1/1800'))) month1,
		datediff(dd,dateadd(yy,datepart(yy,dateadd(dd,a.date_doc + min_days_due - 657072,'1/1/1800'))-1800,
			dateadd(mm,datepart(mm,dateadd(dd,a.date_doc + min_days_due - 657072,'1/1/1800')),'1/1/1800')),
				dateadd(yy,datepart(yy,dateadd(dd,a.date_doc + min_days_due - 657072,'1/1/1800'))-1800,
					dateadd(mm,datepart(mm,dateadd(dd,a.date_doc + min_days_due - 657072,'1/1/1800'))+1,'1/1/1800'))) month2,
		c.discount_days,
		(1-ABS(SIGN(b.min_days_due-31)))*(1-ABS(SIGN(c.discount_days-31)))*
			datepart(mm,dateadd(dd,a.date_doc - 657072,'1/1/1800'))*5 mark_flag,
                c.sequence_id
	INTO	#discount_temp
	FROM	#apterm a, apterms b, aptermsd c
	WHERE	a.terms_code = b.terms_code
        and     b.terms_code = c.terms_code
	AND	b.terms_type = 2
	AND c.discount_days > 0
 
        delete d
        from #discount_temp d,
          (select term, min(sequence_id) from #discount_temp  group by term) as t(term, sequence_id)
        where d.term = t.term and d.sequence_id != t.sequence_id

	UPDATE	#days_temp
	SET	mark_flag = 1,
		days = days_due
	WHERE	days_due <= month1
	AND	days_due >= days
	AND	mark_flag = 0

	UPDATE	#discount_temp
	SET	mark_flag = 1,
		days = discount_days
	WHERE	discount_days <= month1
	AND	discount_days >= days
	AND	mark_flag = 0

	
	UPDATE	#days_temp
	SET	mark_flag = 2,
		days = month1
	WHERE	days_due >= days
	AND	days_due > month1
	AND	mark_flag = 0

	UPDATE	#discount_temp
	SET	mark_flag = 2,
		days = month1
	WHERE	discount_days >= days
	AND	discount_days > month1
	AND	mark_flag = 0

	
	UPDATE	#days_temp
	SET	mark_flag = 3,
		days = days_due,
		month = month + 1
	WHERE	days_due <= month2
	AND	days_due < days
	AND	mark_flag = 0

	UPDATE	#discount_temp
	SET	mark_flag = 3,
		days = discount_days,
		month = month + 1
	WHERE	discount_days <= month2
	AND	discount_days < days
	AND	mark_flag = 0

	
	UPDATE	#days_temp
	SET	mark_flag = 4,
		days = month2,
		month = month + 1
	WHERE	days_due > month2
	AND	days_due < days
	AND	mark_flag = 0

	UPDATE	#discount_temp
	SET	mark_flag = 4,
		days = month2,
		month = month + 1
	WHERE	discount_days > month2
	AND	discount_days < days
	AND	mark_flag = 0

	
	UPDATE	#days_temp
	SET	month = mark_flag/5 + 1,
		days = datediff(dd,dateadd(yy,datepart(yy,dateadd(dd,doc_date - 657072,'1/1/1800'))-1800,
			dateadd(mm,datepart(mm,dateadd(dd,doc_date - 657072,'1/1/1800')),'1/1/1800')),
				dateadd(yy,datepart(yy,dateadd(dd,doc_date - 657072,'1/1/1800'))-1800,
					dateadd(mm,datepart(mm,dateadd(dd,doc_date - 657072,'1/1/1800'))+1,'1/1/1800'))),
		years = case when mark_flag = 60 then years -1 else years end,					-- mls 1/19/06 SCR 36020
		mark_flag = 5
	WHERE	mark_flag >= 5
	
	UPDATE	#discount_temp
	SET	month = mark_flag/5 + 1,
		days = datediff(dd,dateadd(yy,datepart(yy,dateadd(dd,doc_date - 657072,'1/1/1800'))-1800,
			dateadd(mm,datepart(mm,dateadd(dd,doc_date - 657072,'1/1/1800')),'1/1/1800')),
				dateadd(yy,datepart(yy,dateadd(dd,doc_date - 657072,'1/1/1800'))-1800,
					dateadd(mm,datepart(mm,dateadd(dd,doc_date - 657072,'1/1/1800'))+1,'1/1/1800'))),
		mark_flag = 5
	WHERE	mark_flag >= 5
	
	
	UPDATE	#days_temp
	SET	years = years + 1,
		month = 1
	WHERE	month = 13

	UPDATE	#apterm
	SET	date_due = datediff(dd,'1/1/1800',
			(dateadd(dd, days - 1,
				dateadd(mm,month - 1, 
					dateadd(yy,years - 1800,'1/1/1800')))))+657072
	FROM	apterms b, #days_temp d
	WHERE	#apterm.terms_code = b.terms_code
	AND	b.terms_type = 2
	AND	#apterm.terms_code = d.term
	AND	#apterm.date_doc = d.doc_date

	UPDATE	#discount_temp
	SET	years = years + 1,
		month = 1
	WHERE	month = 13

	UPDATE	#apterm
	SET	date_discount = datediff(dd,'1/1/1800',
			(dateadd(dd, days - 1,
				dateadd(mm,month - 1, 
					dateadd(yy,years - 1800,'1/1/1800')))))+657072
	FROM	apterms b, #discount_temp d
	WHERE	#apterm.terms_code = b.terms_code
	AND	b.terms_type = 2
	AND	#apterm.terms_code = d.term
	AND	#apterm.date_doc = d.doc_date

	DROP TABLE #days_temp
	DROP TABLE #discount_temp





UPDATE	#apterm
SET	date_due = t.date_due,
	date_discount = t.date_discount
FROM	apterms t
WHERE	#apterm.terms_code = t.terms_code
AND	t.terms_type = 3


UPDATE	#apterm
SET	date_discount = date_doc
WHERE	date_discount = 0


-----------------------------------------------------------
   SELECT @idate_due      = date_due,
          @idate_discount = date_discount
     FROM #apterm
     WHERE date_doc   = @idate_doc AND
           terms_code = @terms_code


EXEC date2str_sp @idate_due, @result_str OUT
select @date_due = @result_str

EXEC date2str_sp @idate_discount, @result_str OUT
select @date_discount = @result_str


select @date_due,@date_discount

END

return
GO
GRANT EXECUTE ON  [dbo].[fs_calculate_apterms] TO [public]
GO
