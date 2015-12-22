SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[APGetTermInfo_sp]
AS

BEGIN



UPDATE	#apterm
SET	date_due = #apterm.date_doc + t.days_due,
	date_discount = #apterm.date_doc + t.discount_days
FROM	apterms t
WHERE	#apterm.terms_code = t.terms_code
AND	t.terms_type = 1


	
	
	SELECT	a.date_doc doc_date,
		b.terms_code term,
		datepart(mm,dateadd(dd,a.date_doc + min_days_due - 657072,"1/1/1800")) month,
		datepart(dd,dateadd(dd,a.date_doc + min_days_due - 657072,"1/1/1800")) days,
		datepart(yy,dateadd(dd,a.date_doc + min_days_due - 657072,"1/1/1800")) years,
		datediff(dd,dateadd(yy,datepart(yy,dateadd(dd,a.date_doc + min_days_due - 657072,"1/1/1800"))-1800,
			dateadd(mm,datepart(mm,dateadd(dd,a.date_doc + min_days_due - 657072,"1/1/1800")) - 1,"1/1/1800")),
				dateadd(yy,datepart(yy,dateadd(dd,a.date_doc + min_days_due - 657072,"1/1/1800"))-1800,
					dateadd(mm,datepart(mm,dateadd(dd,a.date_doc + min_days_due - 657072,"1/1/1800")),"1/1/1800"))) month1,
		datediff(dd,dateadd(yy,datepart(yy,dateadd(dd,a.date_doc + min_days_due - 657072,"1/1/1800"))-1800,
			dateadd(mm,datepart(mm,dateadd(dd,a.date_doc + min_days_due - 657072,"1/1/1800")),"1/1/1800")),
				dateadd(yy,datepart(yy,dateadd(dd,a.date_doc + min_days_due - 657072,"1/1/1800"))-1800,
					dateadd(mm,datepart(mm,dateadd(dd,a.date_doc + min_days_due - 657072,"1/1/1800"))+1,"1/1/1800"))) month2,
		b.days_due,
		(1-ABS(SIGN(b.min_days_due-31)))*(1-ABS(SIGN(b.days_due-31)))*
			datepart(mm,dateadd(dd,a.date_doc - 657072,"1/1/1800"))*5 mark_flag
	INTO	#days_temp
	FROM	#apterm a, apterms b
	WHERE	a.terms_code = b.terms_code
	AND	b.terms_type = 2

	SELECT	a.date_doc doc_date,
		b.terms_code term,
		datepart(mm,dateadd(dd,a.date_doc + min_days_due - 657072,"1/1/1800")) month,
		datepart(dd,dateadd(dd,a.date_doc + min_days_due - 657072,"1/1/1800")) days,
		datepart(yy,dateadd(dd,a.date_doc + min_days_due - 657072,"1/1/1800")) years,
		datediff(dd,dateadd(yy,datepart(yy,dateadd(dd,a.date_doc + min_days_due - 657072,"1/1/1800"))-1800,
			dateadd(mm,datepart(mm,dateadd(dd,a.date_doc + min_days_due - 657072,"1/1/1800")) - 1,"1/1/1800")),
				dateadd(yy,datepart(yy,dateadd(dd,a.date_doc + min_days_due - 657072,"1/1/1800"))-1800,
					dateadd(mm,datepart(mm,dateadd(dd,a.date_doc + min_days_due - 657072,"1/1/1800")),"1/1/1800"))) month1,
		datediff(dd,dateadd(yy,datepart(yy,dateadd(dd,a.date_doc + min_days_due - 657072,"1/1/1800"))-1800,
			dateadd(mm,datepart(mm,dateadd(dd,a.date_doc + min_days_due - 657072,"1/1/1800")),"1/1/1800")),
				dateadd(yy,datepart(yy,dateadd(dd,a.date_doc + min_days_due - 657072,"1/1/1800"))-1800,
					dateadd(mm,datepart(mm,dateadd(dd,a.date_doc + min_days_due - 657072,"1/1/1800"))+1,"1/1/1800"))) month2,
		b.discount_days,
		(1-ABS(SIGN(b.min_days_due-31)))*(1-ABS(SIGN(b.discount_days-31)))*
			datepart(mm,dateadd(dd,a.date_doc - 657072,"1/1/1800"))*5 mark_flag
	INTO	#discount_temp
	FROM	#apterm a, apterms b
	WHERE	a.terms_code = b.terms_code
	AND	b.terms_type = 2
	AND b.discount_days > 0

	
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
		days = datediff(dd,dateadd(yy,datepart(yy,dateadd(dd,doc_date - 657072,"1/1/1800"))-1800,
			dateadd(mm,datepart(mm,dateadd(dd,doc_date - 657072,"1/1/1800")),"1/1/1800")),
				dateadd(yy,datepart(yy,dateadd(dd,doc_date - 657072,"1/1/1800"))-1800,
					dateadd(mm,datepart(mm,dateadd(dd,doc_date - 657072,"1/1/1800"))+1,"1/1/1800"))),
		mark_flag = 5
	WHERE	mark_flag >= 5
	
	UPDATE	#discount_temp
	SET	month = mark_flag/5 + 1,
		days = datediff(dd,dateadd(yy,datepart(yy,dateadd(dd,doc_date - 657072,"1/1/1800"))-1800,
			dateadd(mm,datepart(mm,dateadd(dd,doc_date - 657072,"1/1/1800")),"1/1/1800")),
				dateadd(yy,datepart(yy,dateadd(dd,doc_date - 657072,"1/1/1800"))-1800,
					dateadd(mm,datepart(mm,dateadd(dd,doc_date - 657072,"1/1/1800"))+1,"1/1/1800"))),
		mark_flag = 5
	WHERE	mark_flag >= 5
	
	
	UPDATE	#days_temp
	SET	years = years + 1,
		month = 1
	WHERE	month = 13

	UPDATE	#apterm
	SET	date_due = datediff(dd,"1/1/1800",
			(dateadd(dd, days - 1,
				dateadd(mm,month - 1, 
					dateadd(yy,years - 1800,"1/1/1800")))))+657072
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
	SET	date_discount = datediff(dd,"1/1/1800",
			(dateadd(dd, days - 1,
				dateadd(mm,month - 1, 
					dateadd(yy,years - 1800,"1/1/1800")))))+657072
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



END
 
GO
GRANT EXECUTE ON  [dbo].[APGetTermInfo_sp] TO [public]
GO
