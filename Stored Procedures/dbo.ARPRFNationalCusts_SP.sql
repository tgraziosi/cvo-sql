SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[ARPRFNationalCusts_SP] @cust_code varchar( 8 ), @rel_code varchar( 8 )
AS
DECLARE @tier_level	int
BEGIN

	IF ( LTRIM(@rel_code) IS NULL OR LTRIM(@rel_code) = " " )
	BEGIN
		INSERT INTO #prfcust
			( cust_code )
		VALUES ( @cust_code )

		RETURN 0
	END

	SELECT	@tier_level = tier_level
	FROM	artierrl
	WHERE	rel_cust = @cust_code
	AND	relation_code = @rel_code

	IF @tier_level IS NULL
		INSERT INTO #prfcust
			( cust_code )
		VALUES ( @cust_code )

	IF @tier_level = 1
		INSERT	INTO #prfcust
			(cust_code)
		SELECT	rel_cust
		FROM	artierrl
		WHERE	parent = @cust_code
		AND	relation_code = @rel_code

	IF @tier_level = 2
		INSERT	INTO #prfcust
			(cust_code)
		SELECT	rel_cust
		FROM	artierrl
		WHERE	child_1 = @cust_code
		AND	relation_code = @rel_code

	IF @tier_level = 3
		INSERT	INTO #prfcust
			(cust_code)
		SELECT	rel_cust
		FROM	artierrl
		WHERE	child_2 = @cust_code
		AND	relation_code = @rel_code

	IF @tier_level = 4
		INSERT	INTO #prfcust
			(cust_code)
		SELECT	rel_cust
		FROM	artierrl
		WHERE	child_3 = @cust_code
		AND	relation_code = @rel_code

	IF @tier_level = 5
		INSERT	INTO #prfcust
			(cust_code)
		SELECT	rel_cust
		FROM	artierrl
		WHERE	child_4 = @cust_code
		AND	relation_code = @rel_code

	IF @tier_level = 6
		INSERT	INTO #prfcust
			(cust_code)
		SELECT	rel_cust
		FROM	artierrl
		WHERE	child_5 = @cust_code
		AND	relation_code = @rel_code

	IF @tier_level = 7
		INSERT	INTO #prfcust
			(cust_code)
		SELECT	rel_cust
		FROM	artierrl
		WHERE	child_6 = @cust_code
		AND	relation_code = @rel_code

	IF @tier_level = 8
		INSERT	INTO #prfcust
			(cust_code)
		SELECT	rel_cust
		FROM	artierrl
		WHERE	child_7 = @cust_code
		AND	relation_code = @rel_code

	IF @tier_level = 9
		INSERT	INTO #prfcust
			(cust_code)
		SELECT	rel_cust
		FROM	artierrl
		WHERE	child_8 = @cust_code
		AND	relation_code = @rel_code

	IF @tier_level = 10
		INSERT	INTO #prfcust
			(cust_code)
		SELECT	rel_cust
		FROM	artierrl
		WHERE	child_9 = @cust_code
		AND	relation_code = @rel_code

	RETURN 0

END
GO
GRANT EXECUTE ON  [dbo].[ARPRFNationalCusts_SP] TO [public]
GO
