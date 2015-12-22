SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[ARGetTermInfo_SP]
AS

BEGIN





UPDATE	#arterm
SET	date_due = #arterm.date_doc + t.days_due,
	date_discount = #arterm.date_doc + t.discount_days
FROM	arterms t
WHERE	#arterm.terms_code = t.terms_code
AND	t.terms_type = 1




	













	
	SELECT	a.date_doc doc_date,
		b.terms_code term,
		datepart(mm,dateadd(dd,a.date_doc  + min_days_due - 657072,'1/1/1800')) month,
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
	FROM	#arterm a, arterms b
	WHERE	a.terms_code = b.terms_code
	AND	b.terms_type = 2

	SELECT	a.date_doc doc_date,
		b.terms_code term,
		datepart(mm,dateadd(dd,a.date_doc  + min_days_due - 657072,'1/1/1800')) month,
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
		b.discount_days,
		(1-ABS(SIGN(b.min_days_due-31)))*(1-ABS(SIGN(b.discount_days-31)))*
			datepart(mm,dateadd(dd,a.date_doc - 657072,'1/1/1800'))*5 mark_flag
	INTO	#discount_temp
	FROM	#arterm a, arterms b
	WHERE	a.terms_code = b.terms_code
	AND	b.terms_type = 2
	AND	b.discount_days > 0

	



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
	SET	
		days = datediff(dd,dateadd(yy,datepart(yy,dateadd(dd,doc_date - 657072,'1/1/1800'))-1800,
			dateadd(mm,datepart(mm,dateadd(dd,doc_date - 657072,'1/1/1800')),'1/1/1800')),
				dateadd(yy,datepart(yy,dateadd(dd,doc_date - 657072,'1/1/1800'))-1800,
					dateadd(mm,datepart(mm,dateadd(dd,doc_date - 657072,'1/1/1800'))+1,'1/1/1800'))),
		mark_flag = 5
	WHERE	mark_flag >= 5
	
	UPDATE	#discount_temp
	SET	
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

	UPDATE	#arterm
	SET	date_due = datediff(dd,'1/1/1800',
			(dateadd(dd, days - 1,
				dateadd(mm,month - 1, 
					dateadd(yy,years - 1800,'1/1/1800')))))+657072
	FROM	arterms b, #days_temp d
	WHERE	#arterm.terms_code = b.terms_code
	AND	b.terms_type = 2
	AND	#arterm.terms_code = d.term
	AND	#arterm.date_doc = d.doc_date

	UPDATE	#discount_temp
	SET	years = years + 1,
		month = 1
	WHERE	month = 13

	UPDATE	#arterm
	SET	date_discount = datediff(dd,'1/1/1800',
			(dateadd(dd, days - 1,
				dateadd(mm,month - 1, 
					dateadd(yy,years - 1800,'1/1/1800')))))+657072
	FROM	arterms b, #discount_temp d
	WHERE	#arterm.terms_code = b.terms_code
	AND	b.terms_type = 2
	AND	#arterm.terms_code = d.term
	AND	#arterm.date_doc = d.doc_date

	DROP TABLE #days_temp
	DROP TABLE #discount_temp






UPDATE	#arterm
SET	date_due = t.date_due,
	date_discount = t.date_discount
FROM	arterms t
WHERE	#arterm.terms_code = t.terms_code
AND	t.terms_type = 3





UPDATE	#arterm
SET	date_discount = date_doc
WHERE	date_discount = 0





	











	SELECT 	a.date_doc doc_date,
		b.terms_code term,
		dateadd(day, a.date_doc - 693596,'01/01/1900') doc_date_greg, 	
		b.days_due months,
		b.min_days_due days,
		(dateadd(dd, 0 ,
			dateadd(mm, month( dateadd(day, a.date_doc - 693596,'01/01/1900') )-1 , 
				dateadd(yy,year( dateadd(day, a.date_doc - 693596,'01/01/1900') ) - 1800,'1/1/1800')))) due_date_greg
	INTO	#days_temp_4
	FROM	#arterm a, arterms b
	WHERE	a.terms_code = b.terms_code
	AND	b.terms_type = 4

	




	UPDATE #days_temp_4
	SET due_date_greg = dateadd(month, months,due_date_greg)
	



	UPDATE #days_temp_4
	SET due_date_greg = dateadd(day, days-1,due_date_greg)


	UPDATE	#arterm
	SET	date_due = datediff(dd,'1/1/1800',
			(dateadd(dd, day(due_date_greg) -1,
				dateadd(mm,month(due_date_greg)-1 , 
					dateadd(yy,year(due_date_greg) - 1800,'1/1/1800')   )))
			) + 657072
	FROM	arterms b, #days_temp_4 d
	WHERE	#arterm.terms_code = b.terms_code
	AND	b.terms_type = 4
	AND	#arterm.terms_code = d.term
	AND	#arterm.date_doc = d.doc_date


	DROP TABLE #days_temp_4


END
 
GO
GRANT EXECUTE ON  [dbo].[ARGetTermInfo_SP] TO [public]
GO
