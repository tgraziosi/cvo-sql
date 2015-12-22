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












CREATE PROC [dbo].[gllin_mcomp_sp] @WhereClause varchar(1024)='' AS

DECLARE 	@db_name varchar(128),
		@company_name varchar(30),
		@comp smallint,
		@indx1 int,
		@indx2 int,
		@length int,
		@sub1 varchar(255),
		@sub2 varchar(255),
		@sub3 varchar(255)


CREATE TABLE #gllin
(
company_name		varchar(30),
journal_ctrl_num	varchar(16),
org_id			varchar(30) NULL,
date_applied		int 		 ,
sequence_id		int 		 ,
rec_company_code	varchar(8)		 ,
account_code		varchar(36)		NULL,
description		varchar(40)		 ,
document_1		varchar(16)		 ,
document_2		varchar(16)		 ,
nat_cur_code		varchar(8)		 ,
nat_balance		float 		 ,
reference_code		varchar(32)		 ,
rate_type_home		varchar(8)		NULL,
rate			float 		 ,
home_cur_code		varchar(8)		 ,
balance			float 		 ,
rate_type_oper		varchar(8)		NULL,
rate_oper		float 		NULL,
oper_cur_code		varchar(8)		NULL,
balance_oper		float 		NULL,
posted_flag		varchar(3)		NULL,
x_date_applied		int 		 ,
x_sequence_id		int 		 ,
x_nat_balance		float 		 ,
x_rate			float 		 ,
x_balance		float 		 ,
x_rate_oper		float 		NULL,
x_balance_oper		float 		NULL,

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
	AND EXISTS(SELECT 1 from CVO_Control..smcomp c INNER JOIN CVO_Control..sminst i ON c.company_id = i.company_id		
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
		 INSERT INTO #gllin
		 SELECT company_name = '''  + @company_name + ''',
		  	t1.journal_ctrl_num,
			t1.org_id, 
		  	t1.date_applied,
		  	t1.sequence_id,
			t1.rec_company_code,
		  	cast(t1.account_code as varchar(36)) as account_code, 
		  	t1.description,
			t1.document_1,
			t1.document_2,
			t1.nat_cur_code, 
		  	t1.nat_balance,
			t1.reference_code,
		  	t1.rate_type_home,
			t1.rate,
			t1.home_cur_code,
		  	t1.balance,
			t1.rate_type_oper,
			t1.rate_oper,
			t1.oper_cur_code,
			t1.balance_oper,
			t1.posted_flag,		
		 	x_date_applied=t1.date_applied,
		 	x_sequence_id=t1.sequence_id,
		 	x_nat_balance=t1.nat_balance,
			x_rate=t1.rate,
		 	x_balance=t1.balance,
			x_rate_oper=t1.rate_oper,
			x_balance_oper=t1.balance_oper
		
		  FROM 
		  	' + @db_name + '..gllin_vw t1
		
		  ' + @WhereClause
		)
	END
	
	 SELECT @db_name = min(db_name) 
	 FROM CVO_Control..smcomp
	 WHERE db_name > @db_name

	SELECT @company_name = ''
	
END

SELECT * FROM #gllin ORDER BY company_name

DROP TABLE #gllin




GO
GRANT EXECUTE ON  [dbo].[gllin_mcomp_sp] TO [public]
GO
