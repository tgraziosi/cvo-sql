SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[tdc_3pl_get_next_quote_id_sp]
	@userid		varchar(50),
	@next_quote_id	int	OUTPUT
AS
	IF NOT EXISTS(SELECT * FROM tdc_next_3pl_quote_tbl)
	BEGIN
		INSERT INTO tdc_next_3pl_quote_tbl (next_quote_id, last_user, last_date_updated)
			VALUES(2, @userid, getdate())
		SELECT @next_quote_id = 1
	END
	ELSE
	BEGIN
		--RETURN THE NEXT AVAILABLE QUOTE ID
		SELECT @next_quote_id = next_quote_id FROM tdc_next_3pl_quote_tbl

		UPDATE tdc_next_3pl_quote_tbl 
			SET next_quote_id = next_quote_id+1,
			    last_user = @userid,
			    last_date_updated = getdate()
	END
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[tdc_3pl_get_next_quote_id_sp] TO [public]
GO
