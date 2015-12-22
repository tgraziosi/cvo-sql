SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROC [dbo].[arinvpay_sp]	@cust_code	varchar( 8 )
AS

BEGIN

	
	IF( (	SELECT ISNULL(status_type, 0)
		FROM arcust
		WHERE customer_code = @cust_code ) = 0 
	 )
			RETURN
	
	
	
	
	TRUNCATE TABLE #arinvpy
	

	
	CREATE TABLE #relcode_custs
	(
		relation_code	char(8),
		parent		char(8),
		across_na	smallint
	)
	
	
	CREATE TABLE	#payer_custs
	(	
		customer_code	varchar(8)
	)

	
	CREATE TABLE	#tiered_custs
	(
		parent		char(8),
		child_1	char(8),
		child_2	char(8),
		child_3	char(8),
		child_4	char(8),
		child_5	char(8),
		child_6	char(8),
		child_7	char(8),
		child_8	char(8),
		child_9	char(8)
	)
	

	
	INSERT	#relcode_custs
	SELECT	DISTINCT relation_code,
		parent,
		0
	FROM	artierrl
	WHERE	rel_cust = @cust_code
	
	IF (@@rowcount > 0 )
	BEGIN
		UPDATE	#relcode_custs
		SET	across_na = across_na_flag
		FROM	arco
		WHERE	relation_code = payer_soldto_rel_code
		
		

		INSERT	#tiered_custs
		SELECT	parent,
			child_1,
			child_2,
			child_3,
			child_4,
			child_5,
			child_6,
			child_7,
			child_8,
			child_9
		FROM	artierrl
		WHERE	rel_cust = @cust_code
		
		INSERT	#payer_custs
		SELECT	rel_cust
		FROM	#relcode_custs a, artierrl b
		WHERE	a.across_na = 1
		AND	a.relation_code = b.relation_code
		AND	a.parent = b.parent
		
		INSERT	#payer_custs
		SELECT	rel_cust
		FROM	#relcode_custs a, artierrl b, arcust c
		WHERE	a.across_na = 0
		AND	a.relation_code = b.relation_code
		AND	a.parent = b.parent
		AND	b.rel_cust = c.customer_code
		AND	c.across_na_flag = 1
		

		INSERT #payer_custs
		SELECT	DISTINCT parent
		FROM	#tiered_custs
			
		INSERT #payer_custs
		SELECT	DISTINCT child_1
		FROM	#tiered_custs
		
		INSERT #payer_custs
		SELECT	DISTINCT child_2
		FROM	#tiered_custs
		
		INSERT #payer_custs
		SELECT	DISTINCT child_3
		FROM	#tiered_custs
		
		INSERT #payer_custs
		SELECT	DISTINCT child_4
		FROM	#tiered_custs
		
		INSERT #payer_custs
		SELECT	DISTINCT child_5
		FROM	#tiered_custs
		
		INSERT #payer_custs
		SELECT	DISTINCT child_6
		FROM	#tiered_custs
		
		INSERT #payer_custs
		SELECT	DISTINCT child_7
		FROM	#tiered_custs
		
		INSERT #payer_custs
		SELECT	DISTINCT child_8
		FROM	#tiered_custs
		
		INSERT #payer_custs
		SELECT	DISTINCT child_9
		FROM	#tiered_custs
	END
	
	INSERT #payer_custs
	SELECT DISTINCT parent
	FROM	arrelcde, arnarel
	WHERE	child = @cust_code
	AND	arnarel.relation_code = arrelcde.relation_code
	AND	arrelcde.tiered_flag = 0
	
	INSERT	#payer_custs
	VALUES	(@cust_code)
	
	DELETE #payer_custs
	WHERE	( LTRIM(customer_code) IS NULL OR LTRIM(customer_code) = " " )
	

	INSERT #arinvpy 
	SELECT DISTINCT arcust.customer_code, arcust.customer_name
	FROM	arcust, #payer_custs
	WHERE 	arcust.customer_code = #payer_custs.customer_code
	AND	valid_payer_flag = 1
	
DROP TABLE #tiered_custs
DROP TABLE #payer_custs
DROP TABLE #relcode_custs

END


GO
GRANT EXECUTE ON  [dbo].[arinvpay_sp] TO [public]
GO
