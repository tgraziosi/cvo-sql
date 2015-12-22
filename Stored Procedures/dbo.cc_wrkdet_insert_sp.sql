SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE [dbo].[cc_wrkdet_insert_sp]
	@workload_code varchar(8),
	@workload_clause varchar(255),
	@having	tinyint = 0,
	@type	tinyint = 0,
	@datatype	varchar(20) = ''
AS
IF @having = 0
	INSERT ccwrkdet 
		SELECT @workload_code,@workload_clause, ISNULL((SELECT MAX(sequence_id) + 1 FROM
							ccwrkdet WHERE workload_code = @workload_code), 1), @type, @datatype
ELSE
	INSERT ccwrkdet 
		SELECT @workload_code,@workload_clause, 11, @type, @datatype 
GO
GRANT EXECUTE ON  [dbo].[cc_wrkdet_insert_sp] TO [public]
GO
