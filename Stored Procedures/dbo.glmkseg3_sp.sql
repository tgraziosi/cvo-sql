SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO






CREATE PROC [dbo].[glmkseg3_sp]	@highcount	int,
			@now		datetime,
			@new_flag 	smallint,
			@new_accounts	int		OUTPUT
AS

DECLARE	@seg_code 	varchar(32),
	@count		int,
	@msg		varchar(40),
	@perc_done	float
        ,
        @main_seg       smallint

SELECT  @main_seg = acct_level 
FROM    glaccdef
WHERE   natural_acct_flag = 1

SELECT @count = 0
SELECT @seg_code = min(seg_code) FROM #seg3




WHILE ( @seg_code IS NOT NULL )
BEGIN
	



        IF ( @main_seg = 1 )
	INSERT #accts
	SELECT
		t1.seg_code+t2.seg_code+t3.seg_code+t4.seg_code,
		left(ltrim(t1.short_desc + " ")
		+ ltrim(t2.short_desc + " ")
		+ ltrim(t3.short_desc + " ")
		+ t4.short_desc,40),
		t1.account_type+t2.account_type+
		   t3.account_type+t4.account_type, 
		t1.new_flag,
		t1.consol_type+t2.consol_type+t3.consol_type+
		   t4.consol_type,
		t1.seg_code, t2.seg_code, t3.seg_code, t4.seg_code,
		t1.consol_detail_flag+t2.consol_detail_flag+
		t3.consol_detail_flag+t4.consol_detail_flag
                ,
                t1.rate_type_home, t1.rate_type_oper
	FROM 	#seg1 t1, #seg2 t2, #seg3 t3, #seg4 t4
	WHERE 	t3.seg_code = @seg_code
	AND	t1.new_flag+t2.new_flag+t3.new_flag+t4.new_flag >= @new_flag
        
        IF ( @main_seg = 2 )
	INSERT #accts
	SELECT
		t1.seg_code+t2.seg_code+t3.seg_code+t4.seg_code,
		left(ltrim(t1.short_desc + " ")
		+ ltrim(t2.short_desc + " ")
		+ ltrim(t3.short_desc + " ")
		+ t4.short_desc,40),
		t1.account_type+t2.account_type+
		   t3.account_type+t4.account_type, 
		t1.new_flag,
		t1.consol_type+t2.consol_type+t3.consol_type+
		   t4.consol_type,
		t1.seg_code, t2.seg_code, t3.seg_code, t4.seg_code,
		t1.consol_detail_flag+t2.consol_detail_flag+
		t3.consol_detail_flag+t4.consol_detail_flag
                ,
                t2.rate_type_home, t2.rate_type_oper
	FROM 	#seg1 t1, #seg2 t2, #seg3 t3, #seg4 t4
        WHERE   t3.seg_code = @seg_code
        AND     t1.new_flag+t2.new_flag+t3.new_flag+t4.new_flag >= @new_flag
         
        IF ( @main_seg = 3 )
	INSERT #accts
	SELECT
		t1.seg_code+t2.seg_code+t3.seg_code+t4.seg_code,
		left(ltrim(t1.short_desc + " ")
		+ ltrim(t2.short_desc + " ")
		+ ltrim(t3.short_desc + " ")
		+ t4.short_desc,40),
		t1.account_type+t2.account_type+
		   t3.account_type+t4.account_type, 
		t1.new_flag,
		t1.consol_type+t2.consol_type+t3.consol_type+
		   t4.consol_type,
		t1.seg_code, t2.seg_code, t3.seg_code, t4.seg_code,
		t1.consol_detail_flag+t2.consol_detail_flag+
		t3.consol_detail_flag+t4.consol_detail_flag
                ,
                t3.rate_type_home, t3.rate_type_oper
	FROM 	#seg1 t1, #seg2 t2, #seg3 t3, #seg4 t4
        WHERE   t3.seg_code = @seg_code
        AND     t1.new_flag+t2.new_flag+t3.new_flag+t4.new_flag >= @new_flag       

        IF ( @main_seg = 4 )
	INSERT #accts
	SELECT
		t1.seg_code+t2.seg_code+t3.seg_code+t4.seg_code,
		left(ltrim(t1.short_desc + " ")
		+ ltrim(t2.short_desc + " ")
		+ ltrim(t3.short_desc + " ")
		+ t4.short_desc,40),
		t1.account_type+t2.account_type+
		   t3.account_type+t4.account_type, 
		t1.new_flag,
		t1.consol_type+t2.consol_type+t3.consol_type+
		   t4.consol_type,
		t1.seg_code, t2.seg_code, t3.seg_code, t4.seg_code,
		t1.consol_detail_flag+t2.consol_detail_flag+
		t3.consol_detail_flag+t4.consol_detail_flag
                ,
                t4.rate_type_home, t4.rate_type_oper
	FROM 	#seg1 t1, #seg2 t2, #seg3 t3, #seg4 t4
        WHERE   t3.seg_code = @seg_code
        AND     t1.new_flag+t2.new_flag+t3.new_flag+t4.new_flag >= @new_flag

        
	


	DELETE 	#accts 
	FROM 	#accts, glchaexc
	WHERE 	account_code LIKE account_pattern

	



	DELETE 	#accts 
	FROM 	#accts, glchart
	WHERE 	#accts.account_code = glchart.account_code

	


	INSERT	#glchart
	SELECT 	NULL, account_code, account_description,
	   	account_type, new_flag, seg1, seg2, seg3, seg4,
	   	detail_flag, consol_type, 0, 0, 0, "", 0
                ,
                rate_type_home, rate_type_oper,NULL
	FROM 	#accts

	


	SELECT 	@new_accounts = @new_accounts + count(account_code)
	FROM	#accts

	TRUNCATE TABLE #accts
	
	


	SELECT @count = @count + 1
	SELECT @perc_done = (100*@count)/@highcount

	SELECT @msg="Building chart, time = "
	   +str(datediff( ms, @now, getdate() ) )+" ms"

	


	SELECT 	@seg_code = min(seg_code)
	FROM 	#seg3
	WHERE 	seg_code > @seg_code
END

RETURN 0

GO
GRANT EXECUTE ON  [dbo].[glmkseg3_sp] TO [public]
GO
