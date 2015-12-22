SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2001 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2001 Epicor Software Corporation, 2001    
                  All Rights Reserved                    
*/                                                












CREATE PROC [dbo].[gljnl_mcomp_sp] @WhereClause varchar(1024)='' as 


DECLARE 	@db_name varchar(128),
		@company_name varchar(30),
		@comp smallint,
		@indx1 int,
		@indx2 int,
		@length int,
		@sub1 varchar(255),
		@sub2 varchar(255),
		@sub3 varchar(255)
	

CREATE TABLE #gljnl_vw (
company_name		varchar(30),
journal_ctrl_num		varchar(16)		 ,
org_id			varchar(30) NULL,
journal_type		varchar(8)		 ,
journal_description		varchar(30)		 ,
app_title		char(40)		 ,
trx_type_desc		varchar(30)		 ,
posted_flag		varchar(3)		NULL,
date_applied		int 		 ,
date_posted		int 		 ,
reversing_flag		varchar(3)		NULL,
repeating_flag		varchar(3)		NULL,
recurring_flag		varchar(3)		NULL,
hold_flag		varchar(3)		NULL,
intercompany_flag		varchar(3)		NULL,
interbranch_flag		varchar(3)	NULL,
source_company_code		varchar(8)		 ,
x_date_applied		int 		 ,
x_date_posted		int 		 ,
)




SELECT @comp = 0
SELECT @indx1 = CHARINDEX('company_name', @WhereClause)
IF(@indx1 > 0 )
BEGIN
	SELECT @comp = 1
	SELECT @sub1 = SUBSTRING(@WhereClause, 1, @indx1 - 1)
	
	SELECT @indx2 = CHARINDEX('AND', @WhereClause, @indx1)
	
	IF( @indx2 > 0)
		BEGIN
			SELECT @sub2 = SUBSTRING(@WhereClause, @indx1, @indx2 - @indx1)
			SELECT @sub3 = SUBSTRING(@WhereClause, @indx1 + LEN(@sub2) + 5, LEN(@WhereClause)-(LEN(@sub2) + 5))
			SELECT @WhereClause = @sub1 + @sub3
		END
	ELSE
		BEGIN
			SELECT @sub2 = SUBSTRING(@WhereClause, @indx1, LEN(@WhereClause))
			SELECT @WhereClause = SUBSTRING(@sub1, 1, @indx1 - 5)
		END

	IF(CHARINDEX('like',@sub2,1) > 0)
	BEGIN
		SELECT @sub3 = SUBSTRING(@sub2, 18, LEN(@sub2))
	END
	ELSE
	BEGIN
		SELECT @sub3 = SUBSTRING(@sub2, 16, LEN(@sub2))		
	END
END
IF(LEN(@WhereClause) < 6)
BEGIN
	SELECT @WhereClause = ''
END

SELECT @db_name = min(db_name) 
FROM CVO_Control..smcomp









WHILE (@db_name != '' 
	AND EXISTS( SELECT 1 from CVO_Control..smcomp c INNER JOIN CVO_Control..sminst i ON c.company_id = i.company_id		
			WHERE app_id = 6000 AND c.db_name = @db_name ))
BEGIN


	SELECT @sub3 = REPLACE (@sub3,char(39),'')

	


	SELECT @company_name = company_name
	FROM   CVO_Control..smcomp
	WHERE db_name = @db_name
	AND    company_name like RTRIM(LTRIM(@sub3))


	SELECT  @company_name = isnull(@company_name,'')

	


	IF((HAS_DBACCESS ( @db_name) = 1) AND (  (@company_name != '') OR (@comp = 0) ))
	BEGIN

		IF(@company_name = '')
		BEGIN
			SELECT @company_name = company_name
			FROM   CVO_Control..smcomp
			WHERE db_name = @db_name
		END
		EXEC ('
		 INSERT INTO #gljnl_vw
		 SELECT 
			company_name = ''' + @company_name + ''', 
		  	t1.journal_ctrl_num,
			t1.org_id, 
		  	t1.journal_type,
		  	t1.journal_description,
			t1.app_title,
		  	t1.trx_type_desc,
		  	t1.posted_flag,
			t1.date_applied, 
		  	t1.date_posted,
			t1.reversing_flag,
		  	t1.repeating_flag,
			t1.recurring_flag,
		  	t1.hold_flag,
			t1.intercompany_flag,
			t1.interbranch_flag,
			t1.source_company_code ,
		
			t1.x_date_applied, 
		 	t1.x_date_posted	 
	  
		  FROM 
		  	' + @db_name + '..gljnl_vw t1 '
		
		  +  @WhereClause + ''
		)
	END
	
	 SELECT @db_name = min(db_name) 
	 FROM CVO_Control..smcomp
	 WHERE db_name > @db_name

	SELECT @company_name = ''
	
END

SELECT * FROM #gljnl_vw ORDER BY company_name

DROP TABLE #gljnl_vw




GO
GRANT EXECUTE ON  [dbo].[gljnl_mcomp_sp] TO [public]
GO
