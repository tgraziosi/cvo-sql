SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[apterms_sp]  @debug_level smallint = 0

AS
   DECLARE @date_doc int,
		   @terms_code varchar(8),
		   @date_due int,
		   @date_disc int 	


UPDATE #apterms
SET date_due = b.date_due,
	date_discount = f.date_discount
FROM #apterms a, apterms b, aptermsd f
WHERE a.terms_code = b.terms_code
AND b.terms_type = 3
AND     f.terms_code = b.terms_code
AND     f.sequence_id = (SELECT MIN(sequence_id) FROM aptermsd)


UPDATE #apterms
SET date_due = b.date_due,
	date_discount = b.date_due
FROM #apterms a, apterms b
WHERE a.terms_code = b.terms_code
AND b.terms_type = 3
AND	NOT EXISTS(SELECT 1 FROM aptermsd WHERE terms_code = b.terms_code)




UPDATE #apterms
SET date_due = a.date_doc + b.days_due,
	date_discount = a.date_doc + b.discount_days
	--date_discount = @date_disc	
FROM #apterms a, apterms b, aptermsd f 
WHERE a.terms_code = b.terms_code
AND b.terms_type = 1
AND b.discount_days > 0
AND     f.terms_code = b.terms_code
AND     f.sequence_id = (SELECT MIN(sequence_id) FROM aptermsd)
	

UPDATE #apterms
SET date_due = a.date_doc + b.days_due,
    date_discount = a.date_doc + f.discount_days
     
    -- date_discount = @date_disc
FROM #apterms a, apterms b , aptermsd f 
WHERE a.terms_code = b.terms_code
AND b.terms_type = 1
AND b.discount_days <= 0
AND     f.terms_code = b.terms_code
AND     f.sequence_id = (SELECT MIN(sequence_id) FROM aptermsd)

UPDATE #apterms
SET date_due = a.date_doc + b.days_due,
	date_discount = a.date_doc + b.discount_days
	--date_discount = @date_disc	
FROM #apterms a, apterms b
WHERE a.terms_code = b.terms_code
AND b.terms_type = 1
AND b.discount_days > 0
AND	NOT EXISTS(SELECT 1 FROM aptermsd WHERE terms_code = b.terms_code)
	

UPDATE #apterms
SET date_due = a.date_doc + b.days_due,
    date_discount = a.date_doc + b.days_due 
   -- date_discount = @date_disc
FROM #apterms a, apterms b 
WHERE a.terms_code = b.terms_code
AND b.terms_type = 1
AND b.discount_days <= 0
AND	NOT EXISTS(SELECT 1 FROM aptermsd WHERE terms_code = b.terms_code)
	


	SELECT 	a.date_doc doc_date,
		b.terms_code term,
		dateadd(day, a.date_doc - 693596,'01/01/1900') doc_date_greg, 	
		b.days_due months,
		b.min_days_due days,
		(dateadd(dd, 0 ,
			dateadd(mm, month( dateadd(day, a.date_doc - 693596,'01/01/1900') )-1 , 
				dateadd(yy,year( dateadd(day, a.date_doc - 693596,'01/01/1900') ) - 1800,'1/1/1800')))) due_date_greg
	INTO	#days_temp_4
	FROM	#apterms a, apterms b
	WHERE	a.terms_code = b.terms_code
	AND	b.terms_type = 4

	
	UPDATE #days_temp_4
	SET due_date_greg = dateadd(month, months,due_date_greg)
	



	UPDATE #days_temp_4
	SET due_date_greg = dateadd(day, days-1,due_date_greg)


		
			UPDATE	#apterms
			SET	date_due = datediff(dd,'1/1/1800',
					(dateadd(dd, day(due_date_greg) -1,
						dateadd(mm,month(due_date_greg)-1 , 
							dateadd(yy,year(due_date_greg) - 1800,'1/1/1800')   )))
					) + 657072, 
				date_discount = datediff(dd,'1/1/1800',
					(dateadd(dd, day(due_date_greg) -1,
						dateadd(mm,month(due_date_greg)-1 , 
							dateadd(yy,year(due_date_greg) - 1800,'1/1/1800')   )))
					) + 657072	
			FROM	apterms b, #days_temp_4 d
			WHERE	#apterms.terms_code = b.terms_code
			AND	b.terms_type = 4
			AND	#apterms.terms_code = d.term
			AND	#apterms.date_doc = d.doc_date
			AND	NOT EXISTS(SELECT 1 FROM aptermsd WHERE terms_code = b.terms_code)

			UPDATE	#apterms
			SET	date_due = datediff(dd,'1/1/1800',
					(dateadd(dd, day(due_date_greg) -1,
						dateadd(mm,month(due_date_greg)-1 , 
							dateadd(yy,year(due_date_greg) - 1800,'1/1/1800')   )))
					) + 657072  ,
				date_discount = #apterms.date_doc + f.discount_days
			FROM	apterms b, #days_temp_4 d,aptermsd f
			WHERE	#apterms.terms_code = b.terms_code
			AND	b.terms_type = 4
			AND	#apterms.terms_code = d.term
			AND	#apterms.date_doc = d.doc_date
			AND     f.terms_code = b.terms_code
			AND     f.sequence_id = (SELECT MIN(sequence_id) FROM aptermsd)
	

	drop table #days_temp_4

	

WHILE (1=1)
     BEGIN
		  SET ROWCOUNT 1
		  SELECT @date_doc = date_doc,
				 @terms_code = terms_code
		  FROM #apterms
		  WHERE date_due = 0 
		  IF @@rowcount = 0 break
		  SET ROWCOUNT 0
		  	
		  EXEC appdtdue_sp 4000, 
						   @terms_code,
						   @date_doc,
						   @date_due OUTPUT
		
		  IF (@date_due = 0) 
		  begin	
		  SELECT @date_due = -1
		  end
		  EXEC appdtdisc_sp 4000, 
						   @terms_code,
						   @date_doc,
						   @date_disc OUTPUT
		
		  IF (@date_disc = 0) 
		  begin	
		  SELECT  @date_disc = @date_due 
		  end 	
	
		  UPDATE #apterms
		  SET date_due = @date_due,
			
			    date_discount = @date_disc	
		  FROM #apterms a, apterms b
		  WHERE a.terms_code = b.terms_code
		  AND a.terms_code = @terms_code
		  AND a.date_doc = @date_doc
		  
		
		
			

		
	 END
  SET ROWCOUNT 0

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[apterms_sp] TO [public]
GO
