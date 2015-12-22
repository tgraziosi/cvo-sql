SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO



CREATE PROCEDURE [dbo].[cc_gl_account_sp]
	@workload_code varchar(8) = '',
	@account_code varchar(32),
	@direction tinyint = 0

AS
	SET rowcount 50
		BEGIN
			IF @direction = 0
				SELECT account_code 'Account Code', account_description 'Description'
				FROM glchart_vw
				WHERE account_code >= @account_code
				ORDER BY account_code
			IF @direction = 1
				SELECT account_code 'Account Code', account_description 'Description'
				FROM glchart_vw
				WHERE account_code < @account_code
				ORDER BY account_code DESC
			IF @direction = 2
				SELECT account_code 'Account Code', account_description 'Description'
				FROM glchart_vw
				WHERE account_code > @account_code
				ORDER BY account_code
		END

	SET rowcount 0

GO
GRANT EXECUTE ON  [dbo].[cc_gl_account_sp] TO [public]
GO
