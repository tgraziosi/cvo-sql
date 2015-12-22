SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[CVO_ReplPrt_sp] @where_clause varchar(255)
AS

SET NOCOUNT ON

DECLARE @Create_doc varchar(1)

--
-- SELECT OUT OPTIONS
--
SELECT @Create_doc = UPPER(substring(@where_clause,charindex('%',@where_clause)+1,1))

--

CREATE TABLE #tmp_CVO_Replen
([tran_id]			[int] NOT NULL,
 [location]			[varchar](10) NULL,
 [bin_no]			[varchar](12) NULL,
 [next_op]			[varchar](30) NULL,
 [part_no]			[varchar](30) NULL,
 [qty_to_process]	[decimal](20,8) NULL,
 [date_time]		[datetime] NULL,
 [Create_doc]		[varchar] (1) NULL
)
--
-- GATHER DETAIL
--
INSERT INTO #tmp_CVO_Replen
SELECT
	pq.tran_id, 
	pq.location, 
	pq.bin_no as from_bin, 
	pq.next_op as to_bin,
	pq.part_no, 
	pq.qty_to_process,
	pq.date_time,
	' '
FROM
	tdc_pick_queue pq
	INNER JOIN tdc_bin_master bm ON pq.next_op = bm.bin_no AND bm.usage_type_code = 'REPLENISH'
WHERE
	pq.trans = 'MGTB2B' and pq.trans_type_no = 0
ORDER BY
	pq.date_time, pq.bin_no, pq.part_no


IF @Create_doc = 'Y'
	BEGIN
	SET ROWCOUNT 0
	SET NOCOUNT ON
	--select 'Generating Document'
	Execute cvo_print_replenish_list 'PICKAREA'

END

--
-- RETURN RECORDS TO EXPLORER
--
SELECT * FROM #tmp_CVO_Replen

DROP TABLE #tmp_CVO_Replen

--



GO
GRANT EXECUTE ON  [dbo].[CVO_ReplPrt_sp] TO [public]
GO
