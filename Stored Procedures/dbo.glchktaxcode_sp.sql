SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

CREATE PROCEDURE [dbo].[glchktaxcode_sp] 	@tcode varchar(8)
AS

IF ( SELECT COUNT( 1 ) FROM arinpcdt WHERE tax_code = @tcode ) = 0
BEGIN

	IF ( SELECT COUNT( 1 ) FROM arinpchg WHERE tax_code = @tcode ) = 0
	BEGIN

		IF ( SELECT COUNT( 1 ) FROM apinpcdt WHERE tax_code = @tcode ) = 0
		BEGIN

			IF ( SELECT COUNT( 1 ) FROM apinpchg WHERE tax_code = @tcode ) = 0
				SELECT 0
			ELSE
				SELECT 1

		END
		ELSE
			SELECT 1

	END
	ELSE
		SELECT 1

END
ELSE
	SELECT 1



/**/                                              
GO
GRANT EXECUTE ON  [dbo].[glchktaxcode_sp] TO [public]
GO
