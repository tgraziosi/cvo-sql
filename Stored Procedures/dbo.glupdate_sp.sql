SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROC [dbo].[glupdate_sp] @company_code	varchar(8),
			@currency_code	varchar(8)
AS

DECLARE @null_var	varchar(8),
	@old_company	varchar(8),
	@old_currency	varchar(8),
	@str_msg	varchar(255)



IF NOT EXISTS(	SELECT	*
		FROM	CVO_Control..mccurr
		WHERE	currency_code = @currency_code )
BEGIN

	EXEC appgetstring_sp "STR_CURRENCY_DESC", @str_msg OUT

	INSERT		CVO_Control..mccurr (
			timestamp,
			currency_code,
			description,
			symbol,
			currency_mask,
			user_defined_mask,
			rounding_factor,
			curr_precision )

	VALUES	(	null,
			@currency_code,
			@str_msg,
			"$",
			"###,###,###,##0.00;-$###,###,###,##0.00",
			" ",
			.01,
			2 )

	IF ( @@error != 0 )
	BEGIN
		SELECT "Error:  cannot insert currency code "+@currency_code+ " into mccurr table"
		RETURN 1
	END
END

ELSE
BEGIN
	SELECT	"Warning:  currency code "+@currency_code+" already exists."
END




SELECT	@old_company = company_code,
	@old_currency = home_currency
FROM	glco







IF ( @old_currency = @currency_code )
	SELECT	@old_currency = " "

IF ( @old_company = @company_code )
	SELECT	@old_company = " "




IF ( 1 != (	SELECT	COUNT(e.company_id)
		FROM	CVO_Control..ewcomp e, glco g
		WHERE	e.company_id = g.company_id ))
BEGIN
	SELECT	"Error: There is no matching record in CVO_Control..ewcomp"
	SELECT	"       for this company: ID =", company_id
	FROM	glco
	RETURN	1
END






IF EXISTS(	SELECT	company_code
		FROM	CVO_Control..ewcomp
		WHERE	company_code = @company_code
		AND	company_id != (	SELECT	company_id
					FROM	glco ) )
BEGIN
	SELECT	"Error: Attempt to rename company to the same name as an"
	SELECT	"       existing company"
	RETURN	1
END





UPDATE	CVO_Control..ewcomp
SET	company_code = @company_code
FROM	CVO_Control..ewcomp e, glco g
WHERE	g.company_id = e.company_id


SELECT	@null_var = NULL

SET ROWCOUNT 4096



 
SELECT	"Updating GLBAL table..."
WHILE ( 1 = 1 )
BEGIN

	UPDATE 	glbal
	SET	currency_code = @currency_code
	WHERE	currency_code IN ( @null_var, " ", @old_currency )

      	IF ( @@ROWCOUNT < 4096 )
      	BREAK
END


 
SELECT	"Updating GLTRX table..."
WHILE ( 1 = 1 )
BEGIN
      
	UPDATE 	gltrx
	SET	company_code = @company_code,
		source_company_code = @company_code,
		home_cur_code = @currency_code
	WHERE	company_code IN ( @null_var, " ", @old_company )
	OR	home_cur_code IN ( @null_var, " ", @old_currency )

      	IF ( @@ROWCOUNT < 4096 )
      	BREAK
END



 
SELECT	"Updating GLTRXDET table..."
WHILE ( 1 = 1 )
BEGIN
      
	UPDATE 	gltrxdet
	SET	rec_company_code = @company_code,
		nat_cur_code = @currency_code
	WHERE	rec_company_code IN ( @null_var, " ", @old_company )
	OR	nat_cur_code IN ( @null_var, " ", @old_currency )

      	IF ( @@ROWCOUNT < 4096 )
      	BREAK
END



 
SELECT	"Updating GLRECDET table..."
WHILE ( 1 = 1 )
BEGIN
      
	UPDATE 	glrecdet
	SET	rec_company_code = @company_code,
		nat_cur_code = @currency_code
	WHERE	rec_company_code IN ( @null_var, " ", @old_company )
	OR	nat_cur_code IN ( @null_var, " ", @old_currency )

      	IF ( @@ROWCOUNT < 4096 )
      	BREAK
END



 
SELECT	"Updating GLREADET table..."
WHILE ( 1 = 1 )
BEGIN
      
	UPDATE 	glreadet
	SET	rec_company_code = @company_code
	WHERE	rec_company_code IN ( @null_var, " ", @old_company )

      	IF ( @@ROWCOUNT < 4096 )
      	BREAK
END



 
SELECT	"Updating BATCHCTL table..."
WHILE ( 1 = 1 )
BEGIN
      
	UPDATE 	batchctl
	SET	company_code = @company_code
	WHERE	company_code IN ( @null_var, " ", @old_company )

      	IF ( @@ROWCOUNT < 4096 )
      	BREAK
END



 
SELECT	"Updating GLRECUR table..."
WHILE ( 1 = 1 )
BEGIN
      
	UPDATE 	glrecur
	SET	nat_cur_code = @currency_code
	WHERE	nat_cur_code IN ( @null_var, " ", @old_currency )

      	IF ( @@ROWCOUNT < 4096 )
      	BREAK
END



EXEC	apupdate_sp	@company_code,
			@currency_code,
			@old_company,
			@old_currency




UPDATE	glco
SET	company_code = @company_code,
	home_currency = @currency_code

IF ( @@error != 0 )
BEGIN
	SELECT	"Error: Cannot update GLCO table with given values!"
	RETURN 1
END

SET	ROWCOUNT 0

RETURN 0

GO
GRANT EXECUTE ON  [dbo].[glupdate_sp] TO [public]
GO
