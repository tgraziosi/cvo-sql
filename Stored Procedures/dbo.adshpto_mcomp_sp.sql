SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create proc [dbo].[adshpto_mcomp_sp] @WhereClause varchar(1024)='' AS

DECLARE 	@db_name varchar(128),
		@company_name varchar(30),
		@comp smallint,
		@indx1 int,
		@indx2 int,
		@length int,
		@sub1 varchar(255),
		@sub2 varchar(255),
		@sub3 varchar(255)


CREATE TABLE #shpto
(
	company_name	varchar(30),
	customer_code	varchar(8) NULL,
	ship_to_code	varchar(8) NULL,
	ship_to_name	varchar(40) NULL,
	tax_code	varchar(8) NULL,
	terms_code	varchar(8) NULL,
	fob_code	varchar(8) NULL,
	freight_code	varchar(8) NULL,
	location_code	varchar(10) NULL,
	dest_zone_code	varchar(8) NULL,
	territory_code	varchar(8) NULL
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

			SELECT @sub2 = SUBSTRING(@WhereClause, @indx1, @indx2 - @indx1 )
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
	AND EXISTS( SELECT 1 FROM CVO_Control..s2papprg 
		WHERE app_id = 18000 AND company_db_name = @db_name AND version_code = '7.3.5'))
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
			INSERT INTO #shpto
			SELECT company_name = '''  + @company_name + ''',
			customer_code,
			ship_to_code,
			ship_to_name,
			tax_code,
			terms_code,
			fob_code,
			freight_code,
			location_code,
			dest_zone_code,
			territory_code
		  FROM 
		  	' + @db_name + '..adshpto_vw
		 ' + @WhereClause + ''
		)
	END
	
	 SELECT @db_name = min(db_name) 
	 FROM CVO_Control..smcomp
	 WHERE db_name > @db_name

	SELECT @company_name = ''
	
END

SELECT * FROM #shpto ORDER BY company_name

DROP TABLE #shpto

GO
GRANT EXECUTE ON  [dbo].[adshpto_mcomp_sp] TO [public]
GO
