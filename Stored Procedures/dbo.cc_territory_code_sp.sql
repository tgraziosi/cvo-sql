SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE [dbo].[cc_territory_code_sp]
	@workload_code varchar(8) = "",
	@territory_code varchar(9),
	@direction tinyint = 0

AS
	SET rowcount 50
	IF @workload_code = ""
		BEGIN
			IF @direction = 0
				SELECT territory_code "Terr. Code", territory_desc "Description"
				FROM arterr
				WHERE territory_code >= @territory_code
				ORDER BY territory_code
			IF @direction = 1
				SELECT territory_code "Terr. Code", territory_desc "Description"
				FROM arterr
				WHERE territory_code < @territory_code
				ORDER BY territory_code DESC
			IF @direction = 2
				SELECT territory_code "Terr. Code", territory_desc "Description"
				FROM arterr
				WHERE territory_code > @territory_code
				ORDER BY territory_code
		END

	ELSE
		BEGIN
			IF @direction = 0
				SELECT DISTINCT t.territory_code "Terr. Code", territory_desc "Description "
				FROM arterr t, arcust a, ccwrkmem m
				WHERE t.territory_code >= @territory_code
				AND a.customer_code = m.customer_code
				AND a.territory_code = t.territory_code
				AND workload_code = @workload_code
				ORDER BY t.territory_code
			IF @direction = 1
				SELECT DISTINCT t.territory_code "Terr. Code",territory_desc "Description "
				FROM arterr t, arcust a, ccwrkmem m
				WHERE t.territory_code <= @territory_code
				AND a.customer_code = m.customer_code
				AND a.territory_code = t.territory_code
				AND workload_code = @workload_code
				ORDER BY t.territory_code DESC
			IF @direction = 2
				SELECT DISTINCT t.territory_code "Terr. Code",territory_desc "Description "
				FROM arterr t, arcust a, ccwrkmem m
				WHERE t.territory_code >= @territory_code
				AND a.customer_code = m.customer_code
				AND a.territory_code = t.territory_code
				AND workload_code = @workload_code
				ORDER BY t.territory_code ASC
		END

	SET rowcount 0

GO
GRANT EXECUTE ON  [dbo].[cc_territory_code_sp] TO [public]
GO
