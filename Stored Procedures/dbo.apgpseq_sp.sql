SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[apgpseq_sp] @debug_level smallint = 0
							WITH RECOMPILE 	
AS
IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/apgpseq.sp" + ", line " + STR( 35, 5 ) + " -- ENTRY: "

UPDATE #seq
SET sequence_id = a.sequence - b.min_sequence
FROM #seq a, #temp b
WHERE a.id = b.id
IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/apgpseq.sp" + ", line " + STR( 41, 5 ) + " -- EXIT: "

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[apgpseq_sp] TO [public]
GO
