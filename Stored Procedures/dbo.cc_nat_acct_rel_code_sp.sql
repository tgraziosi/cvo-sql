SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO



CREATE PROCEDURE [dbo].[cc_nat_acct_rel_code_sp]
	@relation_code		varchar(8) = '',
	@direction tinyint = 0

AS
	SET rowcount 50

	IF @direction = 0
		SELECT	DISTINCT relation_code 'Relation Code', [description] 'Description'
		FROM		arrelcde 
		WHERE		relation_code >= @relation_code
		AND			tiered_flag = 1
		ORDER BY relation_code ASC
	IF @direction = 1
		SELECT	DISTINCT relation_code 'Relation Code', [description] 'Description'
		FROM		arrelcde 
		WHERE		relation_code <= @relation_code
		AND			tiered_flag = 1
		ORDER BY relation_code DESC
	IF @direction = 2
		SELECT	DISTINCT relation_code 'Relation Code', [description] 'Description'
		FROM		arrelcde 
		WHERE		relation_code >= @relation_code
		AND			tiered_flag = 1
		ORDER BY relation_code ASC


SET rowcount 0


	
GO
GRANT EXECUTE ON  [dbo].[cc_nat_acct_rel_code_sp] TO [public]
GO
