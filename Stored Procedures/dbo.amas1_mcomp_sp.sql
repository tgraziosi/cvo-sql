SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2006 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2006 Epicor Software Corporation, 2006    
                  All Rights Reserved                    
*/                                                













CREATE PROC [dbo].[amas1_mcomp_sp] @WhereClause varchar(1024)='' AS

DECLARE 	@db_name varchar(128),
		@company_name varchar(30),
		@comp smallint,
		@indx1 int,
		@indx2 int,
		@length int,
		@sub1 varchar(255),
		@sub2 varchar(255),
		@sub3 varchar(255)

SELECT * INTO #amas1_comp FROM amas1
DELETE #amas1_comp




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
			WHERE app_id = 10000 AND c.db_name = @db_name ))
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
		EXEC('	INSERT INTO #amas1_comp

		 SELECT company_name = '''  + @company_name + ''',
			co_asset_id,
			asset_ctrl_num,
			asset_description,
			asset_type_code,
			activity_state,
			is_new,
			is_pledged,
			is_property,
			depreciated,
			is_imported,
			lease_type,
			original_cost,
			orig_quantity,
			date_acquisition,
			date_placed_in_service,
			date_disposition,
			category_code,
			account_reference_code,
			policy_number,		
			key_1,
		
			x_original_cost,
			x_orig_quantity,
			x_date_acquisition,
			x_date_placed_in_service,
			x_date_disposition

		  FROM 
		  	' + @db_name + '..amas1_vw
		  '  + @WhereClause
		)
	END

	 SELECT @db_name = min(db_name) 
	 FROM CVO_Control..smcomp
	 WHERE db_name > @db_name

	SELECT @company_name = ''
	
END

SELECT company_name,
co_asset_id,
asset_ctrl_num,
asset_description,
asset_type_code,
activity_state,
is_new,
is_pledged,
is_property,
depreciated,
is_imported,
lease_type,
original_cost,
orig_quantity,
date_acquisition,
date_placed_in_service,
date_disposition,
category_code,
account_reference_code,
policy_number,
key_1,
x_original_cost,
x_orig_quantity,
x_date_acquisition=isnull(datediff( day, '01/01/1900',date_acquisition) + 693596,0) ,
x_date_placed_in_service=isnull(datediff( day, '01/01/1900',date_placed_in_service) + 693596,0) ,
x_date_disposition=isnull(datediff( day, '01/01/1900',date_disposition) + 693596,0) 
 FROM #amas1_comp ORDER BY company_name


DROP TABLE #amas1_comp

GO
GRANT EXECUTE ON  [dbo].[amas1_mcomp_sp] TO [public]
GO
